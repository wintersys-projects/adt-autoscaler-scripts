#!/bin/sh
######################################################################################################
# Description: This script will install the linode cli
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

USER_HOME="`/usr/bin/awk -F: '{ print $1}' /etc/passwd | /bin/grep "X*X"`"
export HOME="/home/${USER_HOME}" | /usr/bin/tee -a ~/.bashrc

if ( [ "${1}" != "" ] )
then
	buildos="${1}"
fi

if ( [ "${buildos}" = "ubuntu" ] )
then
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install pipx		#####UBUNTU-LINODECLIL-REPO#####
	if ( [ -f /usr/local/bin/linode-cli ] )									#####UBUNTU-LINODECLIL-REPO#####
	then													#####UBUNTU-LINODECLIL-REPO#####
		/usr/bin/pipx upgrade linode-cli 								#####UBUNTU-LINODECLIL-REPO#####
	else													#####UBUNTU-LINODECLIL-REPO#####
		/usr/bin/pipx install linode-cli 								#####UBUNTU-LINODECLIL-REPO#####
  		/bin/rm /usr/local/bin/linode-cli								#####UBUNTU-LINODECLIL-REPO#####
		/usr/bin/ln -s ${HOME}/.local/bin/linode-cli /usr/local/bin/linode-cli				#####UBUNTU-LINODECLIL-REPO#####
	fi													#####UBUNTU-LINODECLIL-REPO#####
fi

if ( [ "${buildos}" = "debian" ] )
then
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install pipx		#####DEBIAN-LINODECLIL-REPO#####
	if ( [ -f /usr/local/bin/linode-cli ] )									#####DEBIAN-LINODECLIL-REPO#####
	then													#####DEBIAN-LINODECLIL-REPO#####
		/usr/bin/pipx upgrade linode-cli 								#####DEBIAN-LINODECLIL-REPO#####
	else													#####DEBIAN-LINODECLIL-REPO#####
		/usr/bin/pipx install linode-cli 								#####DEBIAN-LINODECLIL-REPO#####
		/bin/rm /usr/local/bin/linode-cli								#####DEBIAN-LINODECLIL-REPO#####
		/usr/bin/ln -s ${HOME}/.local/bin/linode-cli /usr/local/bin/linode-cli				#####DEBIAN-LINODECLIL-REPO#####
	fi													#####DEBIAN-LINODECLIL-REPO#####
fi

