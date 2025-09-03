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

apt=""
if ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
then
	apt="/usr/bin/apt"
elif ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt-get" ] )
then
	apt="/usr/bin/apt-get"
fi

export DEBIAN_FRONTEND=noninteractive
install_command="${apt} -o DPkg::Lock::Timeout=-1 -o Dpkg::Use-Pty=0 -qq -y install " 

cwd="`/usr/bin/pwd`"

if ( [ "${apt}" != "" ] )
then
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd:repo'`" = "1" ] )
		then
			eval ${install_command} s3cmd	
		elif ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd:source'`" = "1" ] )
		then
			eval ${install_command} python3 python3-dateutil
			/usr/bin/ln -s /usr/bin/python3 /usr/bin/python
			cd /opt
			/usr/bin/git clone https://github.com/s3tools/s3cmd.git
			/bin/cp /opt/s3cmd/s3cmd /usr/bin/s3cmd
			/bin/cp -r /opt/s3cmd/S3 /usr/bin/
			/bin/rm -r /opt/s3cmd
		fi
	fi
	if ( [ "${BUILDOS}" = "debian" ] )
	then
		if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd:repo'`" = "1" ] )
		then
			eval ${install_command} s3cmd
		elif ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd:source'`" = "1" ] )
		then
			eval ${install_command} python3 python3-dateutil
			/usr/bin/ln -s /usr/bin/python3 /usr/bin/python
			cd /opt
			/usr/bin/git clone https://github.com/s3tools/s3cmd.git
			/bin/cp /opt/s3cmd/s3cmd /usr/bin/s3cmd
			/bin/cp -r /opt/s3cmd/S3 /usr/bin/
			/bin/rm -r /opt/s3cmd
			cd ${cwd}
		fi
	fi
fi

if ( [ -f ${HOME}/.s3cfg ] )
then
	/bin/cp ${HOME}/.s3cfg /root
fi

if ( [ ! -f /usr/bin/s3cmd ] )
then
	${HOME}/providerscripts/email/SendEmail.sh "INSTALLATION ERROR S3CMD" "I believe that s3cmd hasn't installed correctly, please investigate" "ERROR"
else
	/bin/touch ${HOME}/runtime/installedsoftware/InstallS3CMD.sh				
fi
