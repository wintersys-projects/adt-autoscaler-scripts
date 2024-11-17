#!/bin/sh
###############################################################################################
# Description: This script will install tugboat
# Author: Peter Winter
# Date: 12/01/2017
###############################################################################################
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
################################################################################################
################################################################################################

if ( [ "${1}" != "" ] )
then
	buildos="${1}"
fi

if ( [ "${buildos}" = "ubuntu" ] )
then
	 DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1  -qq -y install snapd	#####UBUNTU-DOCTL-REPO#####
	 snap="`/usr/bin/whereis snap | /usr/bin/awk -F':' '{print $NF}' | /usr/bin/awk '{print $1}'`"		#####UBUNTU-DOCTL-REPO#####
	 ${snap} install doctl											#####UBUNTU-DOCTL-REPO#####
	 /usr/bin/ln -s /snap/bin/doctl /usr/local/bin/doctl							#####UBUNTU-DOCTL-REPO#####
	 /bin/mkdir -p /root/.config/doctl 									#####UBUNTU-DOCTL-REPO#####
	 /bin/cp ${HOME}/.config/doctl/config.yaml /root/.config/doctl						#####UBUNTU-DOCTL-REPO#####
	 /bin/chmod 400 ${HOME}/.config/doctl/config.yaml /root/.config/doctl/config.yaml			#####UBUNTU-DOCTL-REPO#####
fi

if ( [ "${buildos}" = "debian" ] )
then
	 DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1  -qq -y install snapd	#####DEBIAN-DOCTL-REPO#####
	 snap="`/usr/bin/whereis snap | /usr/bin/awk -F':' '{print $NF}' | /usr/bin/awk '{print $1}'`"		#####DEBIAN-DOCTL-REPO#####
	 ${snap} install doctl											#####DEBIAN-DOCTL-REPO#####
	 /usr/bin/ln -s /snap/bin/doctl /usr/local/bin/doctl							#####DEBIAN-DOCTL-REPO#####
	 /bin/mkdir -p /root/.config/doctl 									#####DEBIAN-DOCTL-REPO#####
	 /bin/cp ${HOME}/.config/doctl/config.yaml /root/.config/doctl						#####DEBIAN-DOCTL-REPO#####
	 /bin/chmod 400 ${HOME}/.config/doctl/config.yaml /root/.config/doctl/config.yaml			#####DEBIAN-DOCTL-REPO#####
fi

