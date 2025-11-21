#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Lists files from a bucket in the datastore
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

file_to_list="$1"

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

        if ( [ "${file_to_list}" = "" ] )
        then
                datastore_cmd="${datastore_tool} --config=/root/.s3cfg-1 --recursive --host=https://${host_base} ls"
        else
                datastore_cmd="${datastore_tool} --config=/root/.s3cfg-1 --recursive --host=https://${host_base} ls s3://"
        fi
elif ( [ "${datastore_tool}" = "/usr/bin/s5cmd" ] )
then
        host_base="`/bin/grep ^host_base /root/.s5cfg-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`"

        if ( [ "${file_to_list}" = "" ] )
        then
                datastore_cmd="${datastore_tool} --credentials-file /root/.s5cfg-1 --endpoint-url https://${host_base} ls"
        else
                datastore_cmd="${datastore_tool} --credentials-file /root/.s5cfg-1 --endpoint-url https://${host_base} ls s3://"
        fi
elif ( [ "${datastore_tool}" = "/usr/bin/rclone" ] )
then
        host_base="`/bin/grep ^endpoint /root/.config/rclone/rclone.conf-1 | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        if ( [ "${file_to_list}" = "" ] )
        then
                datastore_cmd="${datastore_tool} --config /root/.config/rclone/rclone.conf-1  --s3-endpoint ${host_base} lsd s3:"
        else
                datastore_cmd="${datastore_tool} --config /root/.config/rclone/rclone.conf-1  --s3-endpoint ${host_base} ls s3:"
        fi
        file_to_list="`/bin/echo ${file_to_list} | /bin/sed 's/\*//g'`"
fi

if ( [ "${file_to_list}" = "" ] )
then
        ${datastore_cmd} | /usr/bin/awk '{print $NF}' 2>/dev/null
else
        ${datastore_cmd}${file_to_list} | /usr/bin/awk '{print $NF}' 2>/dev/null
fi
