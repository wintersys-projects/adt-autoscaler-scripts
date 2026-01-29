#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: When a new machine is deployed (as the result of an autoscaling event)
# then the existing machines might well have updated s and so when a new machine
# is built (or a machine has been offline for a period of time for some reason, a reboot
# maybe) then the current set of historical archives need to be applied to bring the 
# machines up to date with the other webservers in the fleet.
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

target_directory="${1}"
bucket_type="${2}"

machine_ip="`${HOME}/utilities/processing/GetIP.sh`"
additions_present="0"
deletions_present="0"

if ( [ "`${HOME}/providerscripts/datastore/operations/ListFromDatastore.sh "${bucket_type}" "filesystem-sync/${bucket_type}/historical/additions/" "${target_directory}"`" != "" ] )
then
        additions_present="1"
fi

if ( [ "`${HOME}/providerscripts/datastore/operations/ListFromDatastore.sh "${bucket_type}" "filesystem-sync/${bucket_type}/historical/deletions/" "${target_directory}"`" != "" ] )
then
        deletions_present="1"
fi

if ( [ "${additions_present}" = "1" ] )
then
        additions="`${HOME}/providerscripts/datastore/operations/ListFromDatastore.sh "${bucket_type}" "filesystem-sync/${bucket_type}/historical/additions/" "${target_directory}"`"
        for addition in ${additions}
        do
                ${HOME}/providerscripts/datastore/operations/GetFromDatastore.sh "${bucket_type}" "filesystem-sync/${bucket_type}/historical/additions/${addition}" "${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions"  "${target_directory}"
        done
fi

if ( [ "${deletions_present}" = "1" ] )
then
        deletions="`${HOME}/providerscripts/datastore/operations/ListFromDatastore.sh "${bucket_type}" "filesystem-sync/${bucket_type}/historical/deletions/" "${target_directory}"`"
        for deletion in ${deletions}
        do
                ${HOME}/providerscripts/datastore/operations/GetFromDatastore.sh "${bucket_type}" "filesystem-sync/${bucket_type}/historical/deletions/${deletion}" "${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions" "${target_directory}"
        done
fi

if ( [ "${deletions_present}" = "1" ] )
then
        archives="`/bin/ls -I processed ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions`"
        audit_header="not done"
        for archive in ${archives}
        do
                if ( [ "`/bin/echo ${archive} | /bin/grep "${machine_ip}"`" = "" ] && [ ! -f ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions/processed/${archive} ] )
                then
                        if ( [ "${audit_header}" = "not done" ] )
                        then
                                /bin/echo "======================================================================"  >> ${HOME}/runtime/filesystem_sync/audit/deletions.log
                                /bin/echo "FILES REMOVED THIS TIME  (`/usr/bin/date`)" >> ${HOME}/runtime/filesystem_sync/audit/deletions.log
                                /bin/echo "======================================================================"  >> ${HOME}/runtime/filesystem_sync/audit/deletions.log
                                /bin/echo "" >> ${HOME}/runtime/filesystem_sync/audit/deletions.log
                                audit_header="done"
                        fi
                        /bin/echo "" >> ${HOME}/runtime/filesystem_sync/audit/deletions.log
                        /bin/echo "Removed files from this machine's filesystem from archive: ${archive}" >> ${HOME}/runtime/filesystem_sync/audit/deletions.log
                        /bin/echo "" >> ${HOME}/runtime/filesystem_sync/audit/deletions.log
                        /bin/cat ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions/${archive} >> ${HOME}/runtime/filesystem_sync/audit/deletions.log

                        /usr/bin/xargs rm < ${HOME}/runtime/filesystem_sync/${bucket_type}/incoming/deletions/${archive}
                        if ( [ "$?" != "0" ] )
                        then
                                for file in `/bin/cat ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions/${archive}`
                                do
                                        /bin/rm ${file} 2>/dev/null
                                done
                        fi
                fi
                /bin/cp ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions/${archive} ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/deletions/processed/${archive}
        done
        /usr/bin/find ${target_directory} -type d -empty -delete
        /usr/bin/find ${target_directory}1 -type d -empty -delete
fi

if ( [ "${additions_present}" = "1" ] )
then
        archives="`/bin/ls -I processed ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions`"
        audit_header="not done"
        for archive in ${archives}
        do
                if ( [ "`/bin/echo ${archive} | /bin/grep "${machine_ip}"`" = "" ] &&  [ ! -f ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions/processed/${archive} ] )
                then
                        if ( [ "${audit_header}" = "not done" ] )
                        then
                                /bin/echo "======================================================================"  >> ${HOME}/runtime/filesystem_sync/audit/additions.log
                                /bin/echo "FILES ADDED THIS TIME  (`/usr/bin/date`)" >> ${HOME}/runtime/filesystem_sync/audit/additions.log
                                /bin/echo "======================================================================"  >> ${HOME}/runtime/filesystem_sync/audit/additions.log
                                /bin/echo "" >> ${HOME}/runtime/filesystem_sync/audit/additions.log
                                audit_header="done"
                        fi

                        /bin/echo "" >> ${HOME}/runtime/filesystem_sync/audit/additions.log
                        /bin/echo "Added files to this machine's filesystem from archive ${archive}" >> ${HOME}/runtime/filesystem_sync/audit/additions.log
                        /bin/echo "" >> ${HOME}/runtime/filesystem_sync/audit/additions.log
                        /bin/tar tvfz ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions/${archive}  | /bin/sed 's:^:^/:g' >> ${HOME}/runtime/filesystem_sync/audit/additions.log
                        /bin/tar xvfpz ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions/${archive} -C / --same-owner --same-permissions
                        root_dirs="`/bin/tar tvfpz ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions/${archive} | /usr/bin/awk -F'/' '{print $5}' | /usr/bin/uniq`"
                        for root_dir in ${root_dirs}
                        do
                                /bin/chown -R www-data:www-data ${target_directory}/${root_dir}
                                /bin/chown -R www-data:www-data ${target_directory}1/${root_dir}
                                /usr/bin/find ${target_directory}/${root_dir} -type d -exec chmod 755 {} + 
                                /usr/bin/find ${target_directory}1/${root_dir} -type d -exec chmod 755 {} + 
                                /usr/bin/find ${target_directory}/${root_dir} -type f -exec chmod 644 {} + 
                                /usr/bin/find ${target_directory}1/${root_dir} -type f -exec chmod 644 {} +  
                        done
                fi
                /bin/cp ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions/${archive} ${HOME}/runtime/filesystem_sync/${bucket_type}/historical/incoming/additions/processed/${archive}
        done
fi
