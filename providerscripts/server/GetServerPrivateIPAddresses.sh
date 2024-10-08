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
	ip="`/usr/local/bin/doctl compute droplet list | /bin/grep ${server_type} | /usr/bin/awk '{print $4}'`"
	echo ${ip}
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	machine_name="`/bin/echo ${server_type} | /bin/sed 's/\*//g'`"
	zone="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
	/usr/bin/exo  compute private-network show adt_private_net_${zone} --zone ${zone} -O text | /usr/bin/tr '{' '\n' | /bin/grep ${server_type} | /usr/bin/sed 's/}.*//g' | /usr/bin/awk '{print $2}'
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
  # /usr/local/bin/linode-cli linodes list --text | /bin/grep ${server_type} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | /bin/grep "192.168"
	linodeids="`/usr/local/bin/linode-cli --text linodes list | /bin/grep ".*${server_type}" | /usr/bin/awk '{print $1}'`"
	privateips=""
	for linodeid in ${linodeids}
	do
		#privateip="`/usr/local/bin/linode-cli --text linodes ips-list ${linodeid} | /bin/grep -A 3 'ipv4.private' | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`"
		#privateip="`/usr/local/bin/linode-cli  --text linodes list | /bin/grep ${linodeid} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | /bin/grep "192.168"`"
		privateip="`/usr/local/bin/linode-cli --text linodes ips-list ${linodeid} | /bin/grep -Po "10.0.1.*" | /usr/bin/awk '{print $1}'`"		
  		privateips=${privateips}" ${privateip}"
	done
	/bin/echo ${privateips}
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	/bin/sleep 1
	server_type="`/bin/echo ${server_type} | /usr/bin/cut -c -25`"
	ids="`/usr/bin/vultr instance list | /bin/grep ${server_type} | /usr/bin/awk '{print $1}'`"
	
	for id in ${ids}
	do
		/usr/bin/vultr instance get ${id} | /bin/grep "INTERNAL IP" | /usr/bin/awk '{print $3}'
	done
fi


