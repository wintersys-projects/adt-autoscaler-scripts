#!/bin/sh
###################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Install the s3cmd tool for manipulating the Datastores
####################################################################################
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

if ( [ "${1}" != "" ] )
then
	buildos="${1}"
fi

if ( [ "${buildos}" = "" ] )
then
	BUILDOS="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
else 
	BUILDOS="${buildos}"
fi

cwd="`/usr/bin/pwd`"

if ( [ "${BUILDOS}" = "ubuntu" ] )
then
	if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd:binary'`" = "1" ] )
	then
		cd /opt
		/usr/bin/wget "`/usr/bin/wget -q -O - https://api.github.com/repos/peak/s5cmd/releases/latest  | /usr/bin/jq -r '.assets[] | select (.name | contains ("amd64"))'.browser_download_url`"
		/usr/bin/dpkg -i /opt/s5cmd_*_linux_amd64.deb
		/bin/rm /opt/s5cmd_*_linux_amd64.deb
		cd ${cwd}
	fi
	if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd:source'`" = "1" ] )
	then	
		cd /opt
		${HOME}/installscripts/InstallGo.sh ${BUILDOS}
		GOBIN=`/usr/bin/pwd` /usr/bin/go install github.com/peak/s5cmd/v2@latest                 
		/bin/mv /opt/s5cmd /usr/bin/s5cmd  
		cd ${cwd}
	fi
fi
if ( [ "${BUILDOS}" = "debian" ] )
then
	if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd:binary'`" = "1" ] )
	then
		cd /opt
		/usr/bin/wget "`/usr/bin/wget -q -O - https://api.github.com/repos/peak/s5cmd/releases/latest  | /usr/bin/jq -r '.assets[] | select (.name | contains ("amd64"))'.browser_download_url`"
		/usr/bin/dpkg -i /opt/s5cmd_*_linux_amd64.deb
		/bin/rm /opt/s5cmd_*_linux_amd64.deb
		cd ${cwd}
	fi
	if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd:source'`" = "1" ] )
	then	
		cd /opt
		${HOME}/installscripts/InstallGo.sh ${BUILDOS}
		GOBIN=`/usr/bin/pwd` /usr/bin/go install github.com/peak/s5cmd/v2@latest                 
		/bin/mv /opt/s5cmd /usr/bin/s5cmd  
		cd ${cwd}                                     											
	fi				
fi  

if ( [ ! -f /usr/bin/s5cmd ] )
then
	${HOME}/providerscripts/email/SendEmail.sh "INSTALLATION ERROR S5CMD" "I believe that s5cmd hasn't installed correctly, please investigate" "ERROR"
else
	/bin/touch ${HOME}/runtime/installedsoftware/InstallS5CMD.sh				
fi
