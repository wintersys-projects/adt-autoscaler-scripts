#!/bin/sh
########################################################################################
# Author: Peter Winter
# Date  : 12/07/2021
# Description : If you need to do anything with the native firewalls you can do it here
########################################################################################
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
#########################################################################################
#########################################################################################
#set -x

if ( [ "`${HOME}/providerscripts/utilities/config/CheckConfigValue.sh ACTIVEFIREWALLS:2`" = "0" ] && [ "`${HOME}/providerscripts/utilities/config/CheckConfigValue.sh ACTIVEFIREWALLS:3`" = "0" ] )
then
        exit
fi

CLOUDHOST="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
REGION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'REGION'`"

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLED_SUCCESSFULLY"`" = "0" ] )
then
	exit
fi

if ( [ -f ${HOME}/DROPLET ] )
then   
	:
fi

if ( [ -f ${HOME}/EXOSCALE ] )
then   
	:
fi

if ( [ -f ${HOME}/LINODE ] )
then
	:
fi

if ( [ -f ${HOME}/VULTR ] )
then
	:
fi


if ( [ -f ${HOME}/VULTR ] )
then
:
fi
