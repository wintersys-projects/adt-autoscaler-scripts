#!/bin/sh
######################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Sync one bucket to another
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

HOME="`/bin/cat /home/homedir.dat`"

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
	datastore_cmd="${datastore_tool} --config=/root/.s3cfg-${count} sync "
elif ( [ "`/bin/grep "^DATASTORETOOL:*" ${HOME}/runtime/buildstyles.dat | /bin/grep s5cmd`" != "" ] )
then
	host_base="`/bin/grep host_base /root/.s5cfg-${count} | /bin/grep host_base | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
	datastore_cmd="${datastore_tool} --credentials-file /root/.s5cfg-${count} --endpoint-url https://${host_base} sync "
fi

if ( [ -d ${original_object} ] || [ -f ${original_object} ] )
then
	${datastore_cmd} ${original_object} s3://${new_object} 2>/dev/null
elif ( [ -d ${new_object} ] || [ -f ${new_object} ] )
then
	${datastore_cmd} s3://${original_object} ${new_object} 2>/dev/null
else
	${datastore_cmd} s3://${original_object} s3://${new_object} 2>/dev/null
fi
