#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will get the operating system version
######################################################################################
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
###################################################################################
###################################################################################
#set -x

BUILDOS="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
BUILDOS_VERSION="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOSVERSION'`"
CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"


if ( [ -f ${HOME}/DROPLET ] || [ "${CLOUDHOST}" = "digitalocean" ] )
then
	BUILDOS_VERSION="`/bin/echo ${BUILDOS_VERSION} | /bin/sed 's/\./-/g'`"
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		/bin/echo "ubuntu-${BUILDOS_VERSION}-x64"
	elif ( [ "${BUILDOS}" = "debian" ] )
	then
		/bin/echo "debian-${BUILDOS_VERSION}-x64"
	fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${CLOUDHOST}" = "exoscale" ] )
then
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		if ( [ "${BUILDOS_VERSION}" = "24.04" ] )
		then
			/bin/echo "Linux Ubuntu ${BUILDOS_VERSION} LTS 64-bit"
		fi
	elif ( [ "${BUILDOS}" = "debian" ] )
	then
   		if ( [ "${BUILDOS_VERSION}" = "12" ] )
   		then
			/bin/echo "Linux Debian ${BUILDOS_VERSION} (Bookworm) 64-bit"
		elif ( [ "${BUILDOS_VERSION}" = "13" ] )
		then
  			/bin/echo "Linux Debian ${BUILDOS_VERSION} (Trixie) 64-bit"
		fi
	fi
fi

if ( [ -f ${HOME}/LINODE ] || [ "${CLOUDHOST}" = "linode" ] )
then
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		/bin/echo "linode/ubuntu${BUILDOS_VERSION}"
	elif ( [ "${BUILDOS}" = "debian" ] )
	then
		/bin/echo "linode/debian${BUILDOS_VERSION}"
	fi
fi

if ( [ -f ${HOME}/VULTR ] || [ "${CLOUDHOST}" = "vultr" ] )
then
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		/bin/echo "Ubuntu ${BUILDOS_VERSION} LTS x64"
	elif ( [ "${BUILDOS}" = "debian" ] )
	then
		/bin/echo "Debian ${BUILDOS_VERSION} x64"
	fi
fi
