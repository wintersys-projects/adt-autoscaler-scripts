#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description: This will update the software
#######################################################################################
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
########################################################################################
########################################################################################
#set -x

BUILDOS="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"

if ( [ "`${HOME}/utilities/config/CheckConfigValue.sh BUILDOS:ubuntu`" = "1" ] || [ "`${HOME}/utilities/config/CheckConfigValue.sh BUILDOS:debian`" = "1" ] )
then
	${HOME}/installscripts/UpdateAndUpgrade.sh ${BUILDOS}   
fi

for script in `/usr/bin/find ${HOME}/runtime/installedsoftware/ -name "*.sh" -print | /usr/bin/awk -F'/' '{print $NF}'`
do
	/bin/sh ${HOME}/installscripts/${script} ${BUILDOS}
done

${HOME}/utilities/UpdateInfrastructure.sh

/usr/sbin/shutdown -r now


