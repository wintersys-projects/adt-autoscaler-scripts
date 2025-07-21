#!/bin/sh
######################################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : Cron can initiate a scaling event by calling this script
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

HOME="`/bin/cat /home/homedir.dat`"

scale_values="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh STATIC_SCALE`"
age="`${HOME}/providerscripts/datastore/configwrapper/AgeOfConfigFile.sh ${scale_values}`"

if ( [ "${age}" -le "600" ] )
then
	exit
fi

CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"

new_scale_value="${1}"

if ( [ ! -f ${HOME}/runtime/scaling ] )
then
	/bin/mkdir ${HOME}/runtime/scaling
fi

number_of_autoscalers="`${HOME}/providerscripts/server/NumberOfServers.sh "as-${REGION}-${BUILD_IDENTIFIER}" "${CLOUDHOST}"`"
number_of_webservers="${new_scale_value}"

base_number_of_webservers="`/usr/bin/expr ${number_of_webservers} / ${number_of_autoscalers}`"
total_base_number_of_webservers="`/usr/bin/expr ${base_number_of_webservers} \* ${number_of_autoscalers}`"
additional_number_of_webservers="`/usr/bin/expr ${number_of_webservers} - ${total_base_number_of_webservers}`"

new_scale_values="STATIC_SCALE"
for autoscaler_no in `printf "%d\n" $(seq 1 ${number_of_autoscalers})`
do
	if ( [ "${additional_number_of_webservers}" -gt "0" ] )
	then
		new_scale_values="${new_scale_values}:`/usr/bin/expr ${base_number_of_webservers} + 1`"
		additional_number_of_webservers="`/usr/bin/expr ${additional_number_of_webservers} - 1`"
	else
		new_scale_values="${new_scale_values}:${base_number_of_webservers}"
	fi
done

${HOME}/providerscripts/datastore/configwrapper/MultiDeleteConfigDatastore.sh STATIC_SCALE:

if ( [ -f ${HOME}/runtime/scaling/STATIC_SCALE:* ] )
then
	/bin/rm ${HOME}/runtime/scaling/STATIC_SCALE:*
fi

/bin/touch ${HOME}/runtime/scaling/${new_scale_values}
${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${HOME}/runtime/scaling/${new_scale_values} ${new_scale_values}
