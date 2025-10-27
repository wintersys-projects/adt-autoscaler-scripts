#!/bin/sh
######################################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script spins up a machine of the specified size, name and so on on our chosen provider
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
#set -x

export HOME="`/bin/cat /home/homedir.dat`"

server_size="${1}"
server_name="${2}"

CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
BUILDOS="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
BUILDOS_VERSION="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOSVERSION'`"
REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"
DDOS_PROTECTION="`${HOME}/utilities/config/ExtractConfigValue.sh 'ENABLEDDOSPROTECTION'`"
VPC_IP_RANGE="`${HOME}/utilities/config/ExtractConfigValue.sh 'VPCIPRANGE'`"
VPC_NAME="`${HOME}/utilities/config/ExtractConfigValue.sh 'VPCNAME'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
ACTIVE_FIREWALL="`${HOME}/utilities/config/ExtractConfigValue.sh 'ACTIVEFIREWALLS'`"
BUILD_FROM_SNAPSHOT="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDFROMSNAPSHOT'`"
OS_CHOICE="`${HOME}/providerscripts/server/GetOperatingSystemVersion.sh`"

SNAPSHOT_ID=""
if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] )
then
	SNAPSHOT_ID="`${HOME}/utilities/config/ExtractConfigValue.sh 'SNAPSHOTID'`"
fi

if ( [ -f ${HOME}/DROPLET ] || [ "${CLOUDHOST}" = "digitalocean" ] )
then
	vpc_id="`/usr/local/bin/doctl vpcs list -o json | /usr/bin/jq -r '.[] | select (.region == "'${REGION}'") | select (.name == ("'${VPC_NAME}'")).id'`"
	firewall_id="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "adt-webserver-'${BUILD_IDENTIFIER}'" ).id'`"

	/bin/sed -i "s/XXXXWEBSERVER_HOSTNAMEXXXX/${server_name}/g" ${HOME}/runtime/cloud-init/webserver.yaml
	cloud_config="`/bin/cat ${HOME}/runtime/cloud-init/webserver.yaml`"

	image="--image ${OS_CHOICE}"

	if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ "${SNAPSHOT_ID}" != "" ] )
	then
		image="--image ${SNAPSHOT_ID}"
	fi

 	key_id="`/usr/local/bin/doctl compute ssh-key list -o json | /usr/bin/jq '.[] | select (.name == "AGILE_TOOLKIT_PUBLIC_KEY-'${BUILD_IDENTIFIER}'").id'`" 

	webserver_id="`/usr/local/bin/doctl compute droplet create "${server_name}" -o json --size "${server_size}" ${image} --region "${REGION}" --ssh-keys "${key_id}" --vpc-uuid "${vpc_id}" --user-data "${cloud_config}" | /usr/bin/jq -r '.[].id'`"

	/bin/sleep 5

	if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
	then
		/usr/local/bin/doctl compute firewall add-droplets ${firewall_id} --droplet-ids ${webserver_id}
	fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${CLOUDHOST}" = "exoscale" ] )
then
	template_visibility=" --template-visibility public "

	/bin/sed -i "s/XXXXWEBSERVER_HOSTNAMEXXXX/${server_name}/g" ${HOME}/runtime/cloud-init/webserver.yaml
	cloud_config="${HOME}/runtime/cloud-init/webserver.yaml"

	if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ "${SNAPSHOT_ID}" != "" ] )
	then
		OS_CHOICE="${SNAPSHOT_ID}"
		template_visibility="--template-visibility private"
	fi
 
 	user_data="--cloud-init ${cloud_config}"

	firewall=""

	if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
	then
		firewall="--security-group adt-webserver-${BUILD_IDENTIFIER} "
	fi

	/usr/bin/exo compute instance create "${server_name}" --instance-type standard.${server_size}  ${firewall} --template "${OS_CHOICE}" ${template_visibility} --zone ${REGION} ${user_data}

	if ( [ "`/usr/bin/exo compute private-network list -O json | /usr/bin/jq -r '.[] | select (.name == "adt_private_net_'${REGION}'").id'`" = "" ] )
	then
		/usr/bin/exo compute private-network create adt_private_net_${REGION} --zone ${REGION} --start-ip 10.0.0.20 --end-ip 10.0.0.200 --netmask 255.255.255.0
	fi
	/usr/bin/exo compute instance private-network attach  ${server_name} adt_private_net_${REGION} --zone ${REGION}
fi


if ( [ -f ${HOME}/LINODE ] || [ "${CLOUDHOST}" = "linode" ] )
then
	if ( [ -f ${HOME}/.ssh/EMERGENCY_PASSWORD ] )
	then
		emergency_password="`/bin/cat ${HOME}/.ssh/EMERGENCY_PASSWORD`"
	fi

	#key="`/usr/local/bin/linode-cli --json sshkeys view ${KEY_ID} | /usr/bin/jq -r '.[].ssh_key'`"
	vpc_id="`/usr/local/bin/linode-cli --json vpcs list | /usr/bin/jq -r '.[] | select (.label == "'${VPC_NAME}'").id'`"
	subnet_id="`/usr/local/bin/linode-cli --json vpcs subnets-list ${vpc_id} | /usr/bin/jq -r '.[] | select (.label == "adt-subnet").id'`"

	/bin/sed -i "s/XXXXWEBSERVER_HOSTNAMEXXXX/${server_name}/g" ${HOME}/runtime/cloud-init/webserver.yaml
	cloud_config="`/bin/cat ${HOME}/runtime/cloud-init/webserver.yaml | /usr/bin/base64 -w 0`"

	image="--image ${OS_CHOICE}"

	if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ "${SNAPSHOT_ID}" != "" ] )
	then
		image="--image ${SNAPSHOT_ID}"
	fi
 
	user_data="--metadata.user_data ${cloud_config}"

	if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
	then
		firewall_id="`/usr/local/bin/linode-cli --json firewalls list | /usr/bin/jq -r '.[] | select (.label == "adt-webserver-'${BUILD_IDENTIFIER}'").id'`"
		/usr/local/bin/linode-cli linodes create --root_pass "${emergency_password}" --region ${REGION} ${image} --firewall_id="${firewall_id}"  --type ${server_size} --label "${server_name}" --no-defaults --interface_generation "linode" --interfaces ' [ { "purpose": "public", "firewall_id": '${firewall_id}', "default_route": { "ipv4": true }, "public": { "ipv4": { "addresses": [ { "address": "auto", "primary": true } ] } } }, { "purpose": "vpc", "firewall_id": '${firewall_id}',  "vpc": { "ipv4": { "addresses": [ { "address": "auto", "primary": true } ] } , "subnet_id": '${subnet_id}' } } ]' ${user_data} --disk_encryption "enabled"	
	else
		/usr/local/bin/linode-cli linodes create --root_pass "${emergency_password}" --region ${REGION} ${image} --type ${server_size} --label "${server_name}" --no-defaults --interface_generation "linode" --interfaces ' [ { "purpose": "public", "firewall_id": '${firewall_id}', "default_route": { "ipv4": true }, "public": { "ipv4": { "addresses": [ { "address": "auto", "primary": true } ] } } }, { "purpose": "vpc", "firewall_id": '${firewall_id}',  "vpc": { "ipv4": { "addresses": [ { "address": "auto", "primary": true } ] } , "subnet_id": '${subnet_id}' } } ]' ${user_data} --disk_encryption "enabled"	
	fi
fi

if ( [ -f ${HOME}/VULTR ] || [ "${CLOUDHOST}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	OS_CHOICE="`/usr/bin/vultr os list -o json | /usr/bin/jq -r --arg os_choice "${OS_CHOICE}" '.os[] | select (.name | contains ($os_choice)).id'`"

	#  if ( [ "`/usr/bin/vultr vpc2 list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "adt-vpc").id'`" = "" ] )
	if ( [ "`/usr/bin/vultr vpc list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "'${VPC_NAME}'").id'`" = "" ] )
	then
		# /usr/bin/vultr vpc2 create --region="${REGION}" --description="${VPC_NAME}" --ip-type="v4" --ip-block="192.168.0.0" --prefix-length="16"
		subnet="`/bin/echo ${VPC_IP_RANGE} | /usr/bin/awk -F'/' '{print $1}'`"
		size="`/bin/echo ${VPC_IP_RANGE} | /usr/bin/awk -F'/' '{print $2}'`"
		/usr/bin/vultr vpc create --region="${REGION}" --description="${VPC_NAME}" --subnet="${subnet}" --size="${size}"
	fi

	#vpc_id="`/usr/bin/vultr vpc2 list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "adt-vpc").id'`"
	vpc_id="`/usr/bin/vultr vpc list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "'${VPC_NAME}'").id'`"

	firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-webserver-'${BUILD_IDENTIFIER}'").id'`"

	snapshot=""
	os="--os=${OS_CHOICE}"

	if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] && [ "${SNAPSHOT_ID}" != "" ] )
	then
		snapshot="--snapshot=${SNAPSHOT_ID}"
		os=""
	fi

	cloud_config="${HOME}/runtime/cloud-init/webserver.yaml"
 
	ddos=""
	if ( [ "${DDOS_PROTECTION}" = "1" ] )
	then
		ddos="--ddos=true"
	fi

	firewall=""
	if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
	then
		firewall="--firewall-group=${firewall_id}"
	fi

	/bin/sed -i "s/XXXXWEBSERVER_HOSTNAMEXXXX/${server_name}/g" ${HOME}/runtime/cloud-init/webserver.yaml

	/usr/bin/vultr instance create --label="${server_name}" --region="${REGION}" --plan="${server_size}" --ipv6=false ${snapshot} ${os} ${ddos} ${firewall} --userdata="`/bin/cat ${cloud_config}`" --vpc-enable --vpc-ids ${vpc_id}

fi
