#!/bin/sh
set -x

exec 1>/tmp/out
exec 2>/tmp/err

if ( [ ! -d /var/lib/adt-config ] )
then
        /bin/mkdir /var/lib/adt-config
fi

if ( [ ! -d /var/lib/adt-config-workarea ] )
then
        /bin/mkdir /var/lib/adt-config-workarea
fi

monitor_for_datastore_changes() {
        while ( [ 1 ] )
        do
                /bin/sleep 5
                /bin/touch ${HOME}/runtime/DATASTORE_SYNC_ACTIVE
                /bin/sleep 1
                ${HOME}/providerscripts/datastore/config/tooling/SyncFromConfigDatastoreWithDelete.sh "root" "/var/lib/adt-config"
                /bin/rm ${HOME}/runtime/DATASTORE_SYNC_ACTIVE
        done
}

monitor_for_datastore_changes &

file_removed() {
        live_dir="${1}"
        deleted_file="${2}"

        while ( [ -f ${HOME}/runtime/DATASTORE_SYNC_ACTIVE ] )
        do
                /bin/sleep 1
        done

        if ( [ ! -f ${live_dir}${deleted_file} ] )
        then
                file_to_delete="`/bin/echo ${live_dir}${deleted_file} | /bin/sed -e 's:/var/lib/adt-config/::' -e 's://:/:'`"
                ${HOME}/providerscripts/datastore/config/tooling/DeleteFromConfigDatastore.sh "${file_to_delete}" "no" "no"
        fi
}

file_modified() {
        live_dir="${1}"
        modified_file="${2}"

        while ( [ -f ${HOME}/runtime/DATASTORE_SYNC_ACTIVE ] )
        do
                /bin/sleep 1
        done

        original_file="${live_dir}${modified_file}" 
        destination_file="`/bin/echo ${original_file} | /bin/sed 's:/adt-config/:/adt-config-workarea/:'`"
        if ( [ "`/bin/echo ${modified_file} | /bin/grep '/'`" != "" ] )
        then
                place_to_put="`/bin/echo ${modified_file} | /bin/sed 's:/[^/]*$::'`"
        fi
        
        if ( [ ! -d ${place_to_put} ] )
        then
                /bin/mkdir -p ${place_to_put}
        fi

        if ( [ -f ${original_file} ] && [ "`/bin/echo ${modified_file} | /usr/bin/grep "^\."`" = "" ] )
        then
                /bin/cp ${original_file} ${destination_file}
        elif ( [ -d ${original_file} ] )
        then
                /bin/cp -r ${original_file} ${destination_file}
        fi
}

file_created() {
        live_dir="${1}"
        created_file="${2}"

        while ( [ -f ${HOME}/runtime/DATASTORE_SYNC_ACTIVE ] )
        do
                /bin/sleep 1
        done

        original_file="${live_dir}${created_file}" 
        destination_file="`/bin/echo ${original_file} | /bin/sed 's:/adt-config/:/adt-config-workarea/:'`"
        if ( [ "`/bin/echo ${created_file} | /bin/grep '/'`" != "" ] )
        then
                place_to_put="`/bin/echo ${created_file} | /bin/sed 's:/[^/]*$::'`"
        fi
        
        if ( [ ! -d ${place_to_put} ] )
        then
                /bin/mkdir -p ${place_to_put}
        fi

        if ( [ -f ${original_file} ] && [ "`/bin/echo ${created_file} | /usr/bin/grep "^\."`" = "" ] )
        then
                /bin/cp ${original_file} ${destination_file}
        elif ( [ -d ${original_file} ] )
        then
                /bin/cp -r ${original_file} ${destination_file}
        fi
}

/usr/bin/inotifywait -q -m -r -e modify,delete,create /var/lib/adt-config | while read DIRECTORY EVENT FILE 
do
        case ${EVENT} in
                MODIFY*)
                        file_modified "${DIRECTORY}" "${FILE}"
                        ${HOME}/providerscripts/datastore/config/tooling/SyncToConfigDatastoreWithoutDelete.sh "/var/lib/adt-config-workarea" "root"
                        if ( [ ! -f ${DIRECTORY}${FILE} ] )
                        then
                                destination_file="${DIRECTORY}${FILE}" 
                                original_file="`/bin/echo ${lDIRECTORY}${FILE} | /bin/sed 's:/adt-config/:/adt-config-workarea/:'`"
                                /bin/cp ${destination_file} ${original_file} 
                        fi
                                
                        ;;
                CREATE*)
                        file_created "${DIRECTORY}" "${FILE}"
                        ${HOME}/providerscripts/datastore/config/tooling/SyncToConfigDatastoreWithoutDelete.sh "/var/lib/adt-config-workarea" "root"
                        if ( [ ! -f ${DIRECTORY}${FILE} ] )
                        then
                                destination_file="${DIRECTORY}${FILE}" 
                                original_file="`/bin/echo ${lDIRECTORY}${FILE} | /bin/sed 's:/adt-config/:/adt-config-workarea/:'`"
                                /bin/cp ${destination_file} ${original_file} 
                        fi
                        ;;
                DELETE*)
                        file_removed "${DIRECTORY}" "${FILE}"
                        ;;
        esac
done
