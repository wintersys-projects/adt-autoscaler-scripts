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
CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"

new_scale_value="${1}"

if ( [ "${new_scale_value}" = "" ] )
then
        exit
fi

if ( [ ! -d ${HOME}/runtime/scaling ] )
then
        /bin/mkdir ${HOME}/runtime/scaling
fi

/bin/touch ${HOME}/runtime/scaling/STATIC_SCALE:${new_scale_value}
no_autoscaler="`/usr/bin/hostname | /bin/sed -e 's:NO-::' -e 's:-as.*::'`"
${HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "scaling" "*autoscaler-${no_autoscaler}*" "local" "scaling-${CLOUDHOST}-${REGION}"
${HOME}/providerscripts/datastore/operations/PutToDatastore.sh "scaling" "${HOME}/runtime/scaling/STATIC_SCALE:${new_scale_value}" "autoscaler-${no_autoscaler}" "local" "no" "scaling-${CLOUDHOST}-${REGION}"


