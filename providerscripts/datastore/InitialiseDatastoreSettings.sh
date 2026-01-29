#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Calling this script will intialise your dataatore settings (in other words
# the credentials needed for the datastore to operate). For a datastore to be used it needs
# to have its settings initialised. 
#####################################################################################
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
####################################################################################
####################################################################################
#set -x

S3_ACCESS_KEY="`${HOME}/utilities/config/ExtractConfigValue.sh 'S3ACCESSKEY'`"
S3_SECRET_KEY="`${HOME}/utilities/config/ExtractConfigValue.sh 'S3SECRETKEY'`"
S3_LOCATION="`${HOME}/utilities/config/ExtractConfigValue.sh 'S3LOCATION'`"
S3_HOST_BASE="`${HOME}/utilities/config/ExtractConfigValue.sh 'S3HOSTBASE'`"
BUILDOS="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"

no_tokens="`/bin/echo "${S3_ACCESS_KEY}" | /usr/bin/fgrep -o '|' | /usr/bin/wc -l`"
no_tokens="`/usr/bin/expr ${no_tokens} + 1`"
count="1"

not_configured="1"
if ( [ -f /root/.config/rclone/rclone.multi.conf ] )
then
        not_configured="0"
fi

while ( [ "${count}" -le "${no_tokens}" ] )
do
        ${HOME}/providerscripts/datastore/PerformInitialiseDatastoreSettings.sh "`/bin/echo "${S3_ACCESS_KEY}" | /usr/bin/cut -d "|" -f ${count}`" "`/bin/echo "${S3_SECRET_KEY}" | /usr/bin/cut -d "|" -f ${count}`" "`/bin/echo "${S3_LOCATION}" | /usr/bin/cut -d "|" -f ${count}`" "`/bin/echo "${S3_HOST_BASE}" | /usr/bin/cut -d "|" -f ${count}`" ${count} ${multi_region_rclone}  
        count="`/usr/bin/expr ${count} + 1`"
done

if ( [ -f /root/.config/rclone/rclone.multi.conf ] && [ "${not_configured}" = "1" ] )
then
        ${HOME}/installscripts/InstallGawk.sh ${BUILDOS}
        /usr/bin/gawk -i inplace 'sub(/\[s3/,"&_"i+1){i++} 1' /root/.config/rclone/rclone.multi.conf 
fi
