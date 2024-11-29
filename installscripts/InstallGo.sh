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

cwd="`/usr/bin/pwd`"

if ( [ -d /root/scratch ] )
then
	cd /root/scratch
else
	/bin/mkdir /root/scatch
 	cd /root/scratch
fi

if ( [ "${buildos}" = "ubuntu" ] )
then
	DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install jq			#####UBUNTU-GO-REPO#####
	version="`/usr/bin/curl https://go.dev/dl/?mode=json | /usr/bin/jq -r '.[0].version' | /bin/sed 's/go//g'1`"		#####UBUNTU-GO-REPO#####
	/usr/bin/curl -O -s https://storage.googleapis.com/golang/go${version}.linux-amd64.tar.gz		#####UBUNTU-GO-REPO-SKIP#####
	/bin/tar -xf go${version}.linux-amd64.tar.gz								#####UBUNTU-GO-REPO-SKIP#####
	/bin/mv go /usr/local											#####UBUNTU-GO-REPO#####
	/bin/rm go${version}.linux-amd64.tar.gz									#####UBUNTU-GO-REPO-SKIP#####
	/usr/bin/ln -s /usr/local/go/bin/go /usr/bin/go								#####UBUNTU-GO-REPO#####
fi

if ( [ "${buildos}" = "debian" ] )
then
	DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install jq			#####DEBIAN-GO-REPO#####
	version="`/usr/bin/curl https://go.dev/dl/?mode=json | /usr/bin/jq -r '.[0].version' | /bin/sed 's/go//g'`"		#####DEBIAN-GO-REPO#####
	/usr/bin/curl -O -s https://storage.googleapis.com/golang/go${version}.linux-amd64.tar.gz		#####DEBIAN-GO-REPO-SKIP#####
	/bin/tar -xf go${version}.linux-amd64.tar.gz								#####DEBIAN-GO-REP-SKIP#####
	/bin/mv go /usr/local											#####DEBIAN-GO-REPO#####
	/bin/rm go${version}.linux-amd64.tar.gz									#####DEBIAN-GO-REPO-SKIP#####
	/usr/bin/ln -s /usr/local/go/bin/go /usr/bin/go								#####DEBIAN-GO-REPO#####
fi
cd ${cwd}
