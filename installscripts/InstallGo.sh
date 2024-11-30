#!/bin/sh
######################################################################################################
# Description: This script will install go
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

if ( [ "${apt}" != "" ] )
then
	if ( [ "${buildos}" = "ubuntu" ] )
	then
        	DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install jq                       #####UBUNTU-GO-BINARY#####
        	version="`/usr/bin/curl https://go.dev/dl/?mode=json | /usr/bin/jq -r '.[0].version' | /bin/sed 's/go//g'1`"            #####UBUNTU-GO-BINARY#####
        	/usr/bin/wget -c https://storage.googleapis.com/golang/go${version}.linux-amd64.tar.gz  -O - | /usr/bin/tar -xz -C /usr/local   #####UBUNTU-GO-BINARY-SKIP#####
        	
 		if ( [ ! -L /usr/bin/go ] )										#####UBUNTU-GO-BINARY#####
 		then													#####UBUNTU-GO-BINARY#####
        		/usr/bin/ln -s /usr/local/go/bin/go /usr/bin/go 						#####UBUNTU-GO-BINARY#####
 		fi	 												#####UBUNTU-GO-BINARY#####
	fi
	if ( [ "${buildos}" = "debian" ] )
	then
        	DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install jq                       #####DEBIAN-GO-BINARY#####
        	version="`/usr/bin/curl https://go.dev/dl/?mode=json | /usr/bin/jq -r '.[0].version' | /bin/sed 's/go//g'1`"            #####DEBIAN-GO-BINARY#####
        	/usr/bin/wget -c https://storage.googleapis.com/golang/go${version}.linux-amd64.tar.gz  -O - | /usr/bin/tar -xz -C /usr/local   #####DEBIAN-GO-BINARY-SKIP#####
        	
 		if ( [ ! -L /usr/bin/go ] )										#####DEBIAN-GO-BINARY#####
 		then													#####DEBIAN-GO-BINARY#####
        		/usr/bin/ln -s /usr/local/go/bin/go /usr/bin/go 						#####DEBIAN-GO-BINARY#####
 		fi	 												#####DEBIAN-GO-BINARY#####
	fi
fi

