#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description: This script will monitor for SSH connections from unknown IPs and send
# an email if there are any connections from unknown IP addresses. 
#######################################################################################
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
########################################################################################
########################################################################################
#set -x

HOME="`/bin/cat /home/homedir.dat`"

if ( [ "`${HOME}/providerscripts/datastore/config/toolkit/ListFromConfigDatastore.sh INSTALLED_SUCCESSFULLY`" = "" ] )
then
        exit
fi

ssh_client_ips="`/usr/bin/pinky | /usr/bin/awk '{print $NF}' | /usr/bin/tail -n +2`"

if ( [ ! -d ${HOME}/runtime/ssh-audit ] )
then
        /bin/mkdir -p ${HOME}/runtime/ssh-audit
fi

/bin/touch ${HOME}/runtime/ssh-audit/audit_trail

for ssh_client_ip in ${ssh_client_ips}
do
        if ( [ "`/bin/grep ${ssh_client_ip} ${HOME}/runtime/ssh-audit/audit_trail`" = "" ] )
        then
                /bin/echo "SSH connection first initiated at `/usr/bin/date` from IP address ${ssh_client_ip}" > ${HOME}/runtime/ssh-audit/audit_trail
                ${HOME}/providerscripts/email/SendEmail.sh "SSH CONNECTION FROM A NEW IP ADDRESS" "There has been a new connection from an unknown IP ${ssh_client_ip} to machine `/usr/bin/hostname`" "ERROR"
        fi
done
