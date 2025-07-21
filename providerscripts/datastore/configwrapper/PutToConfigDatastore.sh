#!/bin/sh
####################################################################################
# Author: Peter Winter
# Date :  24/02/2022
# Description: This will put a particular file to the configuration datastore
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

file_to_put="${1}"
place_to_put="${2}"

export HOME=`/bin/cat /home/homedir.dat`

WEBSITE_URL="`${HOME}/utilities/config/ExtractConfigValue.sh 'WEBSITEURL'`"
SERVER_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
TOKEN="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1 | /usr/bin/tr '[:upper:]' '[:lower:]'`"
configbucket="`/bin/echo "${WEBSITE_URL}"-config | /bin/sed 's/\./-/g'`-${TOKEN}"


if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
	datastore_tool="/usr/bin/s3cmd put "
elif ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ]  )
then
	host_base="`/bin/grep host_base /root/.s5cfg | /bin/grep host_base | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
	datastore_tool="/usr/bin/s5cmd --credentials-file /root/.s5cfg --endpoint-url https://${host_base} cp "
fi

if ( [ ! -f ${file_to_put} ] )
then
	path_to_file="`/bin/echo ${file_to_put} | sed 's:/[^/]*$::' | /bin/sed 's,^/,,'`"
	file="`/bin/echo "${file_to_put}" | /bin/grep "/" | /usr/bin/awk -F'/' '{print $NF}'`"

	if ( [ "`/bin/echo ${file_to_put} | /bin/grep "/"`" = "" ] )
	then
		file_to_put="/tmp/${file_to_put}"
	else
		file_to_put="/tmp/${path_to_file}/${file}"
		dir="`/bin/echo ${file_to_put} | /bin/sed 's:/[^/]*$::'`"
		if ( [ -d ${dir} ] )
		then
			/bin/mv ${dir} ${dir}.$$
		fi
		/bin/mkdir -p "${dir}"
	fi
	/bin/touch ${file_to_put}
fi

if ( [ "${place_to_put}" != "" ] )
then
	command="${datastore_tool} ${file_to_put} s3://${configbucket}/${place_to_put}"
else
	command="${datastore_tool} ${file_to_put} s3://${configbucket}"
fi

count="0"
satisfied="0"
while ( [ "${count}" -lt "5" ] && [ "${satisfied}" = "0" ] )
do
	result="`${command} 2>&1 >/dev/null`" 
	if ( [ "`/bin/echo ${result} | /bin/grep 'ERROR'`" != "" ] )
	then
		/bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
		/bin/sleep 5
		count="`/usr/bin/expr ${count} + 1`"
	else 
		satisfied="1"
	fi
done 

if ( [ -f ${file_to_put} ] )
then
	/bin/rm ${file_to_put}
fi
