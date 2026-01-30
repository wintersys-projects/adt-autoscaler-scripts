#!/bin/sh
#########################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Implement the putting of a file from the filesystem of the server to a
# datastore
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
count="$4"

HOME="`/bin/cat /home/homedir.dat`"

if ( [ "${place_to_put}" = "root" ] )
then
        place_to_put=""
fi

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
        host_base="`/bin/grep ^host_base /root/.s3cfg-${count} | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --config=/root/.s3cfg-${count}  --host=https://${host_base} put "
        bucket_prefix="s3://"
        slasher="/"
        place_to_put="`/bin/echo ${place_to_put} | /bin/sed 's;\/$;;g'`"
        placed_file="`/bin/echo ${file_to_put} | /usr/bin/awk -F'/' '{print $NF}'`"
elif ( [ "${datastore_tool}" = "/usr/bin/s5cmd" ] )
then
        host_base="`/bin/grep ^host_base /root/.s5cfg-${count} | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        now="`/usr/bin/date +'%Y-%m-%dT%H:%M:%S'`"
        datastore_cmd="${datastore_tool} --credentials-file /root/.s5cfg-${count} --endpoint-url https://${host_base} cp --metadata 'CreationDate=${now}'"
        bucket_prefix="s3://"
        slasher="/"
        placed_file=""
elif ( [ "${datastore_tool}" = "/usr/bin/rclone" ] )
then
        host_base="`/bin/grep ^endpoint /root/.config/rclone/rclone.conf-${count} | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --config /root/.config/rclone/rclone.conf-${count} --s3-endpoint ${host_base} copy "
        now="`/usr/bin/date +'%Y-%m-%dT%H:%M:%S'`"
        datastore_cmd1="${datastore_tool} --config /root/.config/rclone/rclone.conf-${count} --s3-endpoint ${host_base} --timestamp ${now} touch "
        bucket_prefix="s3:"
        slasher="/"
        placed_file="`/bin/echo ${file_to_put} | /usr/bin/awk -F'/' '{print $NF}'`"
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
while ( [ "`${datastore_cmd} ${file_to_put} ${bucket_prefix}${place_to_put}${slasher}${placed_file} 2>&1 >/dev/null | /bin/grep -E "(ERROR|NOTICE)"`" != "" ] && [ "${count}" -lt "5" ] )
do
        /bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
        /bin/sleep 5
        count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${datastore_cmd1}" != "" ] )
then
        ${datastore_cmd1} ${bucket_prefix}${place_to_put}${slasher}${placed_file}
fi

if ( [ "${delete}" = "yes" ] )
then
        if ( [ -f ${file_to_put} ] )
        then
                /bin/rm ${file_to_put}
        fi
fi
