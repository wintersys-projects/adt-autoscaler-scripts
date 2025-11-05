#!/bin/sh
####################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script gets a list of server ip addresses based on a name/type
####################################################################################
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
#######################################################################################
#######################################################################################
#set -x

export HOME="`/bin/cat /home/homedir.dat`"

server_type="${1}"
cloudhost="${2}"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
	/usr/local/bin/doctl compute droplet list -o json | /usr/bin/jq -r '.[] | select (.name | contains ("'${server_type}'")).networks.v4[] | select (.type == "private").ip_address' 2>/dev/null 
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	zone="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"
	/usr/bin/exo compute private-network show adt_private_net_${zone} --zone ${zone} -O json | /usr/bin/jq -r '.leases[] | select(.instance | contains ("'${server_type}'")) | .ip_address' 2>/dev/null
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
	linodeids="`/usr/local/bin/linode-cli linodes list --no-defaults --json | /usr/bin/jq '.[] | select (.label | contains("'${server_type}'")).id'`"
	privateips=""
	for linodeid in ${linodeids}
	do
		privateip="`/usr/local/bin/linode-cli linodes ips-list ${linodeid} --no-defaults --json | /usr/bin/jq -r '.[].ipv4.vpc[].address' 2>/dev/null`"		
		privateips=${privateips}" ${privateip}"
	done
	/bin/echo ${privateips}
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	server_type="`/bin/echo ${server_type} | /usr/bin/cut -c -32`"

	ids="`/usr/bin/vultr instance list -o json | /usr/bin/jq -r '.instances[] | select (.label | contains("'${server_type}'")).id'`"
	for id in ${ids} 
	do
		/usr/bin/vultr instance ipv4 list ${id} -o json | /usr/bin/jq -r '.ipv4s[] | select (.type == "private").ip' 2>/dev/null
	done

      #  ids="`/usr/bin/vultr instance list -o json | /usr/bin/jq -r '.instances[] | select (.label | contains("'${server_type}'")).id'`"
      #  vpc_id="`/usr/bin/vultr vpc2 list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "adt-vpc").id'`"
      #  /usr/bin/vultr vpc2 nodes list ${vpc_id} -o json | /usr/bin/jq -r '.nodes[] | select (.description | contains ( "'${server_type}'")).ip_address'
fi


