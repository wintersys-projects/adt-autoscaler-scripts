#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: This is the lighweight way of syncing to filesystems. It is less resource
# heavy but it has some limitations meaning that if you dump a whole bunch of files into
# the filesystem you are syncing from then there will be lost events because inotifywait
# seems to drop some events in my testing if there is a burst of added or deleted files.
# That said, if you know that you are only going to be adding or deleting one or two files
# at a time then this can be used to sync directories via the datastore. 
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

active_directory="${1}"
bucket_type="${2}"

if ( [ ! -d ${active_directory} ] )
then
        /bin/mkdir ${active_directory}
        ${HOME}/providerscripts/datastore/operations/SyncFromDatastore.sh "${bucket_type}" "root" "${active_directory}"
fi

if ( [ ! -d ${HOME}/runtime/datastore_workarea/${bucket_type} ] )
then
        /bin/mkdir -p ${HOME}/runtime/datastore_workarea/${bucket_type}
else
        /bin/rm -r ${HOME}/runtime/datastore_workarea/${bucket_type}/*
fi

if ( [ ! -f ${HOME}/runtime/datastore_workarea/${bucket_type}/incoming_records_index.dat ] )
then
        /bin/echo "0" > ${HOME}/runtime/datastore_workarea/${bucket_type}/incoming_records_index.dat
fi

delete_marked_files()
{
        for deleted_file in `/usr/bin/find ${active_directory} | /bin/grep '\.delete_me$'`
        do
                marker_file="${deleted_file}"
                real_file="`/bin/echo ${marker_file} | /bin/sed 's:\.delete_me::g'`"

                if ( [ -f ${marker_file} ] )
                then
                        /bin/rm ${marker_file}
                fi

                if ( [ -f ${real_file} ] )
                then
                        /bin/touch ${real_file}.cleaningup
                fi

                if ( [ -f ${real_file} ] )
                then
                        /bin/rm ${real_file}
                fi

                if ( [ -f ${real_file}.cleaningup ] )
                then
                        /bin/rm ${real_file}.cleaningup 
                fi

                /bin/sleep 22

                datastore_marker_file="`/bin/echo ${marker_file} | /bin/sed -e "s:${active_directory}/::g"`"
                datastore_real_file="`/bin/echo ${real_file} | /bin/sed -e "s:${active_directory}/::g" -e 's/\.delete_me//g'`"
                ${HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "${bucket_type}" "${datastore_marker_file}" "local" 
                ${HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "${bucket_type}" "${datastore_real_file}" "local" 
        done
}

update_to_and_from_datastore()
{
        while ( [ 1 ] )
        do
                /bin/sleep 10
                if ( [ -f ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log ] )
                then
                        /usr/bin/uniq ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log  > ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log.$$
                        /bin/mv ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log.$$ ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log
                        total_no_records="`/usr/bin/wc -l ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log | /usr/bin/awk '{print $1}'`"
                        processed_no_records="`/bin/cat ${HOME}/runtime/datastore_workarea/${bucket_type}/incoming_records_index.dat`"
                        to_process_no_records="`/usr/bin/expr ${total_no_records} - ${processed_no_records}`"

                        if ( [ "${total_no_records}" != "${processed_no_records}" ] )
                        then
                                /usr/bin/head -${total_no_records} ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log  | /usr/bin/tail -${to_process_no_records} > ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log.$$
                                /bin/echo "${total_no_records}" > ${HOME}/runtime/datastore_workarea/${bucket_type}/incoming_records_index.dat

                                /bin/cat ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log.$$ | while read file_to_add place_to_put
                        do
                                ${HOME}/providerscripts/datastore/operations/PutToDatastore.sh "${bucket_type}" "${file_to_add}" "${place_to_put}" "local" "no"
                        done
                        fi

                        if ( [ -f ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log.$$ ] )
                        then
                                /bin/rm ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log.$$
                        fi
                fi

                ${HOME}/providerscripts/datastore/operations/SyncFromDatastore.sh "${bucket_type}" "root" "${active_directory}"

                if ( [ "`/usr/bin/find ${active_directory} | /bin/grep '\.delete_me$'`" != "" ] )
                then
                        delete_marked_files &
                fi

                if ( [ -d ${active_directory} ] )
                then
                        /usr/bin/find ${active_directory} -type d -empty -delete
                        /usr/bin/find ${active_directory} -type f -print0 | /usr/bin/xargs -0 chattr -i
                fi
        done
}

update_to_and_from_datastore &

/usr/bin/inotifywait -q -m -r -e delete,modify,create ${active_directory} | while read DIRECTORY EVENT FILE 
do          
        /bin/echo "${DIRECTORY}XXX${FILE}" >> /tmp/file_out

        if ( [ -f ${DIRECTORY}${FILE} ] && ( [ "`/bin/echo ${FILE} | /bin/grep "^\."`" = "" ] && [ "`/bin/echo ${FILE} | /bin/grep '\~$'`" = "" ] && [ "`/bin/echo ${FILE} | /bin/grep  -E '\.[a-z0-9]{8,}\.partial$'`" = "" ] && [ "`/bin/echo ${FILE} | /bin/grep  -E '[0-9]{9,}$'`" = "" ] && [ "`/bin/echo ${FILE} | /bin/grep  'cleaningup'`" = "" ] ) || [ "${EVENT}" = "DELETE" ]  )
        then
                case ${EVENT} in
                        MODIFY*)
                                file_for_processing="${DIRECTORY}${FILE}"
                                if ( [ "`/bin/echo ${file_for_processing} | /bin/fgrep -o '/' | /usr/bin/wc -l`" -gt "4" ] )
                                then
                                        place_to_put="`/bin/echo ${file_for_processing} | /bin/sed 's:/[^/]*$::' | /bin/sed "s:${active_directory}/::g"`"
                                else
                                        place_to_put="root"
                                fi

                                /usr/bin/chattr +i ${file_for_processing}
                                /bin/echo "${file_for_processing} ${place_to_put}" >> ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log
                                ;;
                        CREATE*)
                                file_for_processing="${DIRECTORY}${FILE}"
                                if ( [ "`/bin/echo ${file_for_processing} | /bin/fgrep -o '/' | /usr/bin/wc -l`" -gt "4" ] )
                                then
                                        place_to_put="`/bin/echo ${file_for_processing} | /bin/sed 's:/[^/]*$::' | /bin/sed "s:${active_directory}/::g"`"
                                else
                                        place_to_put="root"
                                fi
                                /bin/echo "${file_for_processing} ${place_to_put}" >> ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log
                                ;;
                        DELETE*)
                                file_for_processing="${DIRECTORY}${FILE}"
                                if ( [ ! -d ${file_for_processing} ]  && [ ! -f ${file_for_processing}.cleaningup ] )
                                then
                                        if ( [ "`/bin/echo ${file_for_processing} | /bin/fgrep -o '/' | /usr/bin/wc -l`" -gt "4" ] )
                                        then
                                                place_to_put="`/bin/echo ${file_for_processing} | /bin/sed 's:/[^/]*$::' | /bin/sed "s:${active_directory}/::g"`"
                                        else
                                                place_to_put="root"
                                        fi

                                        if ( [ ! -f ${file_for_processing}.delete_me ] && [ "`/bin/echo ${file_for_processing} | /bin/grep '\.delete_me'`" = "" ] )
                                        then
                                                if ( [ ! -d ${active_directory}/${place_to_put} ] )
                                                then
                                                        /bin/mkdir -p ${active_directory}/${place_to_put}
                                                fi
                                                /bin/touch ${file_for_processing}.delete_me
                                                /bin/echo "${file_for_processing}.delete_me ${place_to_put}" >> ${HOME}/runtime/datastore_workarea/${bucket_type}/additions_to_perform.log
                                        fi
                                fi
                                ;;
                esac
        fi
done
