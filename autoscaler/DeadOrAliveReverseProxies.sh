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
