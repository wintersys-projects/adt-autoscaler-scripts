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

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
	/usr/local/bin/doctl compute droplet list -o json | /usr/bin/jq -r '.[] | select (.networks.v4[] | select (.ip_address == "'${ip}'")).networks.v4[] | select (.type == "public").ip_address'
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	zone="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"
	server_name="`/usr/bin/exo compute private-network show adt_private_net_${zone} --zone ${zone} -O json | /usr/bin/jq -r '.leases[] | select(.ip_address=="'${ip}'") | .instance'`"
	/usr/bin/exo compute instance list --zone ${zone} -O json | /usr/bin/jq -r '.[] | select (.name =="'${server_name}'").ip_address' 
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
	linode_ids="`/usr/local/bin/linode-cli --json linodes list | /usr/bin/jq '.[].id'`"
	matched_linode_id=""
	for linode_id in ${linode_ids}
	do
		if ( [ "`/usr/local/bin/linode-cli --json  linodes ips-list ${linode_id} | /usr/bin/jq -r '.[].ipv4.vpc[].address'`" = "${ip}" ] )
		then
			matched_linode_id="${linode_id}"
		fi
	done

	if ( [ "${matched_linode_id}" != "" ] )
	then
		/usr/local/bin/linode-cli linodes ips-list ${matched_linode_id} --no-defaults --json | /usr/bin/jq -r '.[].ipv4.public[].address'
	fi
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	#vpc_id="`/usr/bin/vultr vpc2 list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "adt-vpc").id'`"
	#id="`/usr/bin/vultr vpc2 nodes list ${vpc_id} -o json | /usr/bin/jq -r '.nodes[] | select (.ip_address == "'${ip}'").id'`"
	#/usr/bin/vultr instance get ${id} -o json | /usr/bin/jq -r '.instance.main_ip'
	ids="`/usr/bin/vultr instance list -o json | /usr/bin/jq -r '.instances[] | .id'`"
	for id in ${ids}
	do
		if ( [ "`/usr/bin/vultr instance ipv4 list ${id} -o json | /usr/bin/jq -r '.ipv4s[] | select (.ip == "'${ip}'")'`" != "" ] )
		then
			machine_id="${id}"
		fi
	done
	if ( [ "${machine_id}" != "" ] )
	then
		/usr/bin/vultr instance list -o json | /usr/bin/jq -r '.instances[] | select (.id == "'${machine_id}'").main_ip'
	fi
fi

