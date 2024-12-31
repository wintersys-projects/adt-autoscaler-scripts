#!/bin/sh
##########################################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : This script can be used to scale down the number of webservers. Just call it from crontab
##########################################################################################################
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

if ( [ "${1}" = "" ] )
then
	exit
fi

new_scale_value="${1}"

/bin/echo "${0} `/bin/date`: Running daily scaledown. Scaling down to ..... ${new_scale_value} servers" >> ${HOME}/logs/OPERATIONAL_MONITORING.log

${HOME}/providerscripts/datastore/configwrapper/MultiDeleteConfigDatastore.sh STATIC_SCALE:
if ( [ -f ${HOME}/runtime/STATIC_SCALE:* ] )
then
        /bin/rm ${HOME}/runtime/STATIC_SCALE:*
fi
/bin/touch ${HOME}/runtime/STATIC_SCALE:${new_scale_value}
${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${HOME}/runtime/STATIC_SCALE:${new_scale_value} STATIC_SCALE:${new_scale_value}




