#!/bin/sh
#####################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will get a list of server ips based on a name/type
######################################################################################
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
#########################################################################################
#########################################################################################
#set -x
server_type="$1"
cloudhost="$2"

export HOME="`/bin/cat /home/homedir.dat`"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
	/usr/local/bin/doctl compute droplet list -o json | /usr/bin/jq -r '.[] | select ( .name | contains ("'${server_type}'")).networks.v4[] | select (.type == "public").ip_address' 2>/dev/null  
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then    
	zone="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"
	/usr/bin/exo  compute instance list --zone ${zone} -O json | /usr/bin/jq -r '.[] | select (.name | contains("'${server_type}'")).ip_address' 2>/dev/null
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
	/usr/local/bin/linode-cli --json linodes list | /usr/bin/jq -r '.[] | select (.label | contains("'${server_type}'")).ipv4[]' 2>/dev/null
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	server_type="`/bin/echo ${server_type} | /usr/bin/cut -c -25`"
	/usr/bin/vultr instance list -o json | /usr/bin/jq -r '.instances[] | select (.label | contains("'${server_type}'")).main_ip' 2>/dev/null
fi



