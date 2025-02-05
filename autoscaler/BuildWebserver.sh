

SIZE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SIZE'`"
REGION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'REGION'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
SERVER_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"



rnd="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
rnd="${rnd}-`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-4`"
server_type="ws-${REGION}-${BUILD_IDENTIFIER}"
autoscalerip="`${HOME}/providerscripts/utilities/processing/GetPublicIP.sh`"
autoscaler_name="`${HOME}/providerscripts/server/GetServerName.sh ${autoscalerip} ${CLOUDHOST}`"
autoscaler_no="`/bin/echo ${autoscaler_name} | /usr/bin/awk -F'-' '{print $2}'`"
webserver_name="ws-${REGION}-${BUILD_IDENTIFIER}-${autoscaler_no}-${rnd}"
server_instance_name="`/bin/echo ${webserver_name} | /bin/sed 's/-$//g'`"


${HOME}/autoscaler/InitialiseCloudInit.sh

${HOME}/providerscripts/server/CreateServer.sh "${SIZE}" "${server_instance_name}"

while ( [ "$?" != "0" ] && [ "${count}" -lt "10" ] )
do
        /bin/sleep 5
        count="`/usr/bin/expr ${count} + 1`"
#       buildmethod="`${HOME}/providerscripts/server/CreateServer.sh "${ostype}" "${REGION}" "${SIZE}" "${server_instance_name}" "${KEY_ID}" ${CLOUDHOST} "${DEFAULT_USER}" ${CLOUDHOST_PASSWORD}`"
        ${HOME}/providerscripts/server/CreateServer.sh "${SIZE}" "${server_instance_name}"
done

if ( [ "${count}" = "10" ] )
then
        /bin/echo "${0} `/bin/date`: Failed to build webserver with name ${server_instance_name} - this is most likely an issue with your provider (${CLOUDHOST}) check their status page" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
        /usr/bin/kill -TERM $$
fi

count="0"
ip=""
# There is a delay between the server being created and started and it "coming online". The way we can tell it is online is when
# It returns an ip address, so try, several times to retrieve the ip address of the server
# We are prepared to wait a total of 300 seconds for the machine to come online
while ( [ "`/bin/echo ${ip} | /bin/grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`" = "" ] && [ "${count}" -lt "15" ] || [ "${ip}" = "0.0.0.0" ] )
do
        /bin/sleep 20
        ip="`${HOME}/providerscripts/server/GetServerIPAddresses.sh ${server_instance_name} ${CLOUDHOST}`"
        ${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} webserverpublicips/${ip}
        private_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${server_instance_name} ${CLOUDHOST}`"
        ${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${private_ip} webserverips/${private_ip}
        count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${ip}" = "" ] )
then
        #This should never happen, and I am not sure what to do about it if it does. If we don't have an ip address, how can
        #we destroy the machine? I simply exit, therefore.
        /bin/echo "${0} `/bin/date`: The weberver didn't come online" 
        exit
else
        /bin/echo "${0} `/bin/date`: The webserver has been assigned public ip address ${ip} and private ip address ${private_ip}" 
        /bin/echo "${0} `/bin/date`: The webserver is now provisioned and I am about to start building its software"
fi


