/usr/bin/inotifywait -q -m -r -e modify,delete,create /var/lib/adt-config | while read DIRECTORY EVENT FILE 
do
        case $EVENT in
                MODIFY*)
                       # file_modified "$DIRECTORY" "$FILE"
                        ${HOME}/providerscripts/datastore/configwrapper/SyncToDatastoreWithoutDelete.sh "/var/lib/adt-config"
                        ;;
                CREATE*)
                       # file_created "$DIRECTORY" "$FILE"
                        ${HOME}/providerscripts/datastore/configwrapper/SyncToDatastoreWithoutDelete.sh "/var/lib/adt-config"
                        ;;
                DELETE*)
                       # file_removed "$DIRECTORY" "$FILE"
                        ${HOME}/providerscripts/datastore/configwrapper/SyncFromDatastoreWithDelete.sh "root" "/var/lib/adt-config" "yes" 

                        ;;
        esac
done
