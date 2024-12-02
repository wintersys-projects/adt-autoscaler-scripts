#!/bin/sh
######################################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script spins up a machine of the specified size, name and so on on our chosen provider
# There are two distinct ways that a machine can be built.
# 1) A regular build
# 2) From pre-existing snapshots.
# It depends on whether the provider supports snapshots as to whether we can use option 2 or not
#######################################################################################################
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
#######################################################################################################
#######################################################################################################
set -x

export HOME="`/bin/cat /home/homedir.dat`"

server_size="${1}"
server_name="`/bin/echo ${2} | /usr/bin/cut -c -32`"

cloudhost="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
build_identifier="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"

snapshotid="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSERVERIMAGEID'`"
buildos="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
buildos_version="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOSVERSION'`"
region="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
ddos_protection="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ENABLEDDOSPROTECTION'`"
vpc_ip_range="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'VPCIPRANGE'`"
key_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'KEYID'`"
build_identifier="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
active_firewall="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ACTIVEFIREWALLS'`"

os_choice="`${HOME}/providerscripts/cloudhost/GetOperatingSystemVersion.sh`"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then

	vpc_id="`/usr/local/bin/doctl vpcs list  | /bin/grep -w "adt-vpc" | /bin/grep -w "${region}" | /usr/bin/awk '{print $1}'`"

	#Digital ocean supports snapshots so, we test to see if we want to use them
	if ( [ "S{snapshotid}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
	then
		#If we get to here, then we are building from a snapshot and we pass the snapshotid in as the oschoice parameter
		os_choice="${snapshotid}"	
  fi
		/usr/local/bin/doctl compute droplet create "${server_name}" --size "${server_size}" --image "${os_choice}"  --region "${region}" --ssh-keys "${key_id}" --vpc-uuid "${vpc_id}"
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	if ( [ "${snapshot_id}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
	then
		os_choice="${snapshot_id}"
	fi
	
	/usr/bin/exo compute instance create "${server_name}" --instance-type standard.${server_size}  --security-group adt-webserver-${build_identifier} --template "${os_choice}" --zone ${region} --ssh-key ${key_id} --cloud-init "${HOME}/providerscripts/server/cloud-init/exoscale.dat"

	if ( [ "`/usr/bin/exo compute private-network list -O text | /bin/grep -w "adt_private_net_${region}"`" = "" ] )
	then
		/usr/bin/exo compute private-network create adt_private_net_${region} --zone ${region} --start-ip 10.0.0.20 --end-ip 10.0.0.200 --netmask 255.255.255.0
	fi
	
	/usr/bin/exo compute instance private-network attach  ${server_name} adt_private_net_${region} --zone ${region}
fi


if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then	
	if ( [ -f ${HOME}/.ssh/EMERGENCY_PASSWORD ] )
	then
		emergency_password="`/bin/cat ${HOME}/.ssh/EMERGENCY_PASSWORD`"
	fi

 	key="`/usr/local/bin/linode-cli --json sshkeys view ${key_id} | /usr/bin/jq -r '.[].ssh_key'`"
 	vpc_id="`/usr/local/bin/linode-cli --json vpcs list | /usr/bin/jq -r '.[] | select (.label == "adt-vpc").id'`"
	subnet_id="`/usr/local/bin/linode-cli --json vpcs subnets-list ${vpc_id} | /usr/bin/jq -r '.[] | select (.label == "adt-subnet").id'`"
 
	if ( [ "${snapshot_id}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
	then
 		os_choice="private/${snapshot_id}"
   	fi

	if ( [ "${active_firewall}" = "2" ] || [ "${active_firewall}" = "3" ] )
 	then
        	firewall_id="`/usr/local/bin/linode-cli --json firewalls list | /usr/bin/jq -r '.[] | select (.label | contains ("adt-webserver")) |  select (.label | endswith ("'-${build_identifier}'")).id'`"
 		/usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass ${emergency_password} --region ${region} --image "${os_choice}" --firewall_id="${firewall_id}" --type ${server_size} --label "${server_name}" --no-defaults --interfaces.primary true --interfaces.purpose vpc --interfaces.subnet_id ${subnet_id} --interfaces.ipv4.nat_1_1 any
	else
 		/usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass ${emergency_password} --region ${region} --image "${os_choice}" --type ${server_size} --label "${server_name}" --no-defaults --interfaces.primary true --interfaces.purpose vpc --interfaces.subnet_id ${subnet_id} --interfaces.ipv4.nat_1_1 any
 	fi
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	os_choice="`/usr/bin/vultr os list -o json | /usr/bin/jq -r '.os[] | select (.name | contains ("'"${os_choice}"'")).id'`"		

	if ( [ "`/usr/bin/vultr vpc2 list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "adt-vpc").id'`" = "" ] )
	then
		/usr/bin/vultr vpc2 create --region="${region}" --description="adt-vpc" --ip-type="v4" --ip-block="192.168.0.0" --prefix-length="16"
	fi
	
        vpc_id="`/usr/bin/vultr vpc2 list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "adt-vpc").id'`"


	#Vultr supports snapshots, so decide if we are building from a snapshot
	if ( [ "${snapshot_id}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
	then
		os_choice="${snapshot_id}"
  	fi

	user_data=`/bin/cat ${HOME}/providerscripts/server/cloud-init/vultr.dat`

 	firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description | contains ("adt-webserver")) |  select (.description | endswith ("'-${BUILD_IDENTIFIER}'")).id'`"

	ddos="false"
 	if ( [ "${ddos_protection}" = "1" ] )
  	then
   		ddos="true"
     	fi
	if ( [ "${snapshot_id}" = "" ] )
 	then
  		if ( [ "${active_firewall}" = "2" ] || [ "${active_firewall}" = "3" ] )
 		then
			/usr/bin/vultr instance create --label="${server_name}" --region="${region}" --plan="${server_size}" --ipv6=false -s ${key_id} --os="${os_choice}" --ddos="${ddos}" --userdata="${user_data}" --firewall-group="${firewall_id}"
		else
  			/usr/bin/vultr instance create --label="${server_name}" --region="${region}" --plan="${server_size}" --ipv6=false -s ${key_id} --os="${os_choice}" --ddos="${ddos}" --userdata="${user_data}" 
  		fi
 	else
  		if ( [ "${active_firewall}" = "2" ] || [ "${active_firewall}" = "3" ] )
 		then
  			/usr/bin/vultr instance create --label="${server_name}" --region="${region}" --plan="${server_size}" --ipv6=false -s ${key_id} --snapshot="${os_choice}" --ddos="${ddos}" --userdata="${user_data}" --firewall-group="${firewall_id}"
		else
   			/usr/bin/vultr instance create --label="${server_name}" --region="${region}" --plan="${server_size}" --ipv6=false -s ${key_id} --snapshot="${os_choice}" --ddos="${ddos}" --userdata="${user_data}"
		fi 
 	fi
 
 	machine_id=""
 	count="0"
	while ( [ "${machine_id}" = "" ] && [ "${count}" -lt "10" ] )
	do
 		machine_id="`/usr/bin/vultr instance list -o json | /usr/bin/jq -r '.instances[] | select (.label == "'"${server_name}"'").id'`"
	   	/bin/sleep 5
     		count="`/usr/bin/expr ${count} + 1`"
	done
	
	/usr/bin/vultr vpc2 nodes attach ${vpc_id} --nodes="${machine_id}"
fi
