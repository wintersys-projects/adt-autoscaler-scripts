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

S3_HOST_BASE="`${HOME}/utilities/config/ExtractConfigValue.sh 'S3HOSTBASE'`"
datastore_region="`/bin/echo "${S3_HOST_BASE}" | /bin/sed 's/|/ /g' | /usr/bin/awk '{print $1}' | /bin/sed -E 's/(.digitaloceanspaces.com|sos-|.exo.io|.linodeobjects.com|.vultrobjects.com)//g'`"

if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
        config_file="`/bin/grep -H ${datastore_region} /root/.s3cfg-* | /usr/bin/awk -F':' '{print $1}'`"
        datastore_tool="/usr/bin/s3cmd --config=${config_file} ls "
elif ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ]  )
then
        config_file="`/bin/grep -H ${datastore_region} /root/.s5cfg-* | /usr/bin/awk -F':' '{print $1}'`"
        host_base="`/bin/grep host_base ${config_file} | /bin/grep host_base | /usr/bin/awk -F'=' '{print  $NF}' | /bin/sed 's/ //g'`" 
        datastore_tool="/usr/bin/s5cmd --credentials-file ${config_file} --endpoint-url https://${host_base}  ls "
fi

if ( [ "${file_to_list}" = "" ] )
then
        ${datastore_tool} 2>/dev/null | /usr/bin/awk '{print $NF}' | /usr/bin/awk -F'/' '{print $NF}'
else
        ${datastore_tool} s3://${file_to_list} 2>/dev/null | /usr/bin/awk '{print $NF}' | /usr/bin/awk -F'/' '{print $NF}'
fi
