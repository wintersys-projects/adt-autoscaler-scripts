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

BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
REGION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
        dbaas="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
        cluster_id="`/bin/echo ${dbaas} | /usr/bin/awk '{print $NF}'`"
        ip_addr="`/usr/local/bin/doctl vpcs list -o json | /usr/bin/jq -r '.[] | select (.name == "adt-vpc" ) | select (.region == "'${REGION}'").ip_range'`"

        if ( [ "${cluster_id}" != "" ] )
        then
                /usr/local/bin/doctl databases firewalls append ${cluster_id} --rule ip_addr:${ip_addr}
        fi
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
        dbaas="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
        zone="`/bin/echo ${dbaas} | /usr/bin/awk '{print $4}'`"
        database_name="`/bin/echo ${dbaas} | /usr/bin/awk '{print $6}'`"

        autoscaler_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
        webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
        database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

        autoscaler_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
        webserver_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
        database_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

        newips="${autoscaler_ips} ${webserver_ips} ${database_ips} ${autoscaler_private_ips} ${webserver_private_ips} ${database_private_ips}"
        newips="`/bin/echo ${newips} | /bin/sed 's/  / /g' | /bin/tr ' ' ',' | /bin/sed 's/,$//g'`"

        if ( [ "`/bin/echo ${dbaas} | /bin/grep ' pg '`" != "" ] )
        then
                /usr/bin/exo dbaas update -z ${zone}  ${database_name} --pg-ip-filter=${newips}
        elif ( [ "`/bin/echo ${dbaas} | /bin/grep ' mysql '`" != "" ] )
        then
                /usr/bin/exo dbaas update -z ${zone}  ${database_name} --mysql-ip-filter=${newips}
        fi
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        dbaas="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
        label="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped" | /usr/bin/awk '{print $7}'`"
        database_id="`/usr/local/bin/linode-cli --json databases mysql-list | /usr/bin/jq ".[] | select(.label | contains ("'${label}'")) | .id"`"
   
        if ( [ "${database_id}" = "" ] )
        then
                database_id="`/usr/local/bin/linode-cli --json databases postgresql-list | /usr/bin/jq ".[] | select(.label | contains ("'${label}'")) | .id"`"
        fi

        webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
        database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
        
        ipaddresses="${webserver_ips} ${database_ips}"

        allow_list=" "
        for ipaddress in ${ipaddresses}
        do
                allow_list="${allow_list} --allow_list ${ipaddress}/32"
        done

        if ( [ "`/bin/echo ${dbaas} | /bin/grep 'mysql'`" != "" ] )
        then
                for ipaddress in ${newips}
                do
                        /usr/local/bin/linode-cli databases mysql-update ${database_id} ${allow_list}
                done
        fi

        if ( [ "`/bin/echo ${dbaas} | /bin/grep 'postgresql'`" != "" ] )
        then        
                for ipaddress in ${newips}
                do
                        /usr/local/bin/linode-cli databases postgresql-update ${database_id} ${allow_list}
                done
        fi
fi

#The vultr managed database should be in the same VPC as the webserver machines which means that the managed database can only be accessed from within that VPC
#This means that you have no need to have trusted IP addresses on an IP address by IP address basis for vultr. I have left the code below commented out in case
#You do want to have specific IP addresses as trusted IPs but as long as your managed database is in the same VPC as your main machines then you shouldn't need this

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"

  #  autoscaler_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
  #  webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
  #  database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

  #  autoscaler_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "as-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
  #  webserver_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "ws-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"
  #  database_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "db-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

  #  ipaddresses="${autoscaler_ips} ${webserver_ips} ${database_ips} ${autoscaler_private_ips} ${webserver_private_ips} ${database_private_ips}"
 #   ipaddresses="`/bin/echo ${ipaddresses} | /bin/sed 's/  / /g;' | /bin/sed 's/ /,/g'`"
#
    databaseids="`/usr/bin/vultr database list -o json | /usr/bin/jq -r '.databases[] | select (.label == "'${label}'").id'`"
    selected_databaseid=""

    DBaaS_HOSTNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBaaS_HOSTNAME'`"

    for databaseid in ${databaseids}
    do
        if ( [ "`/usr/bin/vultr database get ${databaseid} -o json | /usr/bin/jq -r '.database | select (.dbname == "'${DBaaS_HOSTNAME}'").id'`" != "" ] )
        then
             selected_databaseid="${databaseid}"
        fi
    done

    if ( [ "${selected_databaseid}" != "" ] )
    then
        VPC_IP_RANGE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'VPCIPRANGE'`"
        /usr/bin/vultr database update ${selected_databaseid} --trusted-ips="${VPC_IP_RANGE}"
    fi
fi
