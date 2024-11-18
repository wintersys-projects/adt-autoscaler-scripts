#!/bin/sh
######################################################################################################
# Description: This script will install iptables
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

HOME="`/bin/cat /home/homedir.dat`"

if ( [ "${1}" != "" ] )
then
	buildos="${1}"
fi

apt=""
if ( [ "`${HOME}/providerscripts/utilities/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
then
	apt="/usr/bin/apt-get"
elif ( [ "`${HOME}/providerscripts/utilities/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt-fast" ] )
then
	apt="/usr/sbin/apt-fast"
fi

if ( [ "${apt}" != "" ] )
then
	if ( [ "${buildos}" = "ubuntu" ] )
	then
                DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install iptables			#####UBUNTU-IPTABLES-REPO#####

                /usr/bin/debconf-set-selections <<EOF									#####UBUNTU-IPTABLES-REPO#####
iptables-persistent iptables-persistent/autosave_v4 boolean true							#####UBUNTU-IPTABLES-REPO#####
iptables-persistent iptables-persistent/autosave_v6 boolean true							#####UBUNTU-IPTABLES-REPO#####
EOF															#####UBUNTU-IPTABLES-REPO#####
                DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install netfilter-persistent	#####UBUNTU-IPTABLES-REPO#####
                DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install iptables-persistent	#####UBUNTU-IPTABLES-REPO#####
	  	if ( [ -f /usr/sbin/ufw ] )										#####UBUNTU-IPTABLES-REPO#####
   		then													#####UBUNTU-IPTABLES-REPO#####
     			/usr/sbin/ufw disable										#####UBUNTU-IPTABLES-REPO#####
		fi													#####UBUNTU-IPTABLES-REPO#####
 	fi

	if ( [ "${buildos}" = "debian" ] )
	then
                DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install iptables			#####DEBIAN-IPTABLES-REPO#####

                /usr/bin/debconf-set-selections <<EOF									#####DEBIAN-IPTABLES-REPO#####
iptables-persistent iptables-persistent/autosave_v4 boolean true							#####DEBIAN-IPTABLES-REPO#####
iptables-persistent iptables-persistent/autosave_v6 boolean true							#####DEBIAN-IPTABLES-REPO#####
EOF															#####DEBIAN-IPTABLES-REPO#####
                DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install netfilter-persistent	#####DEBIAN-IPTABLES-REPO#####
                DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install iptables-persistent	#####DEBIAN-IPTABLES-REPO#####
          	if ( [ -f /usr/sbin/ufw ] )										#####DEBIAN-IPTABLES-REPO#####
   		then													#####DEBIAN-IPTABLES-REPO#####
     			/usr/sbin/ufw disable										#####DEBIAN-IPTABLES-REPO#####
		fi													#####DEBIAN-IPTABLES-REPO#####
	fi
fi
