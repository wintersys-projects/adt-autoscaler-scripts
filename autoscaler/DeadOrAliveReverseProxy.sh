

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
                fi
                probecount="`/usr/bin/expr ${probecount} + 1`"
        done

        if ( [ "${status}" = "down" ] )
        then
                /bin/echo "${0} `/bin/date`: ReverseProxy ${ip} was found to be offline because it couldn't be contacted using curl" 
                ${HOME}/autoscaler/RemoveIPFromDNS.sh ${dnsip}        
        fi
}

CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"

ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "rp-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

for ip in ${ips}
do
  probe_by_curl
done
