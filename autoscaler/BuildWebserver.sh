
cleanup() {     
        
        if ( [ -f ${HOME}/runtime/AUTOSCALINGMONITOR:${1} ] )
        then
                if ( [ "${2}" = "successfully" ] )
                then
                        /bin/echo "${0} `/bin/date`: Build no ${1} has been completed ${2}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
                else
                        /bin/echo "${0} `/bin/date`: Build no ${1} has been completed unsuccessfully - due to a raised trap condition" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
                fi
                /bin/rm ${HOME}/runtime/AUTOSCALINGMONITOR:${1}
        fi
 
}

#If we are trying to build a webserver before the toolkit has been fully installed, we don't want to do anything, so exit
if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLED_SUCCESSFULLY"`" = "0" ] )
then
        exit
fi

buildno="${1}"
trap "cleanup ${buildno}" TERM
start=`/bin/date +%s`

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

#Check there is a directory for logging
logdate="`/usr/bin/date | /usr/bin/awk '{print $1 $2 $3 $NF}'`"
logdir="scaling-events-`/usr/bin/date | /usr/bin/awk '{print $1,$2,$3}' | /bin/sed 's/ //g'`"

logdir="${logdir}/${webserver_name}"

if ( [ ! -d ${HOME}/logs/${logdir} ] )
then
        /bin/mkdir -p ${HOME}/logs/${logdir}
fi

#The log files for the server build are written here... 
log_file="webserver_out_`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${HOME}/logs/${logdir}/${log_file}
err_file="webserver_err_`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${HOME}/logs/${logdir}/${err_file}

/bin/echo "Initialising Cloud Init for webserver ${webserver_name}"
${HOME}/autoscaler/InitialiseCloudInit.sh

/bin/touch ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock

${HOME}/providerscripts/server/CreateServer.sh "${SIZE}" "${server_instance_name}"

while ( [ "$?" != "0" ] && [ "${count}" -lt "10" ] )
do
        /bin/sleep 5
        count="`/usr/bin/expr ${count} + 1`"
        ${HOME}/providerscripts/server/CreateServer.sh "${SIZE}" "${server_instance_name}"
done

if ( [ "${count}" = "10" ] )
then
        /bin/echo "${0} `/bin/date`: Failed to build webserver with name ${server_instance_name} - this is most likely an issue with your provider (${CLOUDHOST}) check their status page" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
        /usr/bin/kill -TERM $$
fi

count="1"
ip=""
/bin/echo "${0} `/bin/date`: I am now going to work on getting the IP adddresses of webserver ${server_instance_name}, this will take several attempts" 

# There is a delay between the server being created and started and it "coming online". The way we can tell it is online is when
# It returns an ip address, so try, several times to retrieve the ip address of the server
# We are prepared to wait a total of 300 seconds for the machine to come online
while ( ( [ "${ip}" = "" ] || [ "${ip}" = "0.0.0.0" ] ) && [ "${count}" -lt "30" ]  )
do
        /bin/sleep 5
        /bin/echo "${0} `/bin/date`: Attempting to get ip address of webserver ${server_instance_name} attempt ${count}" 
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
        /bin/echo "${0} `/bin/date`: The webserver didn't come online, no ip address assigned or available, this could be an API availability issue" 
        exit
else
        if ( [ ! -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip} ] )
        then
                /bin/touch ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip}
        fi 
        
        if ( [ -f ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock ] )
        then
                /bin/rm ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock
        fi
        
        if ( [ ! -d ${HOME}/runtime/beingbuiltips/${buildno} ] )
        then 
                /bin/mkdir -p ${HOME}/runtime/beingbuiltips/${buildno}
        fi

        if ( [ ! -d ${HOME}/runtime/beingbuiltpublicips/${buildno} ] )
        then
                /bin/mkdir -p ${HOME}/runtime/beingbuiltpublicips/${buildno}
        fi

        /bin/touch ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip}
        ${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip} beingbuiltips/
        
        /bin/echo "${0} `/bin/date`: The webserver has been assigned public ip address ${ip} and private ip address ${private_ip}" 
        /bin/echo "${0} `/bin/date`: The webserver is now provisioned and I am about to start building it out and installing software"
fi

count="1"
/bin/echo "${0} `/bin/date`: I am now going to attempt several times to see if the webserver ${server_instance_name} has completed its build process" 
/bin/echo "${0} `/bin/date`: This will take ten or twenty attempts at least"

while ( [ "${count}" -lt "71" ] && [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "/bin/ls /home/${SERVER_USER}/runtime/WEBSERVER_READY"`" = "" ] )
do
        /bin/sleep 5
        /bin/echo "${0} `/bin/date`: Checking if I consider the webserver with ip address (${private_ip}) to have completed its build process" 
        count="`/usr/bin/expr ${count} + 1`"
done

failedonlinecheck="1"
count="1"
headfile="`${HOME}/autoscaler/SelectHeadFile.sh`"
/bin/echo "${0} `/bin/date`: Have set the headfile for curl command to be ${headfile}" 
/bin/echo "${0} `/bin/date`: the full URL I am checking for is: https://${private_ip}:443/${headfile}"
/bin/echo "${0} `/bin/date`: I expect this to take several attempts before the website is considered fully online"

while ( [ "${count}" -lt "71" ] && [ "${failedonlinecheck}" != "0" ] )
do
        /bin/echo "${0} `/bin/date`: Peforming online checks using curl (attempt ${count}) for newly built webserver with ip address ${ip}" 

        if ( [ "${failedonlinecheck}" = "1" ] )
        then
                if ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/${headfile} | /bin/grep -E 'HTTP/2 200|HTTP/2 301|HTTP/2 302|HTTP/2 303|200 OK|302 Found|301 Moved Permanently'`" = "" ] )
                then
                        /bin/echo "${0} `/bin/date`: Expecting ${private_ip} to be online, but can't reach it with curl yet...."
                        /bin/sleep 5
                        count="`/usr/bin/expr ${count} + 1`"
                else
                        /bin/echo "${0} `/bin/date`: a new webserver with ip address:${ip} is online that's wicked..." 
                        failedonlinecheck="0"
                fi
        fi
done

if ( [ "${count}" != "71" ] || [ "${failedonlinecheck}" = "0" ] )
then
        ${HOME}/autoscaler/AddIPToDNS.sh ${ip}
elif ( [ "${failedonlinecheck}" = "1" ] )
then
        if ( [ -f ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock ] )
        then
                /bin/rm ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock
        fi
        
        /bin/echo "${0} `/bin/date`: webserver with ip address: ${ip} failed its online check" 
        /bin/echo "${0} `/bin/date`: webserver with ip address: ${ip} is being destroyed" 
        ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
fi

/bin/echo "${0} `/bin/date`: Deleting the 'beingbuilt' ip address ${private_ip} from the config datastore" 
${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh  beingbuiltips/${private_ip}
/bin/rm ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip}

/bin/echo "${0} `/bin/date`: This build hasn't stalled, so, removing file ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip}" 
if ( [ ! -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip} ] )
then
        /bin/rm ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip}
fi 

#Output how long the build took
end=`/bin/date +%s`
runtime="`/usr/bin/expr ${end} - ${start}`"
/bin/echo "${0} This script took `/bin/date -u -d @${runtime} +\"%T\"` to complete and completed at time: `/usr/bin/date`" 

trap "cleanup ${buildno} successfully" TERM

/usr/bin/kill -TERM $$



