#!/bin/sh
###############################################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : Set up the firewall for the autoscaler
################################################################################################################
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
#set -x #THIS MUST NOT BE SWITCHED ON DURING NORMAL USE, SCRIPT BREAK

if ( [ -f ${HOME}/runtime/FIREWALL-ACTIVE ] )
then
	exit
fi

if ( [ ! -d ${HOME}/logs/firewall ] )
then
	/bin/mkdir -p ${HOME}/logs/firewall
fi

#if ( [ ! -f ${HOME}/runtime/AUTOSCALER_READY ] )
#then
#   exit
#fi

#This stream manipulation is required for correct function, please do not remove or comment out
#exec >${HOME}/logs/firewall/FIREWALL_CONFIGURATION.log
#exec 2>&1

if ( [ "`${HOME}/providerscripts/utilities/config/CheckConfigValue.sh ACTIVEFIREWALLS:1`" = "0" ] && [ "`${HOME}/providerscripts/utilities/config/CheckConfigValue.sh ACTIVEFIREWALLS:3`" = "0" ] )
then
	exit
fi

firewall=""
if ( [ "`${HOME}/providerscripts/utilities/config/ExtractBuildStyleValues.sh "FIREWALL" | /usr/bin/awk -F':' '{print $NF}'`" = "ufw" ] )
then
        firewall="ufw"
elif ( [ "`${HOME}/providerscripts/utilities/config/ExtractBuildStyleValues.sh "FIREWALL" | /usr/bin/awk -F':' '{print $NF}'`" = "iptables" ] )
then
        firewall="iptables"
fi

if ( [ "${firewall}" = "ufw" ] && [ ! -f ${HOME}/runtime/FIREWALL-ACTIVE ] )
then
	/usr/sbin/ufw reset
  	/usr/sbin/ufw delete allow 22/tcp
 	/bin/sed -i "s/IPV6=yes/IPV6=no/g" /etc/default/ufw
        /usr/sbin/ufw logging off
	/usr/sbin/ufw reload
fi


SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
VPC_IP_RANGE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'VPCIPRANGE'`"

. ${HOME}/providerscripts/utilities/SetupInfrastructureIPs.sh

SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"

${HOME}/security/KnickersUp.sh

updated="0"

if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh BUILDMACHINEVPC:0`" = "1" ] )
then
	if ( [ "${firewall}" = "ufw" ] )
	then
		if ( [ "`/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw status | /bin/grep ${BUILD_CLIENT_IP} | /bin/grep ALLOW`" = "" ] )
		then
			/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw allow from ${BUILD_CLIENT_IP} to any port ${SSH_PORT}
			/bin/sleep 5
			updated="1"
		fi
        elif ( [ "${firewall}" = "iptables" ] )
        then
                if ( [ "`/usr/sbin/iptables --list-rules | /bin/grep ACCEPT | /bin/grep ${SSH_PORT} | /bin/grep ${BUILD_CLIENT_IP}`" = "" ] )
                then
                        /usr/sbin/iptables -I INPUT -s ${BUILD_CLIENT_IP} -p tcp --dport ${SSH_PORT} -j ACCEPT
                        /usr/sbin/iptables -I INPUT -s ${BUILD_CLIENT_IP} -p ICMP --icmp-type 8 -j ACCEPT
                        updated="1"
                fi
        fi
fi


if ( [ "${firewall}" = "ufw" ] )
then
	if ( [ "`/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw status | /bin/grep "${VPC_IP_RANGE}" | /bin/grep ALLOW`" = "" ] )
   	then
		/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw allow from ${VPC_IP_RANGE} to any port ${SSH_PORT}
		/bin/sleep 5
		updated="1"
	fi
elif ( [ "${firewall}" = "iptables" ] )
then
	if ( [ "`/usr/sbin/iptables --list-rules | /bin/grep ACCEPT | /bin/grep ${SSH_PORT} | /bin/grep ${VPC_IP_RANGE}`" = "" ] )
	then
		/usr/sbin/iptables -I INPUT -s ${VPC_IP_RANGE} -p tcp --dport ${SSH_PORT} -j ACCEPT
		/usr/sbin/iptables -I INPUT -s ${VPC_IP_RANGE} -p ICMP --icmp-type 8 -j ACCEPT
		updated="1"
	fi
fi












#if ( [ "${CLOUDHOST}" = "digitalocean" ] )
#then
#	if ( [ "${firewall}" = "ufw" ] )
#	then
#   		if ( [ "`/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw status | /bin/grep "10.116.0.0/24" | /bin/grep ALLOW`" = "" ] )
 #  		then
#			/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw allow from 10.116.0.0/24 to any port ${SSH_PORT}
#			/bin/sleep 5
#			updated="1"
#		fi
 #       elif ( [ "${firewall}" = "iptables" ] )
  #      then
  #              if ( [ "`/usr/sbin/iptables --list-rules | /bin/grep ACCEPT | /bin/grep ${SSH_PORT} | /bin/grep 10.116.0.0`" = "" ] )
  #              then
  #                      /usr/sbin/iptables -I INPUT -s 10.116.0.0/24 -p tcp --dport ${SSH_PORT} -j ACCEPT
  #                      /usr/sbin/iptables -I INPUT -s 10.116.0.0/24 -p ICMP --icmp-type 8 -j ACCEPT
  #                      updated="1"
  #              fi
  #      fi
#fi

#if ( [ "${CLOUDHOST}" = "exoscale" ] )
#then
#	if ( [ "${firewall}" = "ufw" ] )
#	then
 #  		if ( [ "`/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw status | /bin/grep "10.0.0.0/24" | /bin/grep ALLOW`" = "" ] )
  # 		then
#			/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw allow from 10.0.0.0/24 to any port ${SSH_PORT}
#			/bin/sleep 5
#			updated="1"
#		fi
 #       elif ( [ "${firewall}" = "iptables" ] )
  #      then
   #             if ( [ "`/usr/sbin/iptables --list-rules | /bin/grep ACCEPT | /bin/grep ${SSH_PORT} | /bin/grep 10.0.0.0`" = "" ] )
    #            then
     #                   /usr/sbin/iptables -I INPUT -s 10.0.0.0/24 -p tcp --dport ${SSH_PORT} -j ACCEPT
      #                  /usr/sbin/iptables -I INPUT -s 10.0.0.0/24 -p ICMP --icmp-type 8 -j ACCEPT
      #                  updated="1"
      #          fi
      #  fi
#fi

#if ( [ "${CLOUDHOST}" = "linode" ] )
#then
#	if ( [ "${firewall}" = "ufw" ] )
#	then
 #  		if ( [ "`/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw status | /bin/grep "10.0.1.0/24" | /bin/grep ALLOW`" = "" ] )
  # 		then
#			/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw allow from 10.0.1.0/24 to any port ${SSH_PORT}
#			/bin/sleep 5
#			updated="1"
#		fi
 #       elif ( [ "${firewall}" = "iptables" ] )
  #      then
   #             if ( [ "`/usr/sbin/iptables --list-rules | /bin/grep ACCEPT | /bin/grep ${SSH_PORT} | /bin/grep 10.0.1.0`" = "" ] )
    #            then
     #                   /usr/sbin/iptables -I INPUT -s 10.0.1.0/24 -p tcp --dport ${SSH_PORT} -j ACCEPT
      #                  /usr/sbin/iptables -I INPUT -s 10.0.1.0/24 -p ICMP --icmp-type 8 -j ACCEPT
       #                 updated="1"
    #            fi
  #      fi
#fi

#if ( [ "${CLOUDHOST}" = "vultr" ] )
#then
#	if ( [ "${firewall}" = "ufw" ] )
#	then
#		if ( [ "`/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw status | /bin/grep "192.168.0.0/16" | /bin/grep ALLOW`" = "" ] )
#		then
#			/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw allow from 192.168.0.0/16 to any port ${SSH_PORT}
#			/bin/sleep 5
#			updated="1"
#		fi
 #       elif ( [ "${firewall}" = "iptables" ] )
  #      then
   #             if ( [ "`/usr/sbin/iptables --list-rules | /bin/grep ACCEPT | /bin/grep ${SSH_PORT} | /bin/grep 192.168.0.0`" = "" ] )
    #            then
     #                   /usr/sbin/iptables -I INPUT -s 192.168.0.0/16 -p tcp --dport ${SSH_PORT} -j ACCEPT
      #                  /usr/sbin/iptables -I INPUT -s 192.168.0.0/16 -p ICMP --icmp-type 8 -j ACCEPT
      #                  updated="1"
      #          fi
      #  fi
#fi

if ( [ "${updated}" = "1" ] )
then
        if ( [ "${firewall}" = "ufw" ] )
        then
                /usr/sbin/ufw -f enable
                /usr/sbin/ufw reload
		${HOME}/providerscripts/utilities/RunServiceCommand.sh networking restart
        elif ( [ "${firewall}" = "iptables" ] )
        then
                ${HOME}/providerscripts/utilities/RunServiceCommand.sh netfilter-persistent save
        fi
fi

if ( [ "${firewall}" = "ufw" ] )
then
        if ( [ "`/usr/bin/ufw status | /bin/grep 'inactive'`" = "" ] )
        then
                /bin/touch ${HOME}/runtime/FIREWALL-ACTIVE
        fi
elif ( [ "${firewall}" = "iptables" ] )
then
        if ( [ "`${HOME}/providerscripts/utilities/RunServiceCommand.sh netfilter-persistent status | /bin/grep Loaded | /bin/grep enabled`" != "" ] )
        then
                if ( [ "`${HOME}/providerscripts/utilities/RunServiceCommand.sh netfilter-persistent status | /bin/grep active`" != "" ] )
                then
                        /bin/touch ${HOME}/runtime/FIREWALL-ACTIVE
                fi
        fi
fi
