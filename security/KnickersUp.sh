#!/bin/sh
#########################################################################################################################
# Description : This script sets the firewall so that it allowes outgoing connections but denies all incoming ones. 
# In other words, once this script is run, your knickers are up
# Author: Peter Winter
# Date : 17-09-2016
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

SERVER_USER_PASSWORD="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"

if ( [ ! -f ${HOME}/runtime/KNICKERS_ARE_UP ] )
then
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
		/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw default deny incoming
		/bin/sleep 10
		/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw default allow outgoing
		/bin/touch ${HOME}/runtime/KNICKERS_ARE_UP
	elif ( [ "${firewall}" = "iptables" ] )
	then
		#/usr/sbin/iptables -I INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
		#/usr/sbin/iptables -I INPUT -m state -p tcp --dport 443 --state ESTABLISHED -j ACCEPT
		#/usr/sbin/iptables -I INPUT -m state -p tcp --dport 1035 --state ESTABLISHED -j ACCEPT
		/usr/sbin/iptables -I INPUT -m state --state ESTABLISHED -j ACCEPT
		/usr/sbin/iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j DROP
		/usr/sbin/iptables -A INPUT -i lo -j ACCEPT
		/usr/sbin/iptables -A OUTPUT -o lo -j ACCEPT
		/usr/sbin/iptables -P INPUT DROP
		/usr/sbin/iptables -P FORWARD DROP
		/usr/sbin/iptables -P OUTPUT ACCEPT
		/usr/sbin/ip6tables -P INPUT DROP
		/usr/sbin/ip6tables -P FORWARD DROP
		/usr/sbin/ip6tables -P OUTPUT DROP
		/usr/sbin/netfilter-persistent save   		
		/bin/touch ${HOME}/runtime/KNICKERS_ARE_UP
	fi
fi

