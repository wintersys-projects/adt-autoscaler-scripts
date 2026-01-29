#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: This script is the controller of our filesystems syncing process.
# There's three core phases
# 1. If historical filesystem updates from other machines need to be applied they are applied
# this will be the case for newly provisioned machines and machines that have been rebooted
# (and possibly missed updates whilst offline)
# 2. Any changes to the current server's filesystems are pushed out to the datastore so that
# other webservers can use those changes to update themselves to be up to date with us.
# 3. Any changes to other servers in our webserver fleet are obtained from the datastore
# and we apply to ourselves to keep ourselves up to date with them
# 4. Housekeeping - clean up any expired achives and so on. 
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

execution_order="${1}"
target_directory="${2}"
bucket_type="${3}"

WEBSITE_URL="`${HOME}/utilities/config/ExtractConfigValue.sh 'WEBSITEURL'`"

if ( [ "`${HOME}/providerscripts/datastore/config/wrapper/ListFromDatastore.sh "config" "INSTALLED_SUCCESSFULLY"`" = "" ] )
then
        exit
fi

historical="0"
if ( [ "`/bin/ls ${HOME}/runtime/filesystem_sync/PREVIOUSEXECUTIONTIME:*`" = "" ] )
then
        #We want to process historically if this is our first time (for example we are a brand new webserver booting up after a scaling event)
        historical="1"
else
        #if a webserver is offline for a while it might miss some updates so process historically
        previous="`/bin/ls ${HOME}/runtime/filesystem_sync/PREVIOUSEXECUTIONTIME:* | /usr/bin/awk -F':' '{print $NF}'`"
        current="`/usr/bin/date +%s`"
        time_since_last_run="`/usr/bin/expr ${current} - ${previous}`"

        if ( [ "${time_since_last_run}" -gt "60" ] )
        then
                historical="1"
        fi
        /bin/rm ${HOME}/runtime/filesystem_sync/PREVIOUSEXECUTIONTIME:*
fi

/bin/touch ${HOME}/runtime/filesystem_sync/PREVIOUSEXECUTIONTIME:`/usr/bin/date +%s`

#If a process has been running for a long time we don't want it blocking us
pids="`/bin/ps -A -o pid,cmd | /bin/grep "/filesystems-sync/"  | /bin/grep "${bucket_type}" | /bin/grep -v grep | /usr/bin/awk '{print $1}'`"
for pid in ${pids}
do
        minutes="`/bin/ps -o etime -p ${pid} | /usr/bin/tail -n +2 | /usr/bin/awk -F':' '{print $1}'`"
        if ( [ "${minutes}" != "" ] )
        then
                if ( [ ${minutes} -gt 5 ] )
                then
                        /usr/bin/kill -TERM ${pid}
                fi
        fi
done

if ( [ "`/bin/ls ${HOME}/runtime/filesystem_sync/DISABLE_EXECUTION-${bucket_type}:${execution_order} 2>/dev/null`" != "" ] )
then
        /usr/bin/find  ${HOME}/runtime/filesystem_sync/DISABLE_EXECUTION-${bucket_type}:${execution_order} -type f -mmin +5 -delete
fi

if ( [ "`/bin/ls ${HOME}/runtime/filesystem_sync/DISABLE_EXECUTION-${bucket_type}:* 2>/dev/null`" != "" ] )
then
        exit
else
        /bin/touch ${HOME}/runtime/filesystem_sync/DISABLE_EXECUTION-${bucket_type}:${execution_order}
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/deletions ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/deletions
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/${bucket_type}/incoming/additions ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/${bucket_type}/incoming/additions
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/${bucket_type}/incoming/deletions ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/${bucket_type}/incoming/deletions
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/${bucket_type}/incoming//additions/processed ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/${bucket_type}/incoming/additions/processed
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/${bucket_type}/incoming/deletions/processed ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/${bucket_type}/incoming/deletions/processed
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions/processed ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions/processed
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions/processed ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions/processed
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions/processed ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions/processed
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions/processed ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions/processed
fi

if ( [ ! -d ${HOME}/runtime/filesystem_sync/audit ] )
then
        /bin/mkdir -p ${HOME}/runtime/filesystem_sync/audit
fi

if ( [ "${historical}" = "1" ] )
then
 #       sync_bucket="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`-sync-tunnel`/bin/echo ${target_directory} | /bin/sed 's:/:-:g'`"
        ${HOME}/providerscripts/datastore/operations/MountDatastore.sh "${bucket_type}" "distributed" "`/bin/echo ${target_directory} | /bin/sed 's:/:-:g'`"
        if ( [ "`/usr/bin/hostname | /bin/grep 'init-1$'`" != "" ] )
        then
                ${HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "${bucket_type}" "*" "distributed" "`/bin/echo ${target_directory} | /bin/sed 's:/:-:g'`"
        fi
        ${HOME}/providerscripts/datastore/filesystems-sync/heavyweight/ProcessIncomingHistoricalWebrootUpdates.sh "${target_directory}" "${bucket_type}"
else
        ${HOME}/providerscripts/datastore/filesystems-sync/heavyweight/ProcessOutgoingWebrootUpdates.sh "${target_directory}" "${bucket_type}"
        ${HOME}/providerscripts/datastore/filesystems-sync/heavyweight/ProcessIncomingWebrootUpdates.sh "${target_directory}" "${bucket_type}"
fi


${HOME}/providerscripts/datastore/filesystems-sync/heavyweight/HousekeepAdditionsSyncing.sh "${target_directory}" "${bucket_type}"
${HOME}/providerscripts/datastore/filesystems-sync/heavyweight/HousekeepDeletionsSyncing.sh "${target_directory}" "${bucket_type}"

if ( [ -f ${HOME}/runtime/filesystem_sync/DISABLE_EXECUTION-${bucket_type}:${execution_order} ] )
then
        /bin/rm ${HOME}/runtime/filesystem_sync/DISABLE_EXECUTION-${bucket_type}:${execution_order}
fi
