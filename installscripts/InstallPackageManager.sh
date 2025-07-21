#!/bin/sh
######################################################################################################
# Description: This script will perform a software update
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
set -x

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

CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"

if ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
then
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		/usr/bin/yes | /usr/bin/dpkg --configure -a
		DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 install -y -qq apt-utils
	fi

	if ( [ "${BUILDOS}" = "debian" ] )
	then
		/usr/bin/yes | /usr/bin/dpkg --configure -a
		DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 install -y -qq apt-utils
	fi
fi

if ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt-fast" ] )
then
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		apt_fast_url='https://raw.githubusercontent.com/ilikenwf/apt-fast/master'

		if ( [ -f /usr/local/sbin/apt-fast ] )
		then
			/bin/rm -f /usr/local/sbin/apt-fast
		fi

		/usr/bin/wget "${apt_fast_url}"/apt-fast -O /usr/sbin/apt-fast
		/bin/chmod +x /usr/sbin/apt-fast

		if ( [ ! -f /etc/apt-fast.conf ] )
		then
			/usr/bin/wget "$apt_fast_url"/apt-fast.conf -O /etc/apt-fast.conf
		fi

		if ( [ -f /etc/apt/sources.list.d/ubuntu.sources ] )
		then
			/bin/sed -i "s/digitalocean/linode/g" /etc/apt/sources.list.d/ubuntu.sources
		fi

		${HOME}/installscripts/InstallAria2.sh "ubuntu"
		/bin/echo 'DOWNLOADBELOW="aria2c -c -s ${_MAXNUM} -x ${_MAXNUM} -k 1M -q --file-allocation=none"' >> /etc/apt-fast.conf
		/bin/sed -i 's/^#DOWNLOADBEFORE/DOWNLOADBEFORE/g' /etc/apt-fast.conf
		if ( [ "${CLOUDHOST}" = "digitalocean" ] )
		then
			/bin/echo "MIRRORS=( 'mirrors.linode.com' )" >> /etc/apt-fast.conf
		fi
		if ( [ "${CLOUDHOST}" = "linode" ] )
		then
			/bin/echo "MIRRORS=( 'mirrors.linode.com' )" >> /etc/apt-fast.conf
		fi
		/bin/echo "DLLIST=" >> /etc/apt-fast.conf
	fi

	if ( [ "${BUILDOS}" = "debian" ] )
	then
		apt_fast_url='https://raw.githubusercontent.com/ilikenwf/apt-fast/master'

		if ( [ -f /usr/local/sbin/apt-fast ] )
		then
			/bin/rm -f /usr/local/sbin/apt-fast
		fi

		/usr/bin/wget "${apt_fast_url}"/apt-fast -O /usr/sbin/apt-fast
		/bin/chmod +x /usr/sbin/apt-fast

		if ( [ ! -f /etc/apt-fast.conf ] )
		then
			/usr/bin/wget "$apt_fast_url"/apt-fast.conf -O /etc/apt-fast.conf
		fi

		if ( [ -f /etc/apt/mirrors/debian.list ] )
		then
			/bin/sed -i "s/digitalocean/linode/g" /etc/apt/mirrors/debian.list
		fi
		${HOME}/installscripts/InstallAria2.sh "debian"
		/bin/echo 'DOWNLOADBELOW="aria2c -c -s ${_MAXNUM} -x ${_MAXNUM} -k 1M -q --file-allocation=none"' >> /etc/apt-fast.conf
		/bin/sed -i 's/^#DOWNLOADBEFORE/DOWNLOADBEFORE/g' /etc/apt-fast.conf
		if ( [ "${CLOUDHOST}" = "digitalocean" ] )
		then
			/bin/echo "MIRRORS=( 'mirrors.linode.com' )" >> /etc/apt-fast.conf
		fi
		if ( [ "${CLOUDHOST}" = "linode" ] )
		then
			/bin/echo "MIRRORS=( 'mirrors.linode.com' )" >> /etc/apt-fast.conf
		fi
		/bin/echo "DLLIST=" >> /etc/apt-fast.conf
	fi
fi
