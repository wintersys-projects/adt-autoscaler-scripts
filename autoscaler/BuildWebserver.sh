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


#If we are trying to build a webserver before the toolkit has been fully installed, we don't want to do anything, so exit
if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLED_SUCCESSFULLY"`" = "0" ] )
then
        exit
fi

buildno="${1}"
chosen_webserver_ip="${2}"

SERVER_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
REGION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'REGION'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
SIZE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SIZE'`"

if ( [ ! -d ${HOME}/runtime/cloud-init ] )
then
	/bin/mkdir -p ${HOME}/runtime/cloud-init
fi

git_provider_domain="github.com"

/bin/cp ${HOME}/providerscripts/server/cloud-init/linode.dat ${HOME}/runtime/cloud-init/linode.dat

/bin/sed -i "s/XXXXSERVER_USERXXXX/${SERVER_USER}/g" ${HOME}/runtime/cloud-init/linode.dat
/bin/sed -i "s/XXXXGIT_PROVIDER_DOMAINXXXX/${git_provider_domain}/g" ${HOME}/runtime/cloud-init/linode.dat
/bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${HOME}/runtime/cloud-init/linode.dat
/bin/sed -i "s/XXXXWEBSERVER_IPXXXX/${chosen_webserver_ip}/g" ${HOME}/runtime/cloud-init/linode.dat

###########################ADDED##############################



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

count="0"
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

