
#!/bin/sh
######################################################################################################
# Description: Purges a webserver IP from a Remote Proxy if the webserver has been shutdown according
# to its "DeadOrAlive" status
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



export HOME="`/bin/cat /home/homedir.dat`"
SSH_PORT="`${HOME}/utilities/config/ExtractConfigValue.sh 'SSHPORT'`"
CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
ALGORITHM="`${HOME}/utilities/config/ExtractConfigValue.sh 'ALGORITHM'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
BUILD_KEY="${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"
OPTIONS=" -o ConnectTimeout=10 -o ConnectionAttempts=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
SERVER_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"
SUDO=" DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

webserver_ip="${1}"

proxy_ip_addresses="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "rp-" "${CLOUDHOST}"`"

for ip_address in ${proxy_ip_addresses}
do
	/usr/bin/ssh -q -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${ip_address} "${SUDO} /home/${SERVER_USER}/providerscripts/webserver/configuration/reverseproxy/RemoveOldIPFromReverseProxyIPList.sh ${webserver_ip}"
done
