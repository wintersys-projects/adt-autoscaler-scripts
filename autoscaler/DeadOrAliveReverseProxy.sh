

CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"

ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "rp-${REGION}-${BUILD_IDENTIFIER}" ${CLOUDHOST}`"

for ip in ${ips}
do

done
