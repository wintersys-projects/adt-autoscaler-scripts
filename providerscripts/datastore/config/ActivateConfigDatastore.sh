#!/bin/sh
#set -x

exec 1>/tmp/out
exec 2>/tmp/err

if ( [ ! -d /var/lib/adt-config ] )
then
        /bin/mkdir /var/lib/adt-config
      #  ${HOME}/providerscripts/datastore/config/tooling/SyncFromConfigDatastoreWithDelete.sh "root" "/var/lib/adt-config"
fi

if ( [ ! -d /var/lib/adt-config1 ] )
then
        /bin/mkdir /var/lib/adt-config1
fi


monitor_for_datastore_changes() {


        while ( [ 1 ] )
        do
                /bin/sleep 5

                ${HOME}/providerscripts/datastore/config/tooling/SyncFromConfigDatastoreWithDelete.sh "root" "/var/lib/adt-config"

                if ( [ -d /var/lib/adt-config ] )
                then
                        /usr/bin/find /var/lib/adt-config -type d -empty -delete
                fi
                if ( [ -d /var/lib/adt-config1 ] )
                then
                        /usr/bin/find /var/lib/adt-config1 -type d -empty -delete
                fi

                

        done
}


monitor_for_datastore_changes &

file_removed() {
        live_dir="${1}"
        deleted_file="${2}"

        file_to_delete="`/bin/echo ${live_dir}${deleted_file} | /bin/sed -e 's:/var/lib/adt-config/::' -e 's://:/:'`"
        ${HOME}/providerscripts/datastore/config/tooling/DeleteFromConfigDatastore.sh "${file_to_delete}" "no" "no"
        /bin/echo "Asynchronous DELETE completed for file ${live_dir}${deleted_file} on this server's local filesystem and removal from the datastore at ${file_to_delete}" >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
}

file_modified() {
        live_dir="${1}"
        modified_file="${2}"

        /usr/bin/rsync  ${live_dir}${modified_file} `/bin/echo ${live_dir}${modified_file} | /bin/sed 's:/adt-config/:/adt-config1'`
        /bin/echo "Asynchronous MODIFICATION completed for file ${live_dir}${modified_file} on this server's local filesystem and added to datastore at ${place_to_put}" >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
}

file_created() {
        live_dir="${1}"
        created_file="${2}"

        /usr/bin/rsync  ${live_dir}${created_file} `/bin/echo ${live_dir}${created_file} | /bin/sed 's:/adt-config/:/adt-config1'`
        /bin/echo "Asynchronous CREATION completed for file ${live_dir}${created_file} on this server's local filesystem and added to datastore at ${place_to_put}" >> ${HOME}/runtime/datastore_workarea/config/audit/audit_trail.log
}

/usr/bin/inotifywait -q -m -r -e modify,delete,create /var/lib/adt-config | while read DIRECTORY EVENT FILE 
do
        case $EVENT in
                MODIFY*)
                        file_modified "$DIRECTORY" "$FILE"
                        ${HOME}/providerscripts/datastore/config/tooling/SyncToConfigDatastoreWithoutDelete.sh "/var/lib/adt-config1" "root"
                        ;;
                CREATE*)
                        file_created "$DIRECTORY" "$FILE"
                        ${HOME}/providerscripts/datastore/config/tooling/SyncToConfigDatastoreWithoutDelete.sh "/var/lib/adt-config1" "root"
                        ;;
                DELETE*)
                        file_removed "$DIRECTORY" "$FILE"
                        ;;
        esac
done
