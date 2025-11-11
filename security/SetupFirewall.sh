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
#set -x 

export HOME="`/bin/cat /home/homedir.dat`"
BUILDOS="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"

if ( [ "`/usr/bin/find ${HOME}/runtime/customfirewallports.dat -mmin -1 -print`" != "" ] )
then
        /bin/rm ${HOME}/runtime/FIREWALL-ACTIVE
fi

if ( [ -f ${HOME}/runtime/FIREWALL-ACTIVE ] )
then
	exit
fi

if ( [ ! -d ${HOME}/logs/firewall ] )
then
	/bin/mkdir -p ${HOME}/logs/firewall
fi

#This stream manipulation is required for correct function, please do not remove or comment out
#exec >${HOME}/logs/firewall/FIREWALL_CONFIGURATION.log
#exec 2>&1

if ( [ "`${HOME}/utilities/config/CheckConfigValue.sh ACTIVEFIREWALLS:1`" = "0" ] && [ "`${HOME}/utilities/config/CheckConfigValue.sh ACTIVEFIREWALLS:3`" = "0" ] )
then
	exit
fi

firewall=""
if ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "FIREWALL" | /usr/bin/awk -F':' '{print $NF}'`" = "ufw" ] )
then
	firewall="ufw"
elif ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "FIREWALL" | /usr/bin/awk -F':' '{print $NF}'`" = "iptables" ] )
then
	firewall="iptables"
fi

if ( [ ! -f ${HOME}/runtime/FIREWALL-INITIALISED ] )
then
        if ( [ "${firewall}" = "ufw" ] && [ ! -f ${HOME}/runtime/FIREWALL-ACTIVE ] )
        then
                /usr/bin/yes | /usr/sbin/ufw reset
                /usr/sbin/ufw delete allow 22/tcp
                /bin/sed -i "s/IPV6=yes/IPV6=no/g" /etc/default/ufw

                /usr/sbin/ufw logging off
                VPC_IP_RANGE="`${HOME}/utilities/config/ExtractConfigValue.sh 'VPCIPRANGE'`"
                ip_addresses="`/usr/sbin/ufw status | /bin/grep "^443" | /bin/grep -v "${VPC_IP_RANGE}" | /bin/grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`"

                for ip_address in ${ip_addresses}
                do
                        /usr/sbin/ufw delete allow from ${ip_address}
                done

                /usr/sbin/ufw reload
                /bin/touch ${HOME}/runtime/FIREWALL-INITIALISED 
        elif ( [ "${firewall}" = "iptables" ] && [ ! -f ${HOME}/runtime/FIREWALL-INITIALISED ] )
        then
                /usr/sbin/iptables -P INPUT DROP
                /usr/sbin/iptables -P FORWARD DROP
                /usr/sbin/iptables -P OUTPUT ACCEPT
                /usr/sbin/iptables -A INPUT -i lo -j ACCEPT
                /usr/sbin/iptables -A OUTPUT -o lo -j ACCEPT

                /usr/sbin/iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                /usr/sbin/iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
                /usr/sbin/iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
                /usr/sbin/iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

                /usr/sbin/ip6tables -P INPUT DROP
                /usr/sbin/ip6tables -P FORWARD DROP
                /usr/sbin/ip6tables -P OUTPUT ACCEPT
                /usr/sbin/ip6tables -A INPUT -i lo -j ACCEPT
                /usr/sbin/ip6tables -A OUTPUT -o lo -j ACCEPT

                VPC_IP_RANGE="`${HOME}/utilities/config/ExtractConfigValue.sh 'VPCIPRANGE'`"
                ip_addresses="`/usr/sbin/iptables -L INPUT -n | /bin/grep "443$" | /bin/grep -v "${VPC_IP_RANGE}" | /bin/grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`"
                for ip_address in ${ip_addresses}
                do
                        /usr/sbin/iptables -D INPUT -s ${ip_address} -p tcp --dport 443 -j ACCEPT
                done

                /bin/touch ${HOME}/runtime/FIREWALL-INITIALISED 
        fi
fi

SSH_PORT="`${HOME}/utilities/config/ExtractConfigValue.sh 'SSHPORT'`"
CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
VPC_IP_RANGE="`${HOME}/utilities/config/ExtractConfigValue.sh 'VPCIPRANGE'`"
BUILD_MACHINE_IP="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDMACHINEIP'`"
SERVER_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"

${HOME}/security/KnickersUp.sh

updated_ssh="0"
if ( [ "`/bin/grep ${VPC_IP_RANGE} /etc/ssh/sshd_config`" = "" ] )
then
	/bin/echo "AllowUsers ${SERVER_USER}@${VPC_IP_RANGE}" >> /etc/ssh/sshd_config
	updated_ssh="1"
fi

if ( [ "${updated_ssh}" = "1" ] )
then
	${HOME}/utilities/processing/RunServiceCommand.sh "ssh" restart
fi

updated="0"

if ( [ "`${HOME}/utilities/config/CheckConfigValue.sh BUILDMACHINEVPC:0`" = "1" ] )
then

	updated_ssh="0"
	if ( [ "`/bin/grep ${BUILD_MACHINE_IP} /etc/ssh/sshd_config`" = "" ] )
	then
		/bin/echo "AllowUsers ${SERVER_USER}@${BUILD_MACHINE_IP}" >> /etc/ssh/sshd_config
		updated_ssh="1"
	fi

	if ( [ "${updated_ssh}" = "1" ] )
 	then
 		${HOME}/utilities/processing/RunServiceCommand.sh "ssh" restart
   	fi
	
	if ( [ "${firewall}" = "ufw" ] )
	then
		if ( [ "`/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw status | /bin/grep ${BUILD_MACHINE_IP} | /bin/grep ALLOW`" = "" ] )
		then
			/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw allow from ${BUILD_MACHINE_IP} to any port ${SSH_PORT}
			/bin/sleep 5
			updated="1"
		fi
	elif ( [ "${firewall}" = "iptables" ] )
	then
		if ( [ "`/usr/sbin/iptables --list-rules | /bin/grep ACCEPT | /bin/grep ${SSH_PORT} | /bin/grep ${BUILD_MACHINE_IP}`" = "" ] )
		then
			/usr/sbin/iptables -A INPUT -s ${BUILD_MACHINE_IP} -p tcp --dport ${SSH_PORT} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
            /usr/sbin/iptables -A OUTPUT -s ${BUILD_MACHINE_IP} -p tcp --sport ${SSH_PORT} -m conntrack --ctstate ESTABLISHED -j ACCEPT
            /usr/sbin/iptables -A INPUT -s ${BUILD_MACHINE_IP} -p ICMP --icmp-type 8 -j ACCEPT
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
        /usr/sbin/iptables -A INPUT -s ${VPC_IP_RANGE} -p tcp --dport ${SSH_PORT} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        /usr/sbin/iptables -A INPUT -s ${VPC_IP_RANGE} -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        /usr/sbin/iptables -A INPUT -s ${VPC_IP_RANGE} -p ICMP --icmp-type 8 -j ACCEPT
		updated="1"
	fi
fi

custom_ports="`/bin/grep "^AUTOSCALERCUSTOMPORTS" ${HOME}/runtime/customfirewallports.dat | /usr/bin/awk -F':' '{print $NF}'`"

for custom_port_token in ${custom_ports}
do
        delete="no"
        if ( [ "`/bin/echo ${custom_port_token} | /bin/grep 'ipv4'`" != "" ] )
        then
                port="`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $1}'`"
                ip_address="`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $3}'`"
                if ( [ "`/bin/echo ${custom_port_token} | /usr/bin/awk -F'|' '{print $4}'`" = "DELETE" ] )
                then
                        delete="yes"
                fi
        fi

        if ( [ "${firewall}" = "ufw" ] )
        then
                if ( [ "`/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw status | /bin/grep ${port} | /bin/grep ALLOW`" = "" ] )
                then
                        /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/ufw allow from ${ip_address} to any port ${port}
                        updated="1"
                fi
        elif ( [ "${firewall}" = "iptables" ] )
        then
                if ( [ "`/usr/sbin/iptables --list-rules | /bin/grep ACCEPT | /bin/grep ${port}`" = "" ] && [ "${delete}" != "yes" ] )
                then
                        /usr/sbin/iptables -A INPUT -s ${ip_address} -p tcp --dport ${port} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
                        /usr/sbin/iptables -A OUTPUT -s ${ip_address} -p tcp --sport ${port} -m conntrack --ctstate ESTABLISHED -j ACCEPT
                        updated="1"
                else
                        if ( [ "`/usr/sbin/iptables --list-rules | /bin/grep ACCEPT | /bin/grep ${port}`" != "" ] && [ "${delete}" = "yes" ] )
                        then
                                /usr/sbin/iptables -D INPUT -s ${ip_address} -p tcp --dport ${port} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
                                /usr/sbin/iptables -D OUTPUT -s ${ip_address} -p tcp --sport ${port} -m conntrack --ctstate ESTABLISHED -j ACCEPT
                                updated="1"
                        fi

                fi
        fi
done

if ( [ "${updated}" = "1" ] )
then
	if ( [ "${firewall}" = "ufw" ] )
	then
		/usr/sbin/ufw -f enable
		/usr/sbin/ufw reload

	elif ( [ "${firewall}" = "iptables" ] )
	then
        /usr/sbin/iptables-save > /etc/iptables/rules.v4
        /usr/sbin/ip6tables-save > /etc/iptables/rules.v6
	fi

	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		${HOME}/utilities/processing/RunServiceCommand.sh systemd-networkd.service restart
	elif ( [ "${BUILDOS}" = "debian" ] )
	then
		${HOME}/utilities/processing/RunServiceCommand.sh networking restart
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
	if ( [ "`${HOME}/utilities/processing/RunServiceCommand.sh netfilter-persistent status | /bin/grep Loaded | /bin/grep enabled`" != "" ] )
	then
		if ( [ "`${HOME}/utilities/processing/RunServiceCommand.sh netfilter-persistent status | /bin/grep active`" != "" ] )
		then
			/bin/touch ${HOME}/runtime/FIREWALL-ACTIVE
		fi
	fi
fi
