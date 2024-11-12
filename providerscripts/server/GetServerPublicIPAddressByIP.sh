#!/bin/sh
############################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script gets a machine's public ip based on its private ip
#############################################################################
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
####################################################################################
####################################################################################
#set -x

export HOME="`/bin/cat /home/homedir.dat`"

ip="${1}"
cloudhost="${2}"

if ( [ "`/bin/echo ${ip} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`" = "" ] )
then
	exit
fi

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
	/usr/local/bin/doctl compute droplet list | /bin/grep ${ip} | /usr/bin/awk '{print $3}'
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	zone="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
	server_name="`/usr/bin/exo compute private-network show adt_private_net_${zone} --zone ${zone} -O json | /usr/bin/jq '.leases[] | select(.ip_address=="'${ip}'") | .instance' | /bin/sed 's/"//g'`"
	/usr/bin/exo compute instance list --zone ${zone} -O json | /usr/bin/jq '.[] | select (.name =="'${server_name}'").ip_address' | /bin/sed 's/"//g'
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
	linodeids="`/usr/local/bin/linode-cli --json --pretty linodes list | jq '.[].id'`"
        
	for linodeid in ${linodeids}
        do
                /usr/local/bin/linode-cli --json --pretty linodes ips-list ${linodeid} | /usr/bin/jq '.[].ipv4.vpc[] | select (.address == "'${ip}'").nat_1_1' | /bin/sed 's/"//g'
        done
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	/bin/sleep 1
         vpc_id="`/usr/bin/vultr vpc2 list -o json | /usr/bin/jq '.vpcs[] | select (.description == "adt-vpc").id' | /bin/sed 's/"//g'`"
        id="`/usr/bin/vultr vpc2 nodes list ${vpc_id} -o json | /usr/bin/jq '.nodes[] | select (.ip_address == "'${ip}'").id' | /bin/sed 's/"//g'`"
        /usr/bin/vultr instance get ${id} -o json | /usr/bin/jq '.instance.main_ip' | /bin/sed 's/"//g'
fi

