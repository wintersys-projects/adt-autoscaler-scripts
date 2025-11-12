#!/bin/sh
#########################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Get a file from a bucket in the datastore
#########################################################################################
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

datastore_to_get="${1}"
destination="${2}"

REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'REGION'`"

if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
	config_file="`/bin/grep -H ${REGION} /root/.s3cfg-* | /usr/bin/awk -F':' '{print $1}'`"
	datastore_tool="/usr/bin/s3cmd --config=${config_file} --force --recursive get "
elif ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ]  )
then
	config_file="`/bin/grep -H ${REGION} /root/.s5cfg-* | /usr/bin/awk -F':' '{print $1}'`"
	host_base="`/bin/grep host_base ${config_file} | /bin/grep host_base | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
	datastore_tool="/usr/bin/s5cmd --credentials-file ${config_file} --endpoint-url https://${host_base} cp "
	if ( [ "${destination}" = "" ] )
	then
		destination="."
	fi
fi

count="0"
while ( [ "`${datastore_tool} s3://${datastore_to_get} ${destination} 2>&1 >/dev/null | /bin/grep "ERROR"`" != "" ] && [ "${count}" -lt "5" ] )
do
	/bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
	/bin/sleep 5
	count="`/usr/bin/expr ${count} + 1`"
done 
