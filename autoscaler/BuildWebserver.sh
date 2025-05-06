#!/bin/sh
###################################################################################################
# Description: This is where we build out a new webserver machine in response to a scaling event
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

buildno="${1}" #This script is passed a buildno as a parameter meaning is this "build 1" or "build 2" or "build n" of a multi webserver build cycle
trap "cleanup ${buildno}" TERM
start=`/bin/date +%s`

SIZE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'WSSERVERTYPE'`"
REGION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'REGION'`"
ALGORITHM="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ALGORITHM'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
SERVER_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"
SSH_PORT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SSHPORT'`"
OPTIONS=" -o ConnectTimeout=10 -o ConnectionAttempts=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
BUILD_KEY="${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"

SUDO=" DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

#Setup the webserver name taking into account which autoscaler it belongs to embedded in its name if this is a multi autoscaler deployment
rnd="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
rnd="${rnd}-`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-4`"
server_type="ws-${REGION}-${BUILD_IDENTIFIER}"
autoscalerip="`${HOME}/providerscripts/utilities/processing/GetPublicIP.sh`"
autoscaler_name="`${HOME}/providerscripts/server/GetServerName.sh ${autoscalerip} ${CLOUDHOST}`"
autoscaler_no="`/bin/echo ${autoscaler_name} | /usr/bin/awk -F'-' '{print $2}'`"
webserver_name="ws-${REGION}-${BUILD_IDENTIFIER}-${autoscaler_no}-${rnd}"
server_instance_name="`/bin/echo ${webserver_name} | /bin/sed 's/-$//g'`"

#Check there is a directory for logging
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

#Make the cloud-init script for building the webserver live and primed
/bin/echo "Initialising Cloud Init for webserver ${webserver_name}"
${HOME}/autoscaler/InitialiseCloudInit.sh

#Place a marker file which says that this machine is initially provisioning onto the file system
/bin/touch ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock

#Actually create the webserver passing in the name we have set for it as well as what machine type/size it should be
${HOME}/providerscripts/server/CreateServer.sh "${SIZE}" "${server_instance_name}"

#Try a few times if something is unsuccessful, generally, it never should be
count="0"
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

/bin/echo "${0} `/bin/date`: Interrogating for webserver instance being available....if this goes on forever there is a problem"

while ( [ "`${HOME}/providerscripts/server/IsInstanceRunning.sh "${server_instance_name}" ${CLOUDHOST}`" != "running" ] )
do
	/bin/sleep 5
done

count="1"
ip=""

/bin/echo "${0} `/bin/date`: Attempting to get ip address of webserver ${server_instance_name} " 

# There is a delay between the server being created and started and it "coming online". The way we can tell it is online is when
# It returns an ip address, so try, several times to retrieve the ip address of the server
# We are prepared to wait a total of 180 seconds for the machine to come online but it should generally be much quicker than that
while ( ( [ "${ip}" = "" ] || [ "${ip}" = "0.0.0.0" ] ) && [ "${count}" -lt "10" ]  )
do
	/bin/sleep 5
	/bin/echo "${0} `/bin/date`: Attempting to get ip address of webserver ${server_instance_name} " 
	ip="`${HOME}/providerscripts/server/GetServerIPAddresses.sh ${server_instance_name} ${CLOUDHOST}`"
	private_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${server_instance_name} ${CLOUDHOST}`"
	count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${ip}" = "" ] || [ "${private_ip}" = "" ] )
then
	#This should never happen, and I am not sure what to do about it if it does. If we don't have an ip address, how can
	#we destroy the machine? I simply exit, therefore.
	/bin/echo "${0} `/bin/date`: The webserver didn't come online, no ip address assigned or available, this could be an API availability issue" 
	/usr/bin/kill -TERM $$
else
	${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} webserverpublicips/${ip}
	${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${private_ip} webserverips/${private_ip}

	#We still need to worry that the build out of the machine might potentially stall for some unknown reason
	if ( [ ! -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip} ] )
	then
		/bin/touch ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip}
	fi 

	#If we are here then the machine isn't being initially provisioned any more so unset that worry
	if ( [ -f ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock ] )
	then
		/bin/rm ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock
	fi

	#Make a note that the machine with this IP address is currently being built. This will be removed once the machine is built
	#Until it is built we can tell that it is building by checking this in the datastore
	if ( [ ! -d ${HOME}/runtime/beingbuiltips/${buildno} ] )
	then 
		/bin/mkdir -p ${HOME}/runtime/beingbuiltips/${buildno}
	fi
	/bin/touch ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip}
	${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip} beingbuiltips/
        
	/bin/echo "${0} `/bin/date`: The webserver has been assigned public ip address ${ip} and private ip address ${private_ip}" 
	/bin/echo "${0} `/bin/date`: The webserver is now provisioned and I am about to start building it out and installing software"
fi

#We don't know how long the machine will take to configure and build but give it a good bit of time before we get impatient with it
count="1"
/bin/echo "${0} `/bin/date`: I am now going to attempt several times to see if the webserver ${server_instance_name} has completed its build process" 
/bin/echo "${0} `/bin/date`: This will take ten or twenty attempts at least"

while ( [ "${count}" -lt "71" ] && [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "/bin/ls /home/${SERVER_USER}/runtime/WEBSERVER_READY"`" = "" ] )
do
	/bin/sleep 5
	/bin/echo "${0} `/bin/date`: Checking if I consider the webserver with ip address (${private_ip}) to have completed its build process this is attempt ${count}" 
	count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${count}" = "71" ] )
then
	/bin/echo "${0} `/bin/date`: A webserver has failed to build after being given a good go at succeeding" 
 	/bin/echo "${0} `/bin/date`: webserver with ip address: ${ip} is being destroyed" 
	${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
	/usr/bin/kill -TERM $$
fi

#If your application needs any updates to the native firewall then they will be applied here
${HOME}/providerscripts/security/firewall/UpdateNativeFirewall.sh

#If the DBaaS firewall needs to be updated to allow the IP address of our new webserver, this will do it
if ( [ "`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DATABASEINSTALLATIONTYPE'`" = "DBaaS" ] )
then
	${HOME}/providerscripts/security/firewall/TightenDBaaSFirewall.sh
fi

application_language_installed=""
count="1"
while ( [ "${application_language_installed}" = "" ] )
do
	/bin/echo "${0} `/bin/date`: testing for application language installation on new webserver, this may take a few attempts this is attempt ${count}"
	application_language_installed="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "/bin/ls /home/${SERVER_USER}/runtime/installedsoftware/InstallApplicationLanguage.sh"`" 
	/bin/sleep 1
  	count="`/usr/bin/expr ${count} + 1`"
done

application_configuration_installed=""
count="1"
while ( [ "${application_configuration_installed}" = "" ] )
do
	/bin/echo "${0} `/bin/date`: testing for application configuration installation on new webserver, this may take a few attempts this is attempt ${count}"
	/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip}  "${SUDO} /home/${SERVER_USER}/providerscripts/application/configuration/SetApplicationConfiguration.sh"
	application_configuration_installed="`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "/bin/ls /home/${SERVER_USER}/runtime/INITIAL_CONFIG_SET"`" 
	/bin/sleep 1
 	count="`/usr/bin/expr ${count} + 1`"
done


#If we got through to here we simply want to check that the website is online using curl
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

if ( [ "${count}" != "71" ] | [ "${failedonlinecheck}" = "0" ] )
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

# This machine is no longer in a "being built" situation so cleanup
/bin/echo "${0} `/bin/date`: Deleting the 'beingbuilt' ip address ${private_ip} from the config datastore" 
${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh  beingbuiltips/${private_ip}
/bin/rm ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip}

#If we are here then we haven't stalled so we can clean that up also if we need to
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



