if ( [ ! -d /var/lib/adt-config ] )
then
        /bin/mkdir /var/lib/adt-config
        ${HOME}/providerscripts/datastore/configwrapper/SyncFromConfigDatastoreWithoutDelete.sh "root" "/var/lib/adt-config"
fi

monitor_for_datastore_changes() {
while ( [ 1 ] )
do
        /bin/sleep 5
        /bin/touch /tmp/lock
        ${HOME}/providerscripts/datastore/configwrapper/SyncFromConfigDatastoreWithoutDelete.sh "root" "/var/lib/adt-config"
        /bin/rm /tmp/lock
done
}

monitor_for_datastore_changes &


        /usr/bin/inotifywait -q -m -r -e modify,delete,create /var/lib/adt-config | while read DIRECTORY EVENT FILE 
do
        while ( [ -f /tmp/lock ] )
        do
                sleep 1
        done
        case $EVENT in
                MODIFY*)
                        # file_modified "$DIRECTORY" "$FILE"
                                while ( [ -f /tmp/lock1 ] )
        do
                sleep 1
        done
                        ${HOME}/providerscripts/datastore/configwrapper/SyncToConfigDatastoreWithoutDelete.sh "/var/lib/adt-config"
                        ;;
                CREATE*)
                        while ( [ -f /tmp/lock1 ] )
        do
                sleep 1
        done
                        # file_created "$DIRECTORY" "$FILE"
                        ${HOME}/providerscripts/datastore/configwrapper/SyncToConfigDatastoreWithoutDelete.sh "/var/lib/adt-config"
                        ;;
                DELETE*)
                        # file_removed "$DIRECTORY" "$FILE"
                        /bin/touch /tmp/lock1
                        ${HOME}/providerscripts/datastore/configwrapper/SyncToConfigDatastoreWithDelete.sh "/var/lib/adt-config"  
                        ${HOME}/providerscripts/datastore/configwrapper/SyncFromConfigDatastoreWithDelete.sh "root" "/var/lib/adt-config"
                        /bin/rm /tmp/lock1
                        ;;
        esac
done
