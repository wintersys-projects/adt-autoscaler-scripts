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

export HOME=`/bin/cat /home/homedir.dat`
WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"

SERVER_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSER'`"
TOKEN="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1 | /usr/bin/tr '[:upper:]' '[:lower:]'`"

configbucket="`/bin/echo "${WEBSITE_URL}"-config | /bin/sed 's/\./-/g'`-${TOKEN}"

if ( [ "`${HOME}/providerscripts/utilities/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
        datastore_tool="/usr/bin/s3cmd --recursive put "
	datastore_tool_1="/usr/bin/s3cmd put "
elif ( [ "`${HOME}/providerscripts/utilities/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ]  )
then
        host_base="`/bin/grep host_base /root/.s5cfg | /bin/grep host_base | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_tool="/usr/bin/s5cmd --credentials-file /root/.s5cfg --endpoint-url https://${host_base} cp "
        datastore_tool_1="/usr/bin/s5cmd --credentials-file /root/.s5cfg --endpoint-url https://${host_base} cp "
fi

if ( [ "$3" = "recursive" ] )
then
	count="0"
	while ( [ "`${datastore_tool_1} $1 s3://${configbucket}/$2 2>&1 >/dev/null | /bin/grep "ERROR"`" != "" ] && [ "${count}" -lt "5" ] )
	do
         	/bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
        	/bin/sleep 5
        	count="`/usr/bin/expr ${count} + 1`"
	done 
else
	if ( [ -f ${1} ] )
	then
 		count="0"
		while ( [ "`${datastore_tool} $1 s3://${configbucket}/$2 2>&1 >/dev/null | /bin/grep "ERROR"`" != "" ] && [ "${count}" -lt "5" ] )
		do
          		/bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
        		/bin/sleep 5
        		count="`/usr/bin/expr ${count} + 1`"
		done 
	elif ( [ -f ./${1} ] )
	then
  		count="0"
		while ( [ "`${datastore_tool} ./$1 s3://${configbucket}/$2 2>&1 >/dev/null | /bin/grep "ERROR"`" != "" ] && [ "${count}" -lt "5" ] )
		do
          		/bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
        		/bin/sleep 5
        		count="`/usr/bin/expr ${count} + 1`"
		done 
		/bin/rm ./$1
	elif ( [ -f /tmp/${1} ] )
	then
  		count="0"
		while ( [ "`${datastore_tool} /tmp/$1 s3://${configbucket}/$2 2>&1 >/dev/null | /bin/grep "ERROR"`" != "" ] && [ "${count}" -lt "5" ] )
		do
          		/bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
        		/bin/sleep 5
        		count="`/usr/bin/expr ${count} + 1`"
		done 
	else
		directory="`/bin/echo ${1} | /usr/bin/awk -F'/' 'NF{NF-=1};1' | /bin/sed 's/ /\//g'`"
		/bin/mkdir -p /tmp/${directory}
		/bin/touch /tmp/$1
    		count="0"
		while ( [ "`${datastore_tool} /tmp/$1 s3://${configbucket}/$2 2>&1 >/dev/null | /bin/grep "ERROR"`" != "" ] && [ "${count}" -lt "5" ] )
		do
          		/bin/echo "An error has occured `/usr/bin/expr ${count} + 1` times in script ${0}"
        		/bin/sleep 5
        		count="`/usr/bin/expr ${count} + 1`"
		done 
		/bin/rm /tmp/$1
	fi
fi
