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
#set -x

export HOME="`/bin/cat /home/homedir.dat`"

server_size="${1}"
server_name="${2}"

CLOUDHOST="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
SNAPSHOT_ID="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'WEBSERVERIMAGEID'`"
BUILDOS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
BUILDOS_VERSION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDOSVERSION'`"
REGION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'REGION'`"
DDOS_PROTECTION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ENABLEDDOSPROTECTION'`"
VPC_IP_RANGE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'VPCIPRANGE'`"
KEY_ID="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'KEYID'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
ACTIVE_FIREWALL="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ACTIVEFIREWALLS'`"

if ( [ "${SNAPSHOT_ID}" = "" ] )
then
        OS_CHOICE="`${HOME}/providerscripts/cloudhost/GetOperatingSystemVersion.sh`"
fi

if ( [ -f ${HOME}/DROPLET ] || [ "${CLOUDHOST}" = "digitalocean" ] )
then

        vpc_id="`/usr/local/bin/doctl vpcs list -o json | /usr/bin/jq -r '.[] | select (.region == "'${REGION}'") | select (.name == "adt-vpc").id'`"
        firewall_id="`/usr/local/bin/doctl -o json compute firewall list | /usr/bin/jq -r '.[] | select (.name == "adt-webserver-'${BUILD_IDENTIFIER}'" ).id'`"
        #Digital ocean supports snapshots so, we test to see if we want to use them
        if ( [ "${SNAPSHOT_ID}" != "" ] )
        then
                #If we get to here, then we are building from a snapshot and we pass the SNAPSHOT_ID in as the oschoice parameter
                OS_CHOICE="${SNAPSHOT_ID}"
        fi
        webserver_id="`/usr/local/bin/doctl compute droplet create "${server_name}" -o json --size "${server_size}" --image "${OS_CHOICE}"  --region "${REGION}" --ssh-keys "${KEY_ID}" --vpc-uuid "${vpc_id}" | /usr/bin/jq -r '.[].id'`"
       
        if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
        then
                /usr/local/bin/doctl compute firewall add-droplets ${firewall_id} --droplet-ids ${webserver_id}
        fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${CLOUDHOST}" = "exoscale" ] )
then
        template_visibility=" --template-visibility public "
        
        if ( [ "${SNAPSHOT_ID}" != "" ] )
        then
                OS_CHOICE="${SNAPSHOT_ID}"
                template_visibilty=" --template-visibility private "
        fi

        if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
        then
                /usr/bin/exo compute instance create "${server_name}" --instance-type standard.${server_size}  --security-group adt-webserver-${BUILD_IDENTIFIER} --template "${OS_CHOICE}" ${template_visibilty} --zone ${REGION} --ssh-key ${KEY_ID} --cloud-init "${HOME}/providerscripts/server/cloud-init/exoscale.dat"
        else
                /usr/bin/exo compute instance create "${server_name}" --instance-type standard.${server_size}  --template "${OS_CHOICE}" ${template_visibilty} --zone ${REGION} --ssh-key ${KEY_ID} --cloud-init "${HOME}/providerscripts/server/cloud-init/exoscale.dat"
        fi
  
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

        key="`/usr/local/bin/linode-cli --json sshkeys view ${KEY_ID} | /usr/bin/jq -r '.[].ssh_key'`"
        vpc_id="`/usr/local/bin/linode-cli --json vpcs list | /usr/bin/jq -r '.[] | select (.label == "adt-vpc").id'`"
        subnet_id="`/usr/local/bin/linode-cli --json vpcs subnets-list ${vpc_id} | /usr/bin/jq -r '.[] | select (.label == "adt-subnet").id'`"
 
        if ( [ "${SNAPSHOT_ID}" != "" ] )
        then
                OS_CHOICE="private/${SNAPSHOT_ID}"
        fi

        if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
        then
                firewall_id="`/usr/local/bin/linode-cli --json firewalls list | /usr/bin/jq -r '.[] | select (.label == "adt-autoscaler-'${BUILD_IDENTIFIER}'").id'`"
                #firewall_id="`/usr/local/bin/linode-cli --json firewalls list | /usr/bin/jq -r '.[] | select (.label | contains ("adt-webserver")) |  select (.label | endswith ("'-${BUILD_IDENTIFIER}'")).id'`"
                /usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass ${emergency_password} --region ${REGION} --image "${OS_CHOICE}" --firewall_id="${firewall_id}" --type ${server_size} --label "${server_name}" --no-defaults --interfaces.primary true --interfaces.purpose vpc --interfaces.subnet_id ${subnet_id} --interfaces.ipv4.nat_1_1 any
        else
                /usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass ${emergency_password} --region ${REGION} --image "${OS_CHOICE}" --type ${server_size} --label "${server_name}" --no-defaults --interfaces.primary true --interfaces.purpose vpc --interfaces.subnet_id ${subnet_id} --interfaces.ipv4.nat_1_1 any
        fi
fi

if ( [ -f ${HOME}/VULTR ] || [ "${CLOUDHOST}" = "vultr" ] )
then
        export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
        OS_CHOICE="`/usr/bin/vultr os list -o json | /usr/bin/jq -r '.os[] | select (.name | contains ("'"${OS_CHOICE}"'")).id'`"

        if ( [ "`/usr/bin/vultr vpc2 list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "adt-vpc").id'`" = "" ] )
        then
                /usr/bin/vultr vpc2 create --region="${REGION}" --description="adt-vpc" --ip-type="v4" --ip-block="192.168.0.0" --prefix-length="16"
        fi

        vpc_id="`/usr/bin/vultr vpc2 list -o json | /usr/bin/jq -r '.vpcs[] | select (.description == "adt-vpc").id'`"


        #Vultr supports snapshots, so decide if we are building from a snapshot
        if ( [ "${SNAPSHOT_ID}" != "" ] )
        then
                OS_CHOICE="${SNAPSHOT_ID}"
        fi

        user_data=`/bin/cat ${HOME}/providerscripts/server/cloud-init/vultr.dat`

        firewall_id="`/usr/bin/vultr firewall group list -o json | /usr/bin/jq -r '.firewall_groups[] | select (.description == "adt-autoscaler-'${BUILD_IDENTIFIER}'").id'`"

        ddos="false"
        if ( [ "${DDOS_PROTECTION}" = "1" ] )
        then
                ddos="true"
        fi
        if ( [ "${SNAPSHOT_ID}" = "" ] )
        then
                if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
                then
                        /usr/bin/vultr instance create --label="${server_name}" --region="${REGION}" --plan="${server_size}" --ipv6=false -s ${KEY_ID} --os="${OS_CHOICE}" --ddos="${ddos}" --userdata="${user_data}" --firewall-group="${firewall_id}"
                else
                        /usr/bin/vultr instance create --label="${server_name}" --region="${REGION}" --plan="${server_size}" --ipv6=false -s ${KEY_ID} --os="${OS_CHOICE}" --ddos="${ddos}" --userdata="${user_data}" 
                fi
        else
                if ( [ "${ACTIVE_FIREWALL}" = "2" ] || [ "${ACTIVE_FIREWALL}" = "3" ] )
                then
                        /usr/bin/vultr instance create --label="${server_name}" --region="${REGION}" --plan="${server_size}" --ipv6=false -s ${KEY_ID} --snapshot="${OS_CHOICE}" --ddos="${ddos}" --userdata="${user_data}" --firewall-group="${firewall_id}"
                else
                        /usr/bin/vultr instance create --label="${server_name}" --region="${REGION}" --plan="${server_size}" --ipv6=false -s ${KEY_ID} --snapshot="${OS_CHOICE}" --ddos="${ddos}" --userdata="${user_data}"
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
