#!/bin/sh
############################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : This script will build a webserver from scratch in response to an autoscaling event
# It depends on the provider scripts and will build according to the provider it is configured for
# If we are configured to use snapshots, then the build will be completed using a snapshot (which
# must exist) otherwise, we perform a vanilla build of our webserver from scratch. 
# With each of these three methods, there are advantages and disadvantages and it just depends
# what suits you
##############################################################################################
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
#############################################################################################
#############################################################################################
set -x

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
chosen_webserver_ip="${2}"
trap "cleanup ${buildno}" TERM
start=`/bin/date +%s`

SERVER_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"

if ( [ -f ${HOME}/.ssh/webserver_configuration_settings.dat ] && [ ! -f ${HOME}/runtime/webserver_configuration_settings.dat ] )
then
        /bin/cp ${HOME}/.ssh/webserver_configuration_settings.dat ${HOME}/runtime/webserver_configuration_settings.dat
        /bin/chown root:${SERVER_USER} ${HOME}/runtime/webserver_configuration_settings.dat
        /bin/chmod 640 ${HOME}/runtime/webserver_configuration_settings.dat
        /bin/mv ${HOME}/.ssh/webserver_configuration_settings.dat ${HOME}/.ssh/webserver_configuration_settings.dat.original
fi

ASIP="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ASIP'`"
if ( [ "${ASIP}" = "" ] )
then 
        if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh autoscalerip/* | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`" = "1" ] )
        then
                ASIP="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh autoscalerip/*`"
        else
                ASIP="multiple"
        fi
fi

AS_PUBLIC_IP="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ASPUBLICIP'`"
if ( [ "${AS_PUBLIC_IP}" = "" ] )
then
        if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh autoscalerpublicip/* | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`" = "1" ] )
        then
                AS_PUBLIC_IP="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh autoscalerpublicip/*`"
        else
                AS_PUBLIC_IP="multiple"
        fi
fi

SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"
DEFAULT_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DEFAULTUSER'`"

if ( [ "${DEFAULT_USER}" = "root" ] )
then
        SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
else
        SUDO="DEBIAN_FRONTEND=noninteractive /usr/bin/sudo -S -E "
fi
CUSTOM_USER_SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
OPTIONS=" -o ConnectTimeout=10 -o ConnectionAttempts=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
OPTIONS1=" -o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "

#Check there is a directory for logging
logdate="`/usr/bin/date | /usr/bin/awk '{print $1 $2 $3 $NF}'`"
logdir="scaling-events-`/usr/bin/date | /usr/bin/awk '{print $1,$2,$3}' | /bin/sed 's/ //g'`"

if ( [ ! -d ${HOME}/logs/${logdir} ] )
then
        /bin/mkdir -p ${HOME}/logs/${logdir}
fi

if ( [ ! -d ${HOME}/logs/${logdir} ] )
then
        /bin/mkdir -p ${HOME}/logs/${logdir}
fi

if ( [ ! -d ${HOME}/runtime/beingbuiltips ] )
then
        /bin/mkdir -p ${HOME}/runtime/beingbuiltips
fi

if ( [ ! -d ${HOME}/runtime/beingbuiltpublicips ] )
then
        /bin/mkdir -p ${HOME}/runtime/beingbuiltpublicips
fi

ip=""

#Pull the configuration into memory for easy access
KEY_ID="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'KEYID'`"
BUILD_CHOICE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDCHOICE'`"
BUILDOS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
REGION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'REGION'`"
SIZE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SIZE'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
ALGORITHM="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ALGORITHM'`"
WEBSITE_URL="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'WEBSITEURL'`"
DNS_CHOICE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DNSCHOICE'`"
DNS_SECURITY_KEY="`${HOME}/providerscripts/utilities/config/ExtractConfigValues.sh 'DNSSECURITYKEY' stripped | /bin/sed 's/ /:/g'`"
DNS_USERNAME="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DNSUSERNAME'`"
GIT_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'GITUSER'`"
GIT_EMAIL_ADDRESS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'GITEMAILADDRESS'`"
INFRASTRUCTURE_REPOSITORY_PROVIDER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPROVIDER'`"
INFRASTRUCTURE_REPOSITORY_USERNAME="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYUSERNAME'`"
INFRASTRUCTURE_REPOSITORY_PASSWORD="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPASSWORD'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
APPLICATION_REPOSITORY_PROVIDER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONREPOSITORYPROVIDER'`"
APPLICATION_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONREPOSITORYOWNER'`"
APPLICATION_REPOSITORY_USERNAME="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONREPOSITORYUSERNAME'`"
APPLICATION_REPOSITORY_PASSWORD="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONREPOSITORYPASSWORD'`"
APPLICATION_REPOSITORY_TOKEN="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONREPOSITORYTOKEN'`"
CLOUDHOST_USERNAME="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'CLOUDHOSTUSERNAME'`"
CLOUDHOST_PASSWORD="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'CLOUDHOSTPASSWORD'`"
BUILD_ARCHIVE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDARCHIVECHOICE'`"
DATASTORE_CHOICE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DATASTORECHOICE'`"
WEBSERVER_CHOICE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'WEBSERVERCHOICE'`"
APPLICATION_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONIDENTIFIER'`"
APPLICATION_LANGUAGE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONLANGUAGE'`"
SOURCECODE_REPOSITORY="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONBASELINESOURCECODEREPOSITORY'`"
SSH_PORT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SSHPORT'`"
DB_PORT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DBPORT'`"
BUILD_CLIENT_IP="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDCLIENTIP'`"
PERSIST_ASSETS_TO_CLOUD="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'PERSISTASSETSTOCLOUD'`"
DIRECTORIES_TO_MOUNT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DIRECTORIESTOMOUNT'`"


if ( [ ! -f ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ] )
then
        original_build_identifier="`/bin/echo ${BUILD_IDENTIFIER} | /bin/sed 's/s-//g'`"
        /bin/cp ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${original_build_identifier} ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}
        /bin/cp ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${original_build_identifier}.pub ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub
fi

BUILD_KEY="${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"

DBIP="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DBIP'`"

if ( [ "${DBIP}" = "" ] )
then
         DBIP="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh \"databaseip/*\"`"
fi

DB_PUBLIC_IP="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DBPUBLICIP'`"

if ( [ "${DB_PUBLIC_IP}" = "" ] )
then
         DB_PUBLIC_IP="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh \"databasepublicip/*\"`"
fi

ASIPS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ASIPS'`"

if ( [ "${ASIPS}" = "" ] )
then

        for ipaddress in "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh \"autoscalerpublicip/*\"`"
        do
                ASIPS=${ASIPS}:${ipaddress}
        done

        ASIPS="`/bin/echo ${ASIPS} | /bin/sed 's/^://g'`"
fi

ASIP_PRIVATES="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ASIP_PRIVATES'`"

if ( [ "${ASIP_PRIVATES}" = "" ] )
then
        for ipaddress in "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh \"autoscalerip/*\"`"
        do
                ASIP_PRIVATES=${ASIP_PRIVATES}:${ipaddress}
        done
        ASIP_PRIVATES="`/bin/echo ${ASIP_PRIVATES} | /bin/sed 's/^://g'`"
fi

z="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
name="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $1}'`"

# Set up the webservers properties, like its name and so on.
rnd="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
rnd="${rnd}-`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-4`"
server_type="ws-${REGION}-${BUILD_IDENTIFIER}"
autoscalerip="`${HOME}/providerscripts/utilities/processing/GetPublicIP.sh`"
autoscaler_name="`${HOME}/providerscripts/server/GetServerName.sh ${autoscalerip} ${CLOUDHOST}`"
autoscaler_no="`/bin/echo ${autoscaler_name} | /usr/bin/awk -F'-' '{print $2}'`"
webserver_name="ws-${REGION}-${BUILD_IDENTIFIER}-${autoscaler_no}-${rnd}"
server_instance_name="`/bin/echo ${webserver_name} | /bin/sed 's/-$//g'`"

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


#What type of machine are we building - this will determine the size and so on with the cloudhost
#server_type_id="`${HOME}/providerscripts/server/GetServerTypeID.sh ${SIZE} "${server_type}" ${CLOUDHOST}`"

#Hell, what operating system are we running
ostype="`${HOME}/providerscripts/cloudhost/GetOperatingSystemVersion.sh ${SIZE} ${CLOUDHOST}`"

#Attempt to create a vanilla machine on which to build our webserver
#The build method tells us if we are using a snapshot or not

/bin/touch ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock

count="0"
while ( [ "`/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${chosen_webserver_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/status/IsWebserverFullyBuilt.sh"`" = "0" ] && [ "${count}" -lt "5" ] )
do
	active_webserver_ips="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh webserverips/*` "
	no_active_webservers="`/bin/echo ${active_webserver_ips} | /usr/bin/wc -w`"
	no_chosen_one="`/usr/bin/shuf -i 1-${no_active_webservers} -n 1`"
   	chosen_webserver_ip="`/bin/echo "${active_webserver_ips}" | /usr/bin/cut -d " " -f ${no_chosen_one}`"
    	/bin/sleep 5
     	count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${count}" -eq "5" ] )
then
        ${HOME}/providerscripts/email/SendEmail.sh "COULDN'T FIND A FULLY BUILT WEBSERVER TO SYNC FROM" "Couldn't find a fully build webserver to sync with after 5 attempts" "ERROR"
	/bin/echo "${0} `/bin/date`: Couldn't find a fully build webserver to sync with after 5 attempts" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	exit
fi

/bin/echo "${0} `/bin/date`: Spinning up a new webserver with name ${webserver_name}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

count="0"
#buildmethod="`${HOME}/providerscripts/server/CreateServer.sh "${ostype}" "${REGION}" "${SIZE}" "${server_instance_name}" "${KEY_ID}" ${CLOUDHOST} "${DEFAULT_USER}" ${CLOUDHOST_PASSWORD}`"
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

# There is a delay between the server being created and started and it "coming online". The way we can tell it is online is when
# It returns an ip address, so try, several times to retrieve the ip address of the server
# We are prepared to wait a total of 300 seconds for the machine to come online
while ( [ "`/bin/echo ${ip} | /bin/grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`" = "" ] && [ "${count}" -lt "15" ] || [ "${ip}" = "0.0.0.0" ] )
do
        /bin/sleep 20
        ip="`${HOME}/providerscripts/server/GetServerIPAddresses.sh ${server_instance_name} ${CLOUDHOST}`"
        WS_PUBLIC_IP="${ip}"
        ${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} webserverpublicips/${ip}
        private_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${server_instance_name} ${CLOUDHOST}`"
        WS_PRIVATE_IP="${private_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${private_ip} webserverips/${private_ip}
        count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${ip}" = "" ] )
then
        #This should never happen, and I am not sure what to do about it if it does. If we don't have an ip address, how can
        #we destroy the machine? I simply exit, therefore.
        /bin/echo "${0} `/bin/date`: The weberver didn't come online" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
        /usr/bin/kill -TERM $$
else
        /bin/echo "${0} `/bin/date`: The webserver has been assigned public ip address ${ip} and private ip address ${private_ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
        /bin/echo "${0} `/bin/date`: The webserver is now provisioned and I am about to start building its software" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
fi

#/bin/echo "${0} `/bin/date`: Ensuring that the server is attached to the VPC (if one is being used)" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
#${HOME}/providerscripts/server/EnsureServerAttachToVPC.sh "${CLOUDHOST}" "${webserver_name}" "${private_ip}"

if ( [ ! -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip} ] )
then
        /bin/touch ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip}
fi

#We add our IP address to a list of machines in the 'being built' stage. We can check this flag elsewhere when we want to
#distinguish between ip address of webservers which have been built and are still being built.
#The autoscaler monitors for this when it is looking for slow builds. The being built part of things is cleared out when
#we reach the end of the build process so if this persists for an excessive amount of time, the "slow builds" script on the
#autoscaler knows that something is hanging or has gone wrong with the build and it clears things up.

if ( [ ! -d ${HOME}/runtime/beingbuiltips/${buildno} ] )
then
        /bin/mkdir -p ${HOME}/runtime/beingbuiltips/${buildno}
fi

if ( [ ! -d ${HOME}/runtime/beingbuiltpublicips/${buildno} ] )
then
        /bin/mkdir -p ${HOME}/runtime/beingbuiltpublicips/${buildno}
fi

/bin/touch ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip}
/bin/touch ${HOME}/runtime/beingbuiltpublicips/${buildno}/${ip}

if ( [ -f ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock ] )
then
         /bin/rm ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock
fi

${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip} beingbuiltips/

/bin/echo "${0} `/bin/date`: If you are using DBaaS then the DBaaS 'firewall' is being initialised" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

. ${HOME}/providerscripts/security/firewall/TightenDBaaSFirewall.sh

snapshot_build="0"
#If we are here, then we are not building from a snapshot
webserver_name="${server_instance_name}"
#Test to see if our server can be accessed using our build key
count="0"
connected="0"
sshpass="0"

while ( [ "${count}" -lt "20" ] && [ "${connected}" = "0" ] )
do
        count="`/usr/bin/expr ${count} + 1`"
        /usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS1} -o "PasswordAuthentication no" ${DEFAULT_USER}@${private_ip} "/bin/touch /tmp/alive.$$"

        if ( [ "`/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS1} ${DEFAULT_USER}@${private_ip} "/bin/ls /tmp/alive.$$"`" != "" ] )
        then
                connected="1"
        fi

        if ( [ "${connected}" = "0" ] && [ "${CLOUDHOST_PASSWORD}" != "" ] )
        then
                if ( [ ! -f /usr/bin/sshpass ] )
                then
                        if ( [ "${BUILDOS}" = "ubuntu" ] || [ "${BUILDOS}" = "debian" ] )
                        then
                                DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq install sshpass
                        fi
                fi

                /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${DEFAULT_USER}@${private_ip} "/bin/touch /tmp/alive1.$$"

                if ( [ "$?" = "0" ] )
                then
                        /bin/echo "${0} `/bin/date`: Doing an sshpass style initiation of our new webserver (${server_instance_name}) with ip address ${private_ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
                        sshpass="1"
                        connected="1"
                fi

        fi
        if ( [ "${connected}" = "0" ] )
        then
                /bin/sleep 10
        fi
done

if ( [ "${connected}" = "0" ] && [ "${count}" = "20" ] )
then
        ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO BUILD/PROVISION A WEBSERVER" "For some reason, autoscaler provisioned webserver with ip ${ip} failed to provision. At the very least, the clouhost_password wasn't set when it was needed" "ERROR"
        /bin/echo "${0} `/bin/date`: Failed to build initiate a new webserver I will have to destroy it and try again" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
        ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
        exit    
fi

if ( [ "${sshpass}" = "1" ] )
then
	/usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/scp ${OPTIONS} ${BUILD_KEY}.pub ${CLOUDHOST_USERNAME}@${private_ip}:/root/.ssh/authorized_keys
fi

/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${SUDO} /usr/sbin/useradd ${SERVER_USER} 2>&1 >/dev/null ; /bin/echo ${SERVER_USER}:${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/chpasswd ; ${SUDO} /usr/bin/gpasswd -a ${SERVER_USER} sudo"
/bin/cat ${BUILD_KEY}.pub | /usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${SUDO} /bin/mkdir -p /home/${SERVER_USER}/.ssh ; ${SUDO} /bin/chown -R ${DEFAULT_USER}:${DEFAULT_USER} /home/${SERVER_USER}/.ssh ; /bin/cat - >> /home/${SERVER_USER}/.ssh/authorized_keys ; ${SUDO} /bin/sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config ; ${SUDO} /bin/sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config ; ${SUDO} /bin/sed -i 's/KbdInteractiveAuthentication yes/KbdInteractiveAuthentication no/g' /etc/ssh/sshd_config ; ${SUDO} /bin/sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' ; ${SUDO} /etc/init.d/ssh reload ; ${SUDO} /bin/chown -R ${SERVER_USER}:${SERVER_USER} /home/${SERVER_USER}"

/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${BUILD_KEY} ${SERVER_USER}@${private_ip}:/home/${SERVER_USER}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY
/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${HOME}/providerscripts/git/GitRemoteInstall.sh ${SERVER_USER}@${private_ip}:/home/${SERVER_USER}

git_provider_domain="`${HOME}/providerscripts/git/GitProviderDomain.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER}`"
count="0"
while ( [ "`/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/ls /home/${SERVER_USER}/ws.sh" 2>/dev/null`" = "" ] && [ "${count}" -lt "5" ] )
do
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/GitRemoteInstall.sh ; cd /home/${SERVER_USER}; /usr/bin/git clone https://${git_provider_domain}/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-webserver-scripts.git; /bin/cp -r ./adt-webserver-scripts/* .; /bin/rm -r ./adt-webserver-scripts; /bin/chown -R ${SERVER_USER}:${SERVER_USER} /home/${SERVER_USER}/*; /bin/chmod 500 /home/${SERVER_USER}/ws.sh "
	/bin/sleep 5
	count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "`/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${chosen_webserver_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/status/IsWebserverFullyBuilt.sh"`" = "0" ] )
then
:
fi
/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${HOME}/runtime/webserver_configuration_settings.dat ${HOME}/runtime/buildstyles.dat ${SERVER_USER}@${private_ip}:${HOME}/.ssh/
/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/ws.sh ${chosen_webserver_ip} ${WS_PUBLIC_IP} ${WS_PRIVATE_IP}"

if ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip}  "/bin/ls /home/${SERVER_USER}/runtime/SUCCESSFULLY_RSYNC_BUILT"`" != "" ] )
then
  ${HOME}/autoscaler/AddIPToDNS.sh ${ip}
fi

/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/touch ${HOME}/runtime/AUTOSCALED_WEBSERVER_ONLINE"
/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/rm ${HOME}/runtime/INITIAL_BUILD_WEBSERVER_ONLINE" 2>/dev/null

${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh  beingbuiltips/${private_ip}

/bin/rm ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip}
/bin/rm ${HOME}/runtime/beingbuiltpublicips/${buildno}/${ip}

#Output how long the build took
end=`/bin/date +%s`
runtime="`/usr/bin/expr ${end} - ${start}`"
/bin/echo "${0} This script took `/bin/date -u -d @${runtime} +\"%T\"` to complete and completed at time: `/usr/bin/date`" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

trap "cleanup ${buildno} successfully" TERM

/usr/bin/kill -TERM $$

trap "cleanup ${buildno} successfully" TERM

/usr/bin/kill -TERM $$
