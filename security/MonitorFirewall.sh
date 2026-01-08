#!/bin/sh
#########################################################################################################################
# Description: This script will check if the firewall is active and will send an email, every five minutes, to the systems
# administrator to tell them that the firewall is inactive. This is just a safety measure
# Author: Peter Winter
# Date: 14/01/2017
########################################################################################################################
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

if ( [ "`${HOME}/utilities/config/CheckConfigValue.sh ACTIVEFIREWALLS:1`" = "0" ] && [ "`${HOME}/utilities/config/CheckConfigValue.sh ACTIVEFIREWALLS:3`" = "0" ] )
then
	exit
fi

if ( [ "`/bin/cat /proc/uptime | /usr/bin/awk -F'.' '{print $1}'`" -lt "600" ] )
then
	exit
fi

#If the toolkit isn't fully installed, we don't want to do anything, so exit
if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh INSTALLED_SUCCESSFULLY`" = "" ] )
then
	exit
fi

firewall=""
if ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "FIREWALL" | /usr/bin/awk -F':' '{print $2}'`" = "ufw" ] )
then
	firewall="ufw"
elif ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "FIREWALL" | /usr/bin/awk -F':' '{print $2}'`" = "iptables" ] )
then
	firewall="iptables"
fi

if ( [ "${firewall}" = "ufw" ] )
then
	if ( [ "`/usr/sbin/ufw status | /bin/grep inactive`" != "" ] )
	then
		${HOME}/providerscripts/email/SendEmail.sh "FIREWALL (ufw) INACTIVE" "Just so you know, your firewall is inactive on machine `${HOME}/utilities/processing/GetPublicIP.sh`. The machine may still be initialsing after a reboot, which can take some minutes, but if these messages continue indefinitely, then you need to look into why the firewall is inactive." "ERROR"
		/bin/rm ${HOME}/runtime/FIREWALL-ACTIVE
	fi
elif ( [ "${firewall}" = "iptables" ] )
then
	if ( [ "`${HOME}/utilities/processing/RunServiceCommand.sh netfilter-persistent status | /bin/grep Loaded | /bin/grep enabled`" = "" ] )
	then
		if ( [ "`${HOME}/utilities/processing/RunServiceCommand.sh netfilter-persistent status | /bin/grep active`" = "" ] || [ "`/usr/sbin/iptables --list-rules | /bin/grep '\-P INPUT DROP'`" = "" ] )
		then
			${HOME}/providerscripts/email/SendEmail.sh "FIREWALL (iptables) INACTIVE" "Just so you know, your firewall is inactive on machine `${HOME}/utilities/processing/GetPublicIP.sh`. The machine may still be initialsing after a reboot, which can take some minutes, but if these messages continue indefinitely, then you need to look into why the firewall is inactive." "ERROR"
			/bin/rm ${HOME}/runtime/FIREWALL-ACTIVE
		fi
	fi
fi
