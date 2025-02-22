#!/bin/sh
####################################################################################################
# Author : Peter Winter
# Date   : 04/07/2016
# Description : This script will build the "autoscaler" from scratch
####################################################################################################
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
#set -x

#Get ourselves oriented and prepared
USER_HOME="`/usr/bin/awk -F: '{ print $1}' /etc/passwd | /bin/grep "X*X"`"
export HOME="/home/${USER_HOME}" | /usr/bin/tee -a ~/.bashrc

/bin/echo "set mouse=r" > /root/.vimrc

#Set the intialial permissions for the build
/usr/bin/find ${HOME} -not -path '*/\.*' -type d -print0 | xargs -0 chmod 0755 # for directories
/usr/bin/find ${HOME} -not -path '*/\.*' -type f -print0 | xargs -0 chmod 0500 # for files
/bin/chown ${SERVER_USER}:root ${HOME}/.ssh
/bin/chmod 750 ${HOME}/.ssh

export HOMEDIR=${HOME}
/bin/echo "${HOMEDIR}" > /home/homedir.dat
/bin/echo 'export HOME=`/bin/cat /home/homedir.dat` && /bin/sh ${1} ${2} ${3} ${4} ${5} ${6}' > /usr/bin/run
/bin/chown ${SERVER_USER}:root /usr/bin/run
/bin/chmod 750 /usr/bin/run

if ( [ ! -d ${HOME}/logs/initialbuild ] )
then
	/bin/mkdir -p ${HOME}/logs/initialbuild
fi

if ( [ ! -d ${HOME}/super ] )
then
	/bin/mkdir ${HOME}/super
fi

/bin/mv ${HOME}/providerscripts/utilities/security/Super.sh ${HOME}/super
/bin/chmod 400 ${HOME}/super/Super.sh

if ( [ -f ${HOME}/InstallGit.sh ] )
then
	/bin/rm ${HOME}/InstallGit.sh
fi

out_file="initialbuild/autoscaler-build-out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${HOME}/logs/${out_file}
err_file="initialbuild/autoscaler-build-err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${HOME}/logs/${err_file}


/bin/echo "${0} `/bin/date`: Beginning the build of the autoscaler" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} `/bin/date`: Building a new webserver" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} `/bin/date`: Setting up the build parameters" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log


#Create the config directories, these will be mounted from the autoscaler to the other server types - DB, WS and Images Servers
if ( [ ! -d ${HOME}/.ssh ] )
then
	/bin/mkdir ${HOME}/.ssh
	/bin/chmod 700 ${HOME}/.ssh
fi

if ( [ ! -d ${HOME}/runtime ] )
then
	/bin/mkdir -p ${HOME}/runtime
	/bin/chown ${SERVER_USER}:${SERVER_USER} ${HOME}/runtime
	/bin/chmod 755 ${HOME}/runtime
fi

#SERVER_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
#
#if ( [ -f ${HOME}/.ssh/autoscaler_configuration_settings.dat ] )
#then#
#	/bin/cp ${HOME}/.ssh/autoscaler_configuration_settings.dat ${HOME}/runtime/autoscaler_configuration_settings.dat
# 	/bin/mv ${HOME}/.ssh/autoscaler_configuration_settings.dat ${HOME}/.ssh/autoscaler_configuration_settings.dat.original
#  	/bin/chown root:root ${HOME}/.ssh/autoscaler_configuration_settings.dat.original
#   	/bin/chmod 400 ${HOME}/.ssh/autoscaler_configuration_settings.dat.original#
#	/bin/chown ${SERVER_USER}:root ${HOME}/runtime/autoscaler_configuration_settings.dat
#	/bin/chmod 640 ${HOME}/runtime/autoscaler_configuration_settings.dat
#fi

#if ( [ -f ${HOME}/.ssh/webserver_configuration_settings.dat ] )
#then
#	/bin/cp ${HOME}/.ssh/webserver_configuration_settings.dat ${HOME}/runtime/webserver_configuration_settings.dat
 #	/bin/mv ${HOME}/.ssh/webserver_configuration_settings.dat ${HOME}/.ssh/webserver_configuration_settings.dat.original
  #	/bin/chown ${SERVER_USER}:root ${HOME}/.ssh/webserver_configuration_settings.dat.original
  # 	/bin/chmod 400 ${HOME}/.ssh/webserver_configuration_settings.dat.original
#	/bin/chown ${SERVER_USER}:root ${HOME}/runtime/webserver_configuration_settings.dat
#	/bin/chmod 640 ${HOME}/runtime/webserver_configuration_settings.dat
#fi

#if ( [ -f ${HOME}/.ssh/buildstyles.dat ] )
#then
#	/bin/cp ${HOME}/.ssh/buildstyles.dat ${HOME}/runtime/buildstyles.dat
 #	/bin/mv ${HOME}/.ssh/buildstyles.dat ${HOME}/.ssh/buildstyles.dat.original
 #   	/bin/chown ${SERVER_USER}:root ${HOME}/.ssh/buildstyles.dat.original
 #  	/bin/chmod 400 ${HOME}/.ssh/buildstyles.dat.original#
#	/bin/chown ${SERVER_USER}:root ${HOME}/runtime/buildstyles.dat
#	/bin/chmod 640 ${HOME}/runtime/buildstyles.dat
#fi


#Load the parts of the configuration that we need into memory
WEBSITE_URL="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'WEBSITEURL'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
INFRASTRUCTURE_REPOSITORY_USERNAME="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYUSERNAME'`"
INFRASTRUCTURE_REPOSITORY_PASSWORD="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPASSWORD'`"
INFRASTRUCTURE_REPOSITORY_PROVIDER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPROVIDER'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
GIT_EMAIL_ADDRESS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'GITEMAILADDRESS'`"
DNS_USERNAME="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DNSUSERNAME'`"
DNS_SECURITY_KEY="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DNSSECURITYKEY'`"
SERVER_TIMEZONE_CONTINENT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERTIMEZONECONTINENT'`"
SERVER_TIMEZONE_CITY="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERTIMEZONECITY'`"
BUILDOS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
#SSH_PORT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SSHPORT'`"
#ALGORITHM="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ALGORITHM'`"
#BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"

#Non standard variable assignments
ROOT_DOMAIN="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
GIT_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'GITUSER'  | /bin/sed 's/#/ /g'` "
WEBSITE_NAME="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $2}'`"


#if ( [ ! -f ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ] )
#then
#	if ( [ -f /etc/ssh/ssh_host_rsa_key ] )
 #	then
  #		/bin/cp /etc/ssh/ssh_host_rsa_key ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}
#		/bin/chmod 600 ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}
#	fi
 #	if ( [ -f /etc/ssh/ssh_host_rsa_key.pub ] )
 #	then
  #		/bin/cp /etc/ssh/ssh_host_rsa_key.pub ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub
#		/bin/chmod 600 ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub
#	fi
#fi

#Initialise Git
/usr/bin/git config --global user.name "${GIT_USER}"
/usr/bin/git config --global user.email ${GIT_EMAIL_ADDRESS}
/usr/bin/git config --global init.defaultBranch main
/usr/bin/git config --global pull.rebase false 

#Set the hostname of this machine
#. ${HOME}/providerscripts/utilities/housekeeping/InitialiseHostname.sh

#Some kernel safeguards
/bin/echo "vm.panic_on_oom=1
kernel.panic=10" >> /etc/sysctl.conf

#if ( [ "`/bin/grep '^#Port' /etc/ssh/sshd_config`" != "" ] || [ "`/bin/grep '^Port' /etc/ssh/sshd_config`" != "" ] )
#then
#	/bin/sed -i "s/^Port.*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
#	/bin/sed -i "s/^#Port.*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
#else
#	/bin/echo "PermitRootLogin no" >> /etc/ssh/sshd_config
#fi

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Preventing root logins"
/bin/echo "${0} `/bin/date`: Preventing root logins" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Double down on preventing logins as root. We already tried, but, make absolutely sure because we can't guarantee format of /etc/ssh/sshd_config
#/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/g' {} +
#/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/g' {} +
#/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^PermitRootLogin.*/PermitRootLogin no/g' {} +
#/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/g' {} +
#/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/g' {} +
#/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^#KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/g' {} +
#/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/g' {} +
#/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/g' {} +
#/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^AddressFamily.*/AddressFamily inet/g' {} +
#/usr/bin/find /etc/ssh -name '*' -type f -exec sed -i 's/^#AddressFamily.*/AddressFamily inet/g' {} +

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Ensuring SSH connections are long lasting"
/bin/echo "${0} `/bin/date`: Ensuring SSH connections are long lasting" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Make sure that client connections to sshd are long lasting
#if ( [ "`/bin/grep 'ClientAliveInterval 200' /etc/ssh/sshd_config 2>/dev/null`" = "" ] )
#then
#	/bin/echo "
#ClientAliveInterval 200
#ClientAliveCountMax 10" >> /etc/ssh/sshd_config
#fi

#${HOME}/providerscripts/utilities/processing/RunServiceCommand.sh ssh restart

#Install the programs that we need to use when building the autoscaler

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Installing software packages "
/bin/echo "${0} `/bin/date`: Installing Software packages" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#${HOME}/installscripts/InstallCoreSoftware.sh &

#${HOME}/providerscripts/datastore/EssentialToolsAvailable.sh

${HOME}/security/SetupFirewall.sh


#>&2 /bin/echo "${0} Update.sh"
#${HOME}/installscripts/Update.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallFirewall.sh"
#${HOME}/installscripts/InstallFirewall.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallCurl.sh"
#${HOME}/installscripts/InstallCurl.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallSSHPass.sh"
#${HOME}/installscripts/InstallSSHPass.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallBC.sh"
#${HOME}/installscripts/InstallBC.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallJQ.sh"
#${HOME}/installscripts/InstallJQ.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallSendEmail.sh"
#${HOME}/installscripts/InstallSendEmail.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallLibioSocket.sh"
#${HOME}/installscripts/InstallLibioSocket.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallLibnetSsleay.sh"
#${HOME}/installscripts/InstallLibnetSsleay.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallSysStat.sh"
#${HOME}/installscripts/InstallSysStat.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallRsync.sh"
#${HOME}/installscripts/InstallRsync.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallCron.sh"
#${HOME}/installscripts/InstallCron.sh ${BUILDOS}
#>&2 /bin/echo "${0} Install Monitoring Gear"
#${HOME}/installscripts/InstallMonitoringGear.sh
#>&2 /bin/echo "${0} InstallGo.sh"
#${HOME}/installscripts/InstallGo.sh ${BUILDOS}

#Configure the timezone we are in
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Setting up timezone"
/bin/echo "${0} `/bin/date`: Setting timezone" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Set the time on the machine
#if ( [ "`/usr/bin/timedatectl list-timezones | /bin/grep ${SERVER_TIMEZONE_CONTINENT} | /bin/grep ${SERVER_TIMEZONE_CITY}`" != "" ] )
#then
#	/usr/bin/timedatectl set-timezone ${SERVER_TIMEZONE_CONTINENT}/${SERVER_TIMEZONE_CITY}
#	${HOME}/providerscripts/utilities/config/StoreConfigValue.sh "SERVERTIMEZONECONTINENT" "${SERVER_TIMEZONE_CONTINENT}"
#	${HOME}/providerscripts/utilities/config/StoreConfigValue.sh "SERVERTIMEZONECITY" "${SERVER_TIMEZONE_CITY}"
#	export TZ=":${SERVER_TIMEZONE_CONTINENT}/${SERVER_TIMEZONE_CITY}"
#fi


/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Installing cloudtools"
/bin/echo "${0} `/bin/date`: Installing cloudtools" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Install the tools for our particular cloudhost provider
#${HOME}/installscripts/InstallCloudhostTools.sh
${HOME}/providerscripts/cloudhost/InitialiseCloudhostConfig.sh

cd ${HOME}

#/bin/echo "ServerAliveInterval 15" | /usr/bin/tee ${HOME}/.ssh/config  /root/.ssh/config 
#/bin/echo "ServerAliveCountMax 6" | /usr/bin/tee -a ${HOME}/.ssh/config  /root/.ssh/config 

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Setting up the script which allows us to root"
/bin/echo "${0} `/bin/date`: Setting up the script which allows us to root" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Installing Datastore tools"
/bin/echo "${0} `/bin/date`: Installing Datastore tools" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
#Install the S3 compatible service we are using
#. ${HOME}/installscripts/InstallDatastoreTools.sh
. ${HOME}/providerscripts/datastore/InitialiseDatastoreConfig.sh

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Disabling password authentication"
/bin/echo "${0} `/bin/date`: Disabling password authentication" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#/bin/sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
#/bin/sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Changing our preferred SSH port"
/bin/echo "${0} `/bin/date`: Changing to our preferred SSH port" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#if ( [ -f /etc/systemd/system/ssh.service.d/00-socket.conf ] )
#then
#	/bin/rm /etc/systemd/system/ssh.service.d/00-socket.conf
#	/bin/systemctl daemon-restart
#fi

#/bin/systemctl disable --now ssh.socket
#/bin/systemctl enable --now ssh.service

DEVELOPMENT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DEVELOPMENT'`"
PRODUCTION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'PRODUCTION'`"

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Initialising Cron"
/bin/echo "${0} `/bin/date`: Initialising cron" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Initialise the cron scripts. If you want to add cron jobs, modify this script to include them
. ${HOME}/cron/InitialiseCron.sh

#/bin/chown -R ${SERVER_USER}:${SERVER_USER} ${HOME}

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Setting up the firewall and then rebooting for hygiene"
/bin/echo "${0} `/bin/date`: Rebooting the autoscaler post installation" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

${HOME}/providerscripts/utilities/processing/UpdateIPs.sh
${HOME}/providerscripts/utilities/housekeeping/CleanupAfterBuild.sh

${HOME}/providerscripts/email/SendEmail.sh "A NEW AUTOSCALER HAS BEEN SUCCESSFULLY BUILT" "A new autoscaler machine has been built and is now going to reboot before coming available" "INFO"

/bin/touch ${HOME}/runtime/DONT_MESS_WITH_THESE_FILES-SYSTEM_BREAK
/bin/touch ${HOME}/runtime/AUTOSCALER_READY
/bin/touch ${HOME}/runtime/AUTHORISED_TO_SCALE

${HOME}/providerscripts/utilities/security/EnforcePermissions.sh

#${HOME}/installscripts/UpdateAndUpgrade.sh ${BUILDOS} &


#/usr/sbin/shutdown -r now
