

SIZE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SIZE'`"
REGION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'REGION'`"
ALGORITHM="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ALGORITHM'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
SERVER_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
SSH_PORT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SSHPORT'`"
OPTIONS=" -o ConnectTimeout=10 -o ConnectionAttempts=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
BUILD_KEY="${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"


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

count=0

while ( [ "${count}" -lt "71" ] && [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "/bin/ls /home/${SERVER_USER}/runtime/WEBSERVER_READY"`" = "" ] )
do
        /bin/sleep 5
        count="`/usr/bin/expr ${count} + 1`"
done

failedonlinecheck="1"

#Do a check, as best we can to make sure that the website application is actually running correctly
count="0"
while ( [ "${count}" -lt "71" ] && [ "${failedonlinecheck}" != "0" ] )
do
        . ${HOME}/autoscaler/SelectHeadFile.sh

        if ( [ "${failedonlinecheck}" = "1" ] )
        then
                /bin/echo "${0} `/bin/date`: Peforming online checks for ip address ${ip}" 
                if ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/${headfile} | /bin/grep -E 'HTTP/2 200|HTTP/2 301|HTTP/2 302|HTTP/2 303|200 OK|302 Found|301 Moved Permanently'`" = "" ] )
                then
                        /bin/echo "/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/${headfile} | /bin/grep -E 'HTTP/2 200|HTTP/2 301|HTTP/2 302|HTTP/2 303|200 OK|302 Found|301 Moved Permanently"
                        /bin/echo "${0} `/bin/date`: Expecting ${private_ip} to be online, but can't reach it with curl yet...."
                        count="`/usr/bin/expr ${count} + 1`"
                        /bin/echo "${0} `/bin/date`: Doing webserver/application online check for ${ip} attempt ${count}" 
                        /bin/sleep 5
                else
                        /bin/echo "${0} `/bin/date`:  ${ip} is online that's wicked..." 
                        failedonlinecheck="0"
                fi
        fi
done

if ( [ "${count}" != "71" ] )
then
        ${HOME}/autoscaler/AddIPToDNS.sh ${ip}
else
fi

#Put in check that website is online and responsive


