#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Put files into a bucket in the datastore
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
######################################################################################
######################################################################################
#set -x

file_to_put="$1"
datastore_to_put_in="$2"
delete="${3}"

if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
	datastore_tool="/usr/bin/s3cmd --force --recursive --multipart-chunk-size-mb=5 put "
elif ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ]  )
then
	host_base="`/bin/grep host_base /root/.s5cfg | /bin/grep host_base | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
	datastore_tool="/usr/bin/s5cmd --credentials-file /root/.s5cfg --endpoint-url https://${host_base} cp "
fi

if ( [ ! -f ${file_to_put} ] )
then
	file_to_put="/tmp/${file_to_put}"
	/bin/touch ${file_to_put}
fi

count="0"
while ( [ "`${datastore_tool} ${file_to_put} s3://${datastore_to_put_in} 2>&1 >/dev/null | /bin/grep "ERROR"`" != "" ] && [ "${count}" -lt "5" ] )
do
	/bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
	/bin/sleep 5
	count="`/usr/bin/expr ${count} + 1`"
done

file="`/bin/echo ${file_to_put} | /usr/bin/awk -F'/' '{print $NF}'`"

if ( [ "${delete}" != "" ] )
then
	/bin/rm ${file_to_put}
fi

