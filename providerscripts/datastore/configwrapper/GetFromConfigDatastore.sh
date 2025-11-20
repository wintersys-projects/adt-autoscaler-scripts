#!/bin/sh
####################################################################################
# Author: Peter Winter
# Date :  24/02/2022
# Description: This will list a particular value from the configuration datastore
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
######################################################################################
######################################################################################
#set -x

export HOME=`/bin/cat /home/homedir.dat`

WEBSITE_URL="`${HOME}/utilities/config/ExtractConfigValue.sh 'WEBSITEURLORIGINAL'`"
if ( [ "${WEBSITE_URL}" = "" ] )
then
	WEBSITE_URL="`${HOME}/utilities/config/ExtractConfigValue.sh 'WEBSITEURL'`"
fi

SERVER_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
TOKEN="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1 | /usr/bin/tr '[:upper:]' '[:lower:]'`"
configbucket="`/bin/echo "${WEBSITE_URL}"-config | /bin/sed 's/\./-/g'`-${TOKEN}"
datastore_tool=""

if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
        datastore_tool="/usr/bin/s3cmd"
elif ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ]  )
then
        datastore_tool="/usr/bin/s5cmd"
elif ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:rclone'`" = "1" ]  )
then
        datastore_tool="/usr/bin/rclone"
fi

if ( [ "${datastore_tool}" = "/usr/bin/s3cmd" ] )
then
        host_base="`/bin/grep host_base /root/.s3cfg-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --config=/root/.s3cfg-1 --force --recursive --host=https://${host_base} ls s3://${config_bucket}/"
        datastore_cmd1="${datastore_tool} --config=/root/.s3cfg-1 --force --recursive --host=https://${host_base} get s3://${config_bucket}/"
elif ( [ "${datastore_tool}" = "/usr/bin/s5cmd" ] )
then
        host_base="`/bin/grep host_base /root/.s5cfg-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --credentials-file /root/.s5cfg-1 --endpoint-url https://${host_base} ls s3://${config_bucket}/"
        datastore_cmd1="${datastore_tool} --credentials-file /root/.s5cfg-1 --endpoint-url https://${host_base} cp s3://${config_bucket}/"
elif ( [ "${datastore_tool}" = "/usr/bin/rclone" ] )
then
        host_base="`/bin/grep ^endpoint /root/.config/rclone/rclone.conf-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --config /root/.config/rclone/rclone.conf-1 --s3-endpoint ${host_base} ls s3:${config_bucket}/"
        datastore_cmd1="${datastore_tool} --config /root/.config/rclone/rclone.conf-1 --s3-endpoint ${host_base} copy s3:${config_bucket}/"
fi

if ( [ "${destination}" = "" ] )
then
        destination="."
fi

if ( [ "`${datastore_cmd}${file_to_get}`" = "" ] )
then
        /bin/echo "Key doesn't exist"
else
        count="0"
        while ( [ "`${datastore_cmd1}${file_to_get} ${destination} 2>&1 >/dev/null | /bin/grep "ERROR"`" != "" ] && [ "${count}" -lt "5" ] )
        do
                /bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
                /bin/sleep 5
                count="`/usr/bin/expr ${count} + 1`"
        done
fi

