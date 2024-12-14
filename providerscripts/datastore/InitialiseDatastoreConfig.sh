
#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This will setup the configuration file for the current s3 interaction tool
# a template is held in the configfiles subdirectory if needed with placeholders that
# this script replaces with "live" values. If there is a change to the format that a
# later version of the current s3 tool needs needs then the template in the "configfiles"
# subdirectory will have to be updated to reflect the needed changes. 
# I did some experimenting and this was the easiest and cleanest way I could come up
# with for generating these configuration files. 
######################################################################################
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
###################################################################################
###################################################################################
#set -x

export HOME="`/bin/cat /home/homedir.dat`"
SERVER_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"

if ( [ "`${HOME}/providerscripts/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
        datastore_tool="/usr/bin/s3cmd"

elif  ( [ "`${HOME}/providerscripts/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ] )
then
	datastore_tool="/usr/bin/s5cmd"
fi

S3_ACCESS_KEY="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'S3ACCESSKEY'`"
S3_SECRET_KEY="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'S3SECRETKEY'`"
S3_LOCATION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'S3LOCATION'`"
S3_HOST_BASE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'S3HOSTBASE'`"

if ( [ -f ${HOME}/.s3cfg ] )
then
	/bin/rm ${HOME}/.s3cfg
fi

if ( [ -f ${HOME}/.s5cfg ] )
then
	/bin/rm ${HOME}/.s5cfg
fi

/bin/cp ${HOME}/providerscripts/datastore/configfiles/s3-cfg.tmpl ${HOME}/.s3cfg

if ( [ "${S3_ACCESS_KEY}" != "" ] )
then
	/bin/sed -i "s/XXXXACCESSKEYXXXX/${S3_ACCESS_KEY}/" ${HOME}/.s3cfg
	/bin/echo "[default]" > ${HOME}/.s5cfg 
 	/bin/echo "aws_access_key_id = ${S3_ACCESS_KEY}" >> ${HOME}/.s5cfg
else
	/bin/echo "${0} Couldn't find the S3_ACCESS_KEY setting" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log    
fi

if ( [ "${S3_SECRET_KEY}" != "" ] )
then
	/bin/sed -i "s/XXXXSECRETKEYXXXX/${S3_SECRET_KEY}/" ${HOME}/.s3cfg
   	/bin/echo "aws_secret_access_key = ${S3_SECRET_KEY}" >> ${HOME}/.s5cfg
else
	/bin/echo "${0} Couldn't find the S3_SECRET_KEY setting" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log  
fi

if ( [ "${S3_LOCATION}" != "" ] )
then
	/bin/sed -i "s/XXXXLOCATIONXXXX/${S3_LOCATION}/" ${HOME}/.s3cfg
else
	/bin/echo "${0} Couldn't find the S3_LOCATION setting" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log  
fi

if ( [ "${S3_HOST_BASE}" != "" ] )
then
	/bin/sed -i "s/XXXXHOSTBASEXXXX/${S3_HOST_BASE}/" ${HOME}/.s3cfg
   	/bin/echo "host_base = ${S3_HOST_BASE}" >> ${HOME}/.s5cfg
    	/bin/echo "alias s5cmd='/usr/bin/s5cmd --credentials-file /root/.s5cfg --endpoint-url https://${S3_HOST_BASE}'" >> /root/.bashrc
else
	/bin/echo "${0} Couldn't find the S3_HOST_BASE setting" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log  
fi

if ( [ -f /root/.s3cfg ] )
then
	/bin/rm /root/.s3cfg
fi

/bin/chown ${SERVER_USER}:${SERVER_USER} ${HOME}/.s3cfg
/bin/cp ${HOME}/.s3cfg /root/.s3cfg

if ( [ -f /root/.s5cfg ] )
then
	/bin/rm /root/.s5cfg
fi

/bin/chown ${SERVER_USER}:${SERVER_USER} ${HOME}/.s5cfg
/bin/cp ${HOME}/.s5cfg /root/.s5cfg

${datastore_tool} mb s3://1$$agile 3>&1 2>/dev/null
${datastore_tool} rb s3://1$$agile 3>&1 2>/dev/null

if ( [ "$?" != "0" ] )
then
	/bin/echo "${0} Your datastore didn't configure correctly on this machine and that will cause the deployment to break" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log  
fi
