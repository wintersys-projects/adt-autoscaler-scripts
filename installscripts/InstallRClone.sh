#!/bin/sh
######################################################################################################
# Description: This script will install the rclone utility
# Author: Peter Winter
# Date: 17/01/2017
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
		if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTOREMOUNTTOOL:rclone:repo'`" = "1" ] )
		then
			eval ${install_command} fuse3 rclone	
		fi
		if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTOREMOUNTTOOL:rclone:binary'`" = "1" ] )
		then
			eval ${install_command} unzip	
			cd /opt
			/usr/bin/wget https://downloads.rclone.org/rclone-current-linux-amd64.zip
			/usr/bin/unzip /opt/rclone*.zip
			/bin/cp rclone*amd64/rclone /usr/bin/rclone
			cd ${cwd}
		fi
		if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTOREMOUNTTOOL:rclone:source'`" = "1" ] )
		then
			eval ${install_command} fuse3
			${HOME}/installscripts/InstallGo.sh ${BUILDOS}
			cd /opt
			/usr/bin/git clone https://github.com/rclone/rclone.git 
			cd /opt/rclone
			/usr/bin/go build
			/bin/mv /opt/rclone/rclone /usr/bin/rclone
			/usr/bin/ln -s /usr/bin/fusermount /usr/bin/fusermount3
			/bin/rm -r /opt/rclone
			cd ${cwd}
		fi
	fi

	if ( [ "${BUILDOS}" = "debian" ] )
	then
		if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTOREMOUNTTOOL:rclone:repo'`" = "1" ] )
		then
			eval ${install_command} fuse3 rclone
		fi
		if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTOREMOUNTTOOL:rclone:binary'`" = "1" ] )
		then
			eval ${install_command} unzip fuse3
			cd /opt
			/usr/bin/wget https://downloads.rclone.org/rclone-current-linux-amd64.zip
			/usr/bin/unzip /opt/rclone*.zip
			/bin/cp rclone*amd64/rclone /usr/bin/rclone
			cd ${cwd}	
		fi
		if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTOREMOUNTTOOL:rclone:source'`" = "1" ] )
		then
			eval ${install_command} fuse3
			${HOME}/installscripts/InstallGo.sh ${BUILDOS}
			cd /opt
			/usr/bin/git clone https://github.com/rclone/rclone.git 
			cd /opt/rclone
			/usr/bin/go build
			/bin/mv /opt/rclone/rclone /usr/bin/rclone
			/usr/bin/ln -s /usr/bin/fusermount /usr/bin/fusermount3
			/bin/rm -r /opt/rclone
			cd ${cwd}
		fi
	fi
fi

if ( [ ! -f /usr/bin/rclone ] )
then
	${HOME}/providerscripts/email/SendEmail.sh "INSTALLATION ERROR RCLONE" "I believe that rclone hasn't installed correctly, please investigate" "ERROR"
else
	/bin/touch ${HOME}/runtime/installedsoftware/InstallRClone.sh	
fi
