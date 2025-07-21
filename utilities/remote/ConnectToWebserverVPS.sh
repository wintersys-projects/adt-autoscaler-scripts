#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Connect to the Database Server machine (linux)
#################################################################################
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
#####################################################################################
#####################################################################################
#set -x

command="${1}"
arg="${2}"
arg1="${3}"
arg2="${4}"
arg3="${5}"


SERVER_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
SSH_PORT="`${HOME}/utilities/config/ExtractConfigValue.sh 'SSHPORT'`"
ALGORITHM="`${HOME}/utilities/config/ExtractConfigValue.sh 'ALGORITHM'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"

ips="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh webserverips/*`"

if ( [ "${ips}" != "" ] )
then
	for ip in ${ips}
	do
		/bin/echo "Do you want to connect to webserver with ip address ${ip} (Y|N)"
		read response
		if ( [ "`/bin/echo 'Y y' | /bin/grep ${response}`" != "" ] )
		then
			if ( [ "${command}" != "" ] )
			then
				/usr/bin/ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${command}" "${arg}" "${arg1}" "${arg2}" "${arg3}"
			else
				/usr/bin/ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${SERVER_USER}@${ip}
			fi
			exit
		fi
	done
fi
