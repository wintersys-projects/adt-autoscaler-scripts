#!/bin/sh
#########################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Create a bucket in the datastore
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

datastore_to_mount="$1"
count="${2}"

datastore_tool=""

if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
	datastore_tool="/usr/bin/s3cmd"
elif ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ]  )
then
	datastore_tool="/usr/bin/s5cmd"
fi

if ( [ "${datastore_tool}" = "/usr/bin/s3cmd" ] )
then
        datastore_cmd="${datastore_tool} --config=/root/.s3cfg-${count} ls "
        datastore_cmd1="${datastore_tool} --config=/root/.s3cfg-${count} mb "
elif ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ]  )
then
        host_base="`/bin/grep host_base /root/.s5cfg-${count} | /bin/grep host_base | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_cmd="${datastore_tool} --credentials-file /root/.s5cfg-${count} --endpoint-url https://${host_base} ls "
        datastore_cmd1="${datastore_tool} --credentials-file /root/.s5cfg-${count} --endpoint-url https://${host_base} mb "
fi

if ( [ "`${datastore_cmd} s3://${datastore_to_mount}`" != "" ] )
then
        exit
fi

count="0"
while ( [ "`${datastore_cmd1} s3://${datastore_to_mount} 2>&1 >/dev/null | /bin/grep "ERROR"`" != "" ] && [ "${count}" -lt "5" ] )
do
        /bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
        /bin/sleep 5
        count="`/usr/bin/expr ${count} + 1`"
done 
