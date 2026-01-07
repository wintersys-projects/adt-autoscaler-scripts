#!/bin/sh
#########################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Actually put a file to the datastore bucket for the current S3 provider and using the
# tool that is currently configured as active
##########################################################################################
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
#########################################################################################
#########################################################################################
#set -x

file_to_put="$1"
place_to_put="$2"
delete="$3"

HOME="`/bin/cat /home/homedir.dat`"

WEBSITE_URL="`${HOME}/utilities/config/ExtractConfigValue.sh 'WEBSITEURL'`"
SERVER_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
TOKEN="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1 | /usr/bin/tr '[:upper:]' '[:lower:]'`"
config_bucket="`/bin/echo "${WEBSITE_URL}"-config | /bin/sed 's/\./-/g'`-${TOKEN}/"

datastore_tool=""
datastore_cmd=""
datastore_cmd1=""

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
        host_base="`/bin/grep ^host_base /root/.s3cfg-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --force --recursive --multipart-chunk-size-mb=5 --config=/root/.s3cfg-1  --host=https://${host_base} put "
        bucket_prefix="s3://"
        if ( [ "${place_to_put}" = "" ] )
        then
                slasher=""
        else
                slasher="/"
        fi
elif ( [ "${datastore_tool}" = "/usr/bin/s5cmd" ] )
then
        host_base="`/bin/grep ^host_base /root/.s5cfg-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --credentials-file /root/.s5cfg-1 --endpoint-url https://${host_base} cp "
        bucket_prefix="s3://"
        if ( [ "${place_to_put}" = "" ] )
        then
                slasher=""
        else
                slasher="/"
        fi
elif ( [ "${datastore_tool}" = "/usr/bin/rclone" ] )
then
        host_base="`/bin/grep ^endpoint /root/.config/rclone/rclone.conf-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --config /root/.config/rclone/rclone.conf-1 --s3-endpoint ${host_base} copy "
        now="`/usr/bin/date +'%Y-%m-%dT%H:%M:%S'`"
        datastore_cmd1="${datastore_tool} --config /root/.config/rclone/rclone.conf-1 --s3-endpoint ${host_base} --timestamp ${now} touch "
        bucket_prefix="s3:"
        slasher="/"
fi

if ( [ ! -d ${HOME}/runtime/datastore_workarea ] )
then
        /bin/mkdir -p ${HOME}/runtime/datastore_workarea
fi

if ( [ ! -f ${file_to_put} ] )
then
        #if there is no file on the file system we can assume that we are being used as a marker like an IP address, so create out own marker file
        /bin/touch ${HOME}/runtime/datastore_workarea/${file_to_put}
        file_to_put=${HOME}/runtime/datastore_workarea/${file_to_put}
fi

count="0"
while ( [ "`${datastore_cmd} ${file_to_put} ${bucket_prefix}${config_bucket}${place_to_put}${slasher} 2>&1 >/dev/null | /bin/grep -E "(ERROR|NOTICE)"`" != "" ] && [ "${count}" -lt "5" ] )
do
        /bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
        /bin/sleep 5
        count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${datastore_cmd1}" != "" ] )
then
        placed_file="`/bin/echo ${file_to_put} | /usr/bin/awk -F'/' '{print $NF}'`"
        ${datastore_cmd1} ${bucket_prefix}${config_bucket}${place_to_put}${slasher}${placed_file}
fi

if ( [ "${delete}" = "yes" ] )
then
        if ( [ -f ${file_to_put} ] )
        then
                /bin/rm ${file_to_put}
        fi
fi
