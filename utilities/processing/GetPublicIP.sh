#!/bin/sh
######################################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Gets the public IP of the machine
########################################################################################################
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

IP="`/usr/bin/wget http://ipinfo.io/ip -qO -`"

if ( [ "${IP}" = "" ] )
then
	IP="`/usr/bin/curl -4 icanhazip.com`"
fi

if ( [ "${IP}" = "" ] )
then
	IP="`/bin/hostname -I | /usr/bin/awk '{print $1}'`"
fi

${HOME}/utilities/config/StoreConfigValue.sh 'MYPUBLICIP' "${IP}"
/bin/echo ${IP}


