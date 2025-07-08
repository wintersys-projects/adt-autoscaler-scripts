#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/06/2021
# Description : This will tighten the DBaaS firewall so that the DBaaS system is only
# accessible to IP addresses that we control (our fleet of webservers basically)
#######################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# The Agile Deployment Toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with The Agile Deployment Toolkit.  If not, see <http://www.gnu.org/licenses/>.
########################################################################################
########################################################################################
#set -x

BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"
CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
MULTI_REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'MULTIREGION'`"
PRIMARY_REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'PRIMARYREGION'`"
WEBSITE_URL="`${HOME}/utilities/config/ExtractConfigValue.sh 'WEBSITEURL'`"

#The digital ocean managed database should be in the same VPC as the webserver machines which means that the managed database can only be accessed from within that VPC
#This means that you have no need to have trusted IP addresses on an IP address by IP address basis for digital ocean. I have left the code below commented out in case
#You do want to have specific IP addresses as trusted IPs but as long as your managed database is in the same VPC as your main machines then you shouldn't need this

multi_region_ips=""

if ( [ "${MULTI_REGION}" = "1" ] )
then
        multi_region_bucket="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`-multi-region"
        multi_region_ips="`${HOME}/providerscripts/datastore/ListFromDatastore.sh ${multi_region_bucket}/dbaas_ips/*`"
fi

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
    dbaas="`${HOME}/utilities/config/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
    cluster_id="`/bin/echo ${dbaas} | /usr/bin/awk '{print $NF}'`"
   # ip_addr="`/usr/local/bin/doctl vpcs list -o json | /usr/bin/jq -r '.[] | select (.name == "adt-vpc" ) | select (.region == "'${REGION}'").ip_range'`"
 
    if ( [ "${cluster_id}" != "" ] )
    then
        if ( [ "${multi_region_ips}" != "" ] )
        then
         for ip in ${multi_region_ips}
         do
          /usr/local/bin/doctl databases firewalls append ${cluster_id} --rule ip_addr:${ip}
         done
       fi
    fi
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
    dbaas="`${HOME}/utilities/config/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
    build_identifier="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
    zone="`/bin/echo ${dbaas} | /usr/bin/awk '{print $4}'`"
    database_name="`/bin/echo ${dbaas} | /usr/bin/awk '{print $6}'`"

    webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "ws-${zone}-${build_identifier}" ${CLOUDHOST}`"
    database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "db-${zone}-${build_identifier}" ${CLOUDHOST}`"
    newips="${webserver_ips} ${database_ips} "
    newips="`/bin/echo ${newips} | /bin/sed 's/  / /g' | /bin/tr ' ' ',' | /bin/sed 's/,$//g'`"

    if ( [ "${multi_region_ips}" != "" ] )
    then
       for ip in ${multi_region_ips}
       do
            ipaddresses="${ipaddresses} ${ip}"
       done
    fi

    ipaddresses="`/bin/echo ${ipaddresses} | /usr/bin/tr ' ' '\n' | /usr/bin/sort -u`"

    if ( [ "`/bin/echo ${dbaas} | /bin/grep ' pg '`" != "" ] )
    then
        /usr/bin/exo dbaas update -z ${zone}  ${database_name} --pg-ip-filter=${ipaddresses}
    elif ( [ "`/bin/echo ${dbaas} | /bin/grep ' mysql '`" != "" ] )
    then
        /usr/bin/exo dbaas update -z ${zone}  ${database_name} --mysql-ip-filter=${ipaddresses}
    fi
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
    dbaas="`${HOME}/utilities/config/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
    label="`${HOME}/utilities/config/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped" | /usr/bin/awk '{print $7}'`"
    database_id="`/usr/local/bin/linode-cli --json databases mysql-list | /usr/bin/jq '.[] | select(.label | contains ("'${label}'")) | .id'`"
   
    if ( [ "${database_id}" = "" ] )
    then
        database_id="`/usr/local/bin/linode-cli --json databases postgresql-list | /usr/bin/jq '.[] | select(.label | contains ("'${label}'")) | .id'`"
    fi

    webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
    database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
        
    ipaddresses="${webserver_ips} ${database_ips}"

    if ( [ "${multi_region_ips}" != "" ] )
    then
       for ip in ${multi_region_ips}
       do
            ipaddresses="${ipaddresses} ${ip}"
       done
    fi

    ipaddresses="`/bin/echo ${ipaddresses} | /usr/bin/tr ' ' '\n' | /usr/bin/sort -u`"

    allow_list=" "
    for ipaddress in ${ipaddresses}
    do
        allow_list="${allow_list} --allow_list ${ipaddress}/32"
    done

    if ( [ "`/bin/echo ${dbaas} | /bin/grep 'mysql'`" != "" ] )
    then
        /usr/local/bin/linode-cli databases mysql-update ${database_id} ${allow_list}
    fi

    if ( [ "`/bin/echo ${dbaas} | /bin/grep 'postgresql'`" != "" ] )
    then        
        /usr/local/bin/linode-cli databases postgresql-update ${database_id} ${allow_list}
    fi
fi

#The vultr managed database should be in the same VPC as the webserver machines which means that the managed database can only be accessed from within that VPC
#This means that you have no need to have trusted IP addresses on an IP address by IP address basis for vultr. I have left the code below commented out in case
#You do want to have specific IP addresses as trusted IPs but as long as your managed database is in the same VPC as your main machines then you shouldn't need this

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
   export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
   databaseids="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.label == "'${label}'").id'`"
   selected_databaseid=""

   DB_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'DB_IDENTIFIER'`"

  for databaseid in ${databaseids}
  do
      if ( [ "`/usr/bin/vultr database get ${databaseid} -o json | /usr/bin/jq -r '.database | select (.dbname == "'${DB_IDENTIFIER}'").id'`" != "" ] )
      then
          selected_databaseid="${databaseid}"
      fi
  done
    ipaddresses=""
    if ( [ "${multi_region_ips}" != "" ] )
    then
       ipaddresses="["
       for ip in ${multi_region_ips}
       do
            ipaddresses="${ipaddresses}${ip},"
       done
       ipaddresses="`/bin/echo ${ipaddresses} | /bin/sed 's/,$//'`]"
    fi

    ipaddresses="`/bin/echo ${ipaddresses} | /usr/bin/tr ' ' '\n' | /usr/bin/sort -u`"

  if ( [ "${selected_databaseid}" != "" ] )
  then
      VPC_IP_RANGE="`${HOME}/utilities/config/ExtractConfigValue.sh 'VPCIPRANGE'`"
      /usr/bin/vultr database update ${selected_databaseid} --trusted-ips="${ipaddresses}"
  fi
fi
