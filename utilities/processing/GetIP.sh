#!/bin/sh
############################################################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : Gets the private ip address of the machine. In certain cases, it also refreshes or reinitialises
# the private networking.
###############################################################################################################################
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
##set -x

if ( [ -f ${HOME}/EXOSCALE ] )
then
	/usr/sbin/dhclient 1>/dev/null 2>/dev/null
fi

private_ip_anchor="`${HOME}/utilities/config/ExtractConfigValue.sh 'VPCIPRANGE' | /usr/bin/awk -F'.' '{print $1}'`"
/usr/bin/nmcli -p device show | grep "IP4\.ADDRESS\[1\]" | /usr/bin/awk '{print $NF}' | /bin/grep "^${private_ip_anchor}\." | /bin/sed "s,/.*,," | /usr/bin/tail -1
${HOME}/utilities/config/StoreConfigValue.sh 'MYIP' "${IP}"

