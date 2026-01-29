#!/bin/sh
######################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Implement the moving of an object within a datastore
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
#######################################################################################
#######################################################################################
#set -x

original_object="$1"
new_object="$2"
count="$3"

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
        host_base="`/bin/grep ^host_base /root/.s3cfg-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --config=/root/.s3cfg-${count} --host=https://${host_base} ls s3://"
        datastore_cmd1="${datastore_tool} --config=/root/.s3cfg-${count} --host=https://${host_base} mv s3://"
        second_prefix="s3://"
elif ( [ "${datastore_tool}" = "/usr/bin/s5cmd" ] )
then
        host_base="`/bin/grep ^host_base /root/.s5cfg-${count} | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --credentials-file /root/.s5cfg-${count} --endpoint-url https://${host_base} ls s3://"
        datastore_cmd1="${datastore_tool} --credentials-file /root/.s5cfg-${count} --endpoint-url https://${host_base} mv s3://"
        second_prefix="s3://"
elif ( [ "${datastore_tool}" = "/usr/bin/rclone" ] )
then
        host_base="`/bin/grep ^endpoint /root/.config/rclone/rclone.conf-${count} | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --config /root/.config/rclone/rclone.conf-${count} --s3-endpoint ${host_base} ls s3:"
        datastore_cmd1="${datastore_tool} --config /root/.config/rclone/rclone.conf-${count} --s3-endpoint ${host_base} moveto s3:"
        second_prefix="s3:"
fi

if ( [ "`${datastore_cmd}${original_object}`" != "" ] )
then
        count="0"
        while ( [ "`${datastore_cmd1}${original_object} ${second_prefix}${new_object} 2>&1 >/dev/null | /bin/grep -E "(ERROR|NOTICE)"`" != "" ] && [ "${count}" -lt "5" ] )
        do
                /bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
                /bin/sleep 5
                count="`/usr/bin/expr ${count} + 1`"
        done
fi
