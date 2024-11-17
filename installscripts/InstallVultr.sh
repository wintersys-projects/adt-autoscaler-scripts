#!/bin/sh
###############################################################################################
# Description: This script will install vultr toolkit
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
#set -x

if ( [ "${1}" != "" ] )
then
	buildos="${1}"
fi

if ( [ "${buildos}" = "ubuntu" ] )
then
	vultr_cli_version="`/usr/bin/curl -L https://api.github.com/repos/vultr/vultr-cli/releases/latest | /usr/bin/jq -r '.name'`"		#####DEBIAN-VULTR-BINARY#####
	/usr/bin/wget https://github.com/vultr/vultr-cli/releases/download/${vultr_cli_version}/vultr-cli_${vultr_cli_version}_linux_amd64.tar.gz -C /usr/bin/	#####DEBIAN-VULTR-BINARY#####
	/bin/mv /usr/bin/vultr-cli /usr/bin/vultr												#####DEBIAN-VULTR-BINARY#####
	/bin/chown root:root /usr/bin/vultr													#####DEBIAN-VULTR-BINARY#####
#	if ( [ ! -f /usr/bin/make ] )										#####UBUNTU-VULTR-SOURCE#####
#	then													#####UBUNTU-VULTR-SOURCE#####
#		DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq install make	#####UBUNTU-VULTR-SOURCE#####
#	fi													#####UBUNTU-VULTR-SOURCE#####
#	if ( [ ! -d /usr/local/src/vultr ] )									#####UBUNTU-VULTR-SOURCE#####
#	then													#####UBUNTU-VULTR-SOURCE#####
#		/bin/mkdir /usr/local/src/vultr									#####UBUNTU-VULTR-SOURCE#####
#	else													#####UBUNTU-VULTR-SOURCE#####
#		/bin/rm -r /usr/local/src/vultr/* 2>/dev/null							#####UBUNTU-VULTR-SOURCE#####
#	fi													#####UBUNTU-VULTR-SOURCE#####
#	cwd="`/usr/bin/pwd`"											#####UBUNTU-VULTR-SOURCE#####
#	cd /usr/local/src/vultr											#####UBUNTU-VULTR-SOURCE#####
#	
#	/usr/bin/git clone https://github.com/vultr/vultr-cli.git						#####UBUNTU-VULTR-SOURCE#####
#	cd vultr-cli												#####UBUNTU-VULTR-SOURCE#####
#	
#	/usr/bin/make builds/vultr-cli_linux_amd64								#####UBUNTU-VULTR-SOURCE#####
#	/bin/cp builds/vultr-cli_linux_amd64 /usr/bin/vultr							#####UBUNTU-VULTR-SOURCE#####
#	
#	cd ${cwd}												#####UBUNTU-VULTR-SOURCE-SKIP#####
fi

if ( [ "${buildos}" = "debian" ] )
then
	vultr_cli_version="`/usr/bin/curl -L https://api.github.com/repos/vultr/vultr-cli/releases/latest | /usr/bin/jq -r '.name'`"	#####DEBIAN-VULTR-BINARY#####
	/usr/bin/wget https://github.com/vultr/vultr-cli/releases/download/${vultr_cli_version}/vultr-cli_${vultr_cli_version}_linux_amd64.tar.gz -C /usr/bin/ #####DEBIAN-VULTR-BINARY#####
	/bin/mv /usr/bin/vultr-cli /usr/bin/vultr											#####DEBIAN-VULTR-BINARY#####
	/bin/chown root:root /usr/bin/vultr												#####DEBIAN-VULTR-BINARY#####
#	if ( [ ! -f /usr/bin/make ] )										#####DEBIAN-VULTR-SOURCE#####
#	then													#####DEBIAN-VULTR-SOURCE#####
#		DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq install make	#####DEBIAN-VULTR-SOURCE#####
#	fi													#####DEBIAN-VULTR-SOURCE#####
#	if ( [ ! -d /usr/local/src/vultr ] )									#####DEBIAN-VULTR-SOURCE#####
#	then													#####DEBIAN-VULTR-SOURCE#####
#		/bin/mkdir /usr/local/src/vultr									#####DEBIAN-VULTR-SOURCE#####
#	else													#####DEBIAN-VULTR-SOURCE#####
#		/bin/rm -r /usr/local/src/vultr/* 2>/dev/null							#####DEBIAN-VULTR-SOURCE#####
#	fi													#####DEBIAN-VULTR-SOURCE#####
#	cwd="`/usr/bin/pwd`"											#####DEBIAN-VULTR-SOURCE#####
#	cd /usr/local/src/vultr											#####DEBIAN-VULTR-SOURCE#####
#	
#	/usr/bin/git clone https://github.com/vultr/vultr-cli.git						#####DEBIAN-VULTR-SOURCE#####
#	cd vultr-cli												#####DEBIAN-VULTR-SOURCE#####
#	
#	/usr/bin/make builds/vultr-cli_linux_amd64								#####DEBIAN-VULTR-SOURCE#####
#	/bin/cp builds/vultr-cli_linux_amd64 /usr/bin/vultr							#####DEBIAN-VULTR-SOURCE#####
#	
#	cd ${cwd}												#####DEBIAN-VULTR-SOURCE-SKIP#####
fi


