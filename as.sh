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
/bin/echo 'export HOME="/home/'${USER_HOME}'"' >> /home/${USER_HOME}/.bashrc
/bin/chmod 644 /home/${USER_HOME}/.bashrc
/bin/chown ${USER_HOME}:root /home/${USER_HOME}/.bashrc

SERVER_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"

#comment/amend as you desire
if ( [ ! -f /root/.vimrc-adt ] )
then
        /bin/echo "
		color=elflord
        set mouse=r
        syntax on
        filetype indent on
        set smartindent
        set fo-=or
        autocmd BufRead,BufWritePre *.sh normal gg=G " > /root/.vimrc-adt

        /bin/echo "alias vim='/usr/bin/vim -u /root/.vimrc-adt'" >> /root/.bashrc
        /bin/echo "alias vi='/usr/bin/vim -u /root/.vimrc-adt'" >> /root/.bashrc
fi

#Set the intial permissions for the build
/usr/bin/find ${HOME} -not -path '*/\.*' -type d -print0 | xargs -0 chmod 0755 # for directories
/usr/bin/find ${HOME} -not -path '*/\.*' -type f -print0 | xargs -0 chmod 0500 # for files
/bin/chown ${SERVER_USER}:root ${HOME}/.ssh
/bin/chmod 750 ${HOME}/.ssh

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

/bin/mv ${HOME}/utilities/security/Super.sh ${HOME}/super
/bin/chmod 400 ${HOME}/super/Super.sh

if ( [ -f ${HOME}/InstallGit.sh ] )
then
	/bin/rm ${HOME}/InstallGit.sh
fi

out_file="initialbuild/autoscaler-build-out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${HOME}/logs/${out_file}
err_file="initialbuild/autoscaler-build-err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${HOME}/logs/${err_file}


/bin/echo "${0} `/bin/date`: Beginning the build of the autoscaler" 

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

#Load the parts of the configuration that we need into memory
GIT_EMAIL_ADDRESS="`${HOME}/utilities/config/ExtractConfigValue.sh 'GITEMAILADDRESS'`"
BUILDOS="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
ROOT_DOMAIN="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
GIT_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'GITUSER'  | /bin/sed 's/#/ /g'` "

#Initialise Git
/usr/bin/git config --global user.name "${GIT_USER}"
/usr/bin/git config --global user.email ${GIT_EMAIL_ADDRESS}
/usr/bin/git config --global init.defaultBranch main
/usr/bin/git config --global pull.rebase false 

if ( [ -f ${HOME}/utilities/software/PushInfrastructureScriptsUpdates.sh ] )
then
	/bin/cp ${HOME}/utilities/software/PushInfrastructureScriptsUpdates.sh /usr/sbin/push
	/bin/chmod 755 /usr/sbin/push
	/bin/chown root:root /usr/sbin/push
fi
if ( [ -f ${HOME}/utilities/software/PushAndSyncInfrastructureScriptsUpdates.sh ] )
then
	/bin/cp ${HOME}/utilities/software/PushAndSyncInfrastructureScriptsUpdates.sh /usr/sbin/push-and-sync
	/bin/chmod 755 /usr/sbin/push-and-sync
	/bin/chown root:root /usr/sbin/push-and-sync
fi
if ( [ -f ${HOME}/utilities/software/SyncInfrastructureScriptsUpdates.sh ] )
then
	/bin/cp ${HOME}/utilities/software/SyncInfrastructureScriptsUpdates.sh /usr/sbin/sync
	/bin/chmod 755 /usr/sbin/sync
	/bin/chown root:root /usr/sbin/sync
fi


/bin/echo "${0} Setting up firewall"
${HOME}/security/SetupFirewall.sh

/bin/echo "${0} Initialising cloudhost config"
${HOME}/providerscripts/cloudhost/InitialiseCloudhostConfig.sh

cd ${HOME}

/bin/echo "${0} Initialising datastore config"
${HOME}/providerscripts/datastore/InitialiseDatastoreConfig.sh

/bin/echo "${0} Initialising cron"
${HOME}/cron/InitialiseCron.sh

${HOME}/utilities/processing/UpdateIPs.sh
${HOME}/utilities/housekeeping/CleanupAfterBuild.sh

${HOME}/providerscripts/email/SendEmail.sh "A NEW AUTOSCALER HAS BEEN SUCCESSFULLY BUILT" "A new autoscaler machine has been built and is now going to reboot before coming available" "INFO"

/bin/touch ${HOME}/runtime/DONT_MESS_WITH_THESE_FILES-SYSTEM_BREAK
/bin/touch ${HOME}/runtime/AUTOSCALER_READY
/bin/touch ${HOME}/runtime/AUTHORISED_TO_SCALE

/bin/echo "${0} Enforcing permissions"
${HOME}/utilities/security/EnforcePermissions.sh

#${HOME}/installscripts/UpdateAndUpgrade.sh ${BUILDOS} &


