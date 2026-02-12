#!/bin/sh
############################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : Record the IP address of the autoscaler
############################################################################################
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
#############################################################################################
#############################################################################################
#set -x

ip="`${HOME}/utilities/processing/GetIP.sh`"
public_ip="`${HOME}/utilities/processing/GetPublicIP.sh`"
build_machine_ip="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDMACHINEIP'`"

if ( [ "${ip}" = "" ] || [ "${public_ip}" = "" ] || [ "${build_machine_ip}" = "" ] )
then
        exit
fi

${HOME}/providerscripts/datastore/config/wrapper/PutToDatastore.sh "config" "${ip}" "autoscalerips" "no"
${HOME}/providerscripts/datastore/config/wrapper/PutToDatastore.sh "config" "${public_ip}" "autoscalerpublicips" "no"
${HOME}/providerscripts/datastore/config/wrapper/PutToDatastore.sh "config" "${build_machine_ip}" "buildmachineip" "no"
