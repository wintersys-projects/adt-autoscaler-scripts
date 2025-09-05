#!/bin/sh
###################################################################################################
# Description: This will probe remote proxy machines and let us know if they are up or down
# Author: Peter Winter
# Date: 12/01/2017
######################################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Fou.logion, either version 3 of the License, or
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

#This function is called whenever the script exits or completes to clean up the monitoring that we have set up

probe_by_curl()
{
        probecount="0"
        status="down"
        file="`${HOME}/autoscaler/SelectHeadFile.sh`"
        while ( [ "${probecount}" -le "3" ] && [ "${status}" = "down" ] )
        do
                if ( [ "`/usr/bin/curl -s -m 20 --insecure -I "https://${ip}:443/${file}" 2>&1 | /bin/grep "HTTP" | /bin/grep -E "200|301|302|303"`" != "" ] ) 
                then
                        status="up"
                else
                        status="down"
                        /bin/sleep 10
                fi
                probecount="`/usr/bin/expr ${probecount} + 1`"
        done

        if ( [ "${status}" = "down" ] )
        then
                /bin/echo "${0} `/bin/date`: ReverseProxy ${ip} was found to be offline because it couldn't be contacted using curl" 
                ip="`${HOME}/providerscripts/server/GetServerPublicIPAddressByIP.sh ${ip} ${CLOUDHOST}`"
                ${HOME}/autoscaler/RemoveIPFromDNS.sh ${ip}     
                ${HOME}/providerscripts/email/SendEmail.sh "IP ADDRESS REMOVED FROM DNS" "IP address of remote proxy IP address (${ip}) removed from DNS system due to an error" "ERROR"
        else
                ips="`${HOME}/autoscaler/GetDNSIPs.sh`"
                if ( [ "`/bin/echo ${ips} | /bin/grep ${ip}`" = "" ] )
                then
                        ${HOME}/autoscaler/AddIPToDNS.sh ${ip}
                fi
        fi
}

CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"

ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "rp-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

for ip in ${ips}
do
        probe_by_curl
done

