#!/bin/sh
#set -x

if ( [ ! -d /var/lib/adt-config ] )
then
        /bin/mkdir /var/lib/adt-config
        ${HOME}/providerscripts/datastore/tooling/SyncFromConfigDatastore.sh "root" "/var/lib/adt-config"
fi

if ( [ ! -d /var/lib/adt-config1 ] )
then
        /bin/mkdir /var/lib/adt-config1
fi

if ( [ ! -d ${HOME}/runtime/datastore_workarea/config ] )
then
        /bin/mkdir -p ${HOME}/runtime/datastore_workarea/config
fi

if ( [ ! -d ${HOME}/runtime/datastore_workarea/config ] )
then
        /bin/mkdir -p ${HOME}/runtime/datastore_workarea/config
fi

if ( [ ! -d ${HOME}/runtime/datastore_workarea/config/audit ] )
then
        /bin/mkdir -p ${HOME}/runtime/datastore_workarea/config/audit
fi

monitor_for_datastore_changes() {

        if ( [ ! -d /var/lib/adt-config1 ] )
        then
                /bin/mkdir /var/lib/adt-config1
        fi

        /bin/echo "=============STARTING NEW AUDIT TRAIL" > ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
        /usr/bin/date >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
        /bin/echo "============STARTING NEW AUDIT TRAIL" >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log

        while ( [ 1 ] )
        do
                /bin/sleep 5
                
                if ( [ -f ${HOME}/runtime/datastore_workarea/config/newdeletes.log ] )
                then
                        /usr/bin/find ${HOME}/runtime/datastore_workarea/config/newdeletes.log -newermt '15 seconds ago' -delete
                fi
                
                if ( [ -f ${HOME}/runtime/datastore_workarea/config/newcreates.log ] )
                then
                        /usr/bin/find ${HOME}/runtime/datastore_workarea/config/newcreates.log -newermt '15 seconds ago' -delete
                fi
                
                /bin/touch ${HOME}/runtime/datastore_workarea/config/newdeletes.log
                /bin/touch ${HOME}/runtime/datastore_workarea/config/newcreates.log
                ${HOME}/providerscripts/datastore/tooling/SyncFromConfigDatastore.sh "root" "/var/lib/adt-config" "yes" > ${HOME}/runtime/datastore_workarea/config/updates.log
                if ( [ -f ${HOME}/runtime/datastore_workarea/config/updates.log ] )
                then
                        while IFS= read -r line 
                        do
                                if ( [ "`/bin/echo ${line} | /bin/grep "^download:"`" != "" ] )
                                then
                                        file_to_obtain="`/bin/echo ${line} | /usr/bin/awk -F"'" '{print $2}' | /usr/bin/cut -f4- -d'/' | /bin/sed 's://:/:g'`"
                                        place_to_put="`/bin/echo ${line} | /usr/bin/awk -F"'" '{print $4}'| /bin/sed 's/adt-config/adt-config1/'`"
                                        if ( [ ! -d /var/lib/adt-config1/${file_to_obtain} ] )
                                        then
                                                if ( [ "`/bin/grep ${file_to_obtain} ${HOME}/runtime/datastore_workarea/config/newdeletes.log`" = "" ] )
                                                then
                                                        if ( [ "`/bin/echo ${file_to_obtain} | /bin/grep '/'`" != "" ] )
                                                        then
                                                                place_to_put="`/bin/echo ${file_to_obtain} | /bin/sed 's:/[^/]*$::'`"
                                                                if ( [ ! -d /var/lib/adt-config/${place_to_put} ] )
                                                                then
                                                                        /bin/mkdir -p /var/lib/adt-config/${place_to_put}
                                                                fi
                                                        else
                                                                place_to_put=""
                                                        fi

                                                        /bin/echo "Getting file ${file_to_obtain} from S3 datastore and storing at /var/lib/adt-config1/${place_to_put} ready to be made a live change by rsync" >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
                                                        ${HOME}/providerscripts/datastore/tooling/GetFromConfigDatastore.sh ${file_to_obtain} /var/lib/adt-config1/${place_to_put}
                                                        if ( [ -f /var/lib/adt-config1/${file_to_obtain} ] )
                                                        then
                                                                /usr/bin/rsync -u --checksum /var/lib/adt-config1/${file_to_obtain} /var/lib/adt-config/${file_to_obtain}
                                                        fi
                                                fi
                                        fi
                                elif ( [ "`/bin/echo ${line} | /bin/grep "^delete:"`" != "" ] )
                                then
                                        file_to_delete="`/bin/echo ${line} | /usr/bin/awk -F"'" '{print $2}'`"
                                        if ( [ ! -d ${file_to_delete} ] )
                                        then
                                                place_to_put="`/bin/echo ${file_to_delete} | /bin/sed 's:/var/lib/adt-config/::' | /bin/sed 's:/[^/]*$::'`/"
                                                if ( [ "`/bin/echo ${place_to_put} | /bin/grep '/'`" = "" ] )
                                                then
                                                        place_to_put="root"
                                                fi
                                                if ( [ "`/bin/grep ${file_to_delete} ${HOME}/runtime/datastore_workarea/config/newcreates.log`" = "" ] )
                                                then
                                                        /bin/echo "Deleting file ${file_to_delete} from local file system which will cascade to remote machines" >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
                                                        /bin/rm ${file_to_delete}
                                                else 
                                                        /bin/echo "Delete of brand new file (${file_to_delete}) triggered by its absence in the datastore. Protecting it from deletion and adding it to the datastore  " >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
                                                        /bin/sed -i "\:${file_to_delete}:d" ${HOME}/runtime/datastore_workarea/config/updates.log
                                                        ${HOME}/providerscripts/datastore/tooling/PutToConfigDatastore.sh ${file_to_delete} ${place_to_put}
                                                fi
                                        fi
                                fi

                        done < "${HOME}/runtime/datastore_workarea/config/updates.log"

                        if ( [ -d /var/lib/adt-config ] )
                        then
                                /usr/bin/find /var/lib/adt-config -type d -empty -delete
                        fi
                        if ( [ -d /var/lib/adt-config1 ] )
                        then
                                /usr/bin/find /var/lib/adt-config1 -type d -empty -delete
                        fi
                fi
        done
}


monitor_for_datastore_changes &

file_removed() {
        live_dir="${1}"
        deleted_file="${2}"

        /bin/echo "${live_dir}${deleted_file}" >> ${HOME}/runtime/datastore_workarea/config/newdeletes.log
        /bin/sed -i "\:${live_dir}${deleted_file}:d" ${HOME}/runtime/datastore_workarea/config/newcreates.log

        check_dir="`/bin/echo ${live_dir} | /bin/sed 's/adt-config/adt-config1/g'`"

        if ( [ -f ${check_dir}/${deleted_file} ] )
        then
                /bin/rm ${check_dir}/${deleted_file}
        fi

        if ( [ -f ${live_dir}/${deleted_file} ] )
        then
                /bin/rm ${live_dir}/${deleted_file}
        fi

        file_to_delete="`/bin/echo ${live_dir}${deleted_file} | /bin/sed -e 's:/var/lib/adt-config/::' -e 's://:/:'`"
        ${HOME}/providerscripts/datastore/tooling/DeleteFromConfigDatastore.sh "${file_to_delete}" "no" "no"
        /bin/echo "Asynchronous DELETE completed for file ${live_dir}${deleted_file} on this server's local filesystem and removal from the datastore at ${file_to_delete}" >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
}

file_modified() {
        live_dir="${1}"
        modified_file="${2}"

        place_to_put="`/bin/echo ${live_dir} | /bin/sed 's:/var/lib/adt-config/::' | /bin/sed 's:/$::g'`"

        if ( [ "`/bin/echo ${modified_file} | /bin/grep '^\.'`" = "" ] )
        then
                if ( [ ! -d ${live_dir}${modified_file} ] )
                then
                        /bin/echo "${live_dir}${modified_file}" > ${HOME}/runtime/datastore_workarea/config/newcreates.log
                        check_dir="`/bin/echo ${live_dir} | /bin/sed 's/adt-config/adt-config1/g'`"

                        if ( [ ! -f ${check_dir}/${modified_file} ] ||  [ "`/usr/bin/diff ${live_dir}/${modified_file} ${check_dir}/${modified_file}`" != "" ] )
                        then
                                ${HOME}/providerscripts/datastore/tooling/PutToConfigDatastore.sh  ${live_dir}${modified_file} ${place_to_put}
                                /bin/echo "needed" >> monitor_log
                        else
                                if ( [ -f ${check_dir}/${modified_file} ] )
                                then
                                        /bin/rm ${check_dir}/${modified_file}
                                fi
                        fi
                fi
        fi
        /bin/echo "Asynchronous MODIFICATION completed for file ${live_dir}${modified_file} on this server's local filesystem and added to datastore at ${place_to_put}" >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
}

file_created() {
        live_dir="${1}"
        created_file="${2}"

        place_to_put="`/bin/echo ${live_dir} | /bin/sed 's:/var/lib/adt-config/::' | /bin/sed 's:/$::g'`"

        if ( [ "`/bin/echo ${created_file} | /bin/grep '^\.'`" = "" ] )
        then
                if ( [ ! -d ${live_dir}${created_file} ] )
                then
                        /bin/echo "${live_dir}${created_file}" > ${HOME}/runtime/datastore_workarea/config/newcreates.log
                        check_dir="`/bin/echo ${live_dir} | /bin/sed 's/adt-config/adt-config1/g'`"

                        if ( [ ! -f ${check_dir}/${created_file} ] ||  [ "`/usr/bin/diff ${live_dir}/${created_file} ${check_dir}/${created_file}`" != "" ] )
                        then
                                ${HOME}/providerscripts/datastore/tooling/PutToConfigDatastore.sh  ${live_dir}${created_file} ${place_to_put}
                                /bin/echo "needed" >> monitor_log
                        else
                                if ( [ -f ${check_dir}/${created_file} ] )
                                then
                                        /bin/rm ${check_dir}/${created_file}
                                fi
                        fi
                fi
        fi
        /bin/echo "Asynchronous CREATION completed for file ${live_dir}${created_file} on this server's local filesystem and added to datastore at ${place_to_put}" >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
}

/usr/bin/inotifywait -q -m -r -e modify,delete,create /var/lib/adt-config | while read DIRECTORY EVENT FILE 
do
        case $EVENT in
                MODIFY*)
                        file_modified "$DIRECTORY" "$FILE"
                        ;;
                CREATE*)
                        file_created "$DIRECTORY" "$FILE"
                        ;;
                DELETE*)
                        file_removed "$DIRECTORY" "$FILE"
                        ;;
        esac
done
