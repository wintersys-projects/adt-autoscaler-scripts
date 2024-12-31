#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/06/2021
# Description : This obtains the build client IP from the S3 system
#######################################################################################
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
########################################################################################
########################################################################################
#set -x

if ( [ ! -d ${HOME}/runtime/BUILDCLIENTIP ] )
then
	/bin/mkdir ${HOME}/runtime/BUILDCLIENTIP
fi

if ( [ "`/bin/ls ${HOME}/runtime/BUILDCLIENTIP/*`" != "" ] && [ -f ${HOME}/runtime/BUILD_CLIENT_UPDATED ] )
then
	exit
fi

uptime="`/usr/bin/uptime | /usr/bin/awk -F ',' ' {print $1} ' | /usr/bin/awk ' {print $3} ' | /usr/bin/awk -F ':' ' {hrs=$1; min=$2; print
 hrs*60 + min} '`"
 
if ( [ "${uptime}" -gt "15" ] )
then
	exit
fi
 
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
/bin/rm ${HOME}/runtime/BUILDCLIENTIP/*

if ( [ "`${HOME}/providerscripts/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
        datastore_tool="/usr/bin/s3cmd get "
elif ( [ "`${HOME}/providerscripts/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ]  )
then
        host_base="`/bin/grep host_base /root/.s5cfg | /bin/grep host_base | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_tool="/usr/bin/s5cmd --credentials-file /root/.s5cfg --endpoint-url https://${host_base} cp "
fi

${datastore_tool} s3://adt-${BUILD_IDENTIFIER}/* ${HOME}/runtime/BUILDCLIENTIP 


BUILD_CLIENT_IP="`/bin/ls ${HOME}/runtime/BUILDCLIENTIP/* | /usr/bin/awk -F'/' '{print $NF}' | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`"
OLD_BUILD_CLIENT_IP="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDCLIENTIP'`"

if ( [ "${OLD_BUILD_CLIENT_IP}" != "${BUILD_CLIENT_IP}" ] )
then
	${HOME}/providerscripts/utilities/config/StoreConfigValue.sh "BUILDCLIENTIP" "${BUILD_CLIENT_IP}"  
	/bin/touch ${HOME}/runtime/BUILD_CLIENT_UPDATED
fi
