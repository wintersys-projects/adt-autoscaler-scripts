#!/bin/sh
######################################################################################################
# Description: This script will tell us the name of the operating system we are currently running
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

BUILDOS_VERSION="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOSVERSION'`"

HOME="`/bin/cat /home/homedir.dat`"


if ( [ "${BUILDOS}" = "ubuntu" ] )
then
        if ( [ "${BUILDOS_VERSION}" = "24.04" ] )
        then
                /bin/echo "noble"
        fi
fi

if ( [ "${BUILDOS}" = "debian" ] )
then
        if ( [ "${BUILDOS_VERSION}" = "13" ] )
        then
                /bin/echo "trixie"
        fi
fi
