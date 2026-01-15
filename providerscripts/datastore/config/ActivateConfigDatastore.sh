if ( [ ! -d /var/lib/adt-config ] )
then
        /bin/mkdir /var/lib/adt-config
        ${HOME}/providerscripts/datastore/configwrapper/SyncFromConfigDatastoreWithoutDelete.sh "root" "/var/lib/adt-config"
fi

monitor_for_datastore_changes() {
while ( [ 1 ] )
do
        /bin/sleep 5
        /bin/touch /tmp/additions.lock
        ${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh /tmp/additions.lock "root"
        /bin/sleep 5
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh additions.lock
        if ( ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh additions.lock`" = "" ] )
        then
                ${HOME}/providerscripts/datastore/configwrapper/SyncFromConfigDatastoreWithoutDelete.sh "root" "/var/lib/adt-config"
        else
                : error message
        fi
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
                        if ( ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh additions.lock`" = "" ] )
                        then
                                /bin/sleep 1
                        fi
                        ${HOME}/providerscripts/datastore/configwrapper/SyncToConfigDatastoreWithoutDelete.sh "/var/lib/adt-config"
                        ;;
                CREATE*)
                        if ( ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh additions.lock`" = "" ] )
                        then
                                /bin/sleep 1
                        fi
                        ${HOME}/providerscripts/datastore/configwrapper/SyncToConfigDatastoreWithoutDelete.sh "/var/lib/adt-config"
                        ;;
                DELETE*)
                        # file_removed "$DIRECTORY" "$FILE"
                        if ( ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh additions.lock`" != "" ] )
                        then
                                /bin/sleep 1
                        fi
                        ${HOME}/providerscripts/datastore/configwrapper/SyncToConfigDatastoreWithDelete.sh "/var/lib/adt-config"  
                        ${HOME}/providerscripts/datastore/configwrapper/SyncFromConfigDatastoreWithDelete.sh "root" "/var/lib/adt-config"
                        ;;
        esac
done
