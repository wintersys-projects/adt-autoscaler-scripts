#!/bin/sh
######################################################################################################
# Description: This script will install the exo utility
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

export DEBIAN_FRONTEND=noninteractive

if ( [ "${BUILDOS}" = "ubuntu" ] )
then
	/usr/bin/curl -fsSL https://raw.githubusercontent.com/exoscale/cli/master/install-latest.sh | /bin/sh	
fi

if ( [ "${BUILDOS}" = "debian" ] )
then
	/usr/bin/curl -fsSL https://raw.githubusercontent.com/exoscale/cli/master/install-latest.sh | /bin/sh 	
fi

if ( [ ! -f /usr/bin/exo ] )
then
	${HOME}/providerscripts/email/SendEmail.sh "INSTALLATION ERROR EXO" "I believe that exo hasn't installed correctly, please investigate" "ERROR"
else
	/bin/touch ${HOME}/runtime/installedsoftware/InstallDoctl.sh				
fi
