#!/bin/sh
set -x

exec 1>/tmp/out
exec 2>/tmp/err

if ( [ ! -d /var/lib/adt-config ] )
then
        /bin/mkdir /var/lib/adt-config
fi

monitor_for_datastore_changes() {
        while ( [ 1 ] )
        do
                /bin/sleep 30
                ${HOME}/providerscripts/datastore/config/tooling/SyncFromConfigDatastoreWithDelete.sh "root" "/var/lib/adt-config"
        done
}

monitor_for_datastore_changes &

/usr/bin/inotifywait -q -m -r -e modify,delete,create /var/lib/adt-config | while read DIRECTORY EVENT FILE 
do
	if ( [ -f ${DIRECTORY}${FILE} ] )
	then
		case ${EVENT} in
			MODIFY*)
				if ( [ "`/bin/echo ${DIRECTORY}${FILE} | /bin/grep '/'`" != "" ] )
				then
					place_to_put="`/bin/echo ${DIRECTORY}${FILE} | /bin/sed 's:/[^/]*$::'`"
				else
					place_to_put="root"
				fi
				${HOME}/providerscripts/datastore/config/tooling/PutToConfigDatastore.sh ${DIRECTORY}${FILE} ${place_to_put}
				;;
			CREATE*)
				if ( [ "`/bin/echo ${DIRECTORY}${FILE} | /bin/grep '/'`" != "" ] )
				then
					place_to_put="`/bin/echo ${DIRECTORY}${FILE} | /bin/sed 's:/[^/]*$::'`"
				else
					place_to_put="root"
				fi
				${HOME}/providerscripts/datastore/config/tooling/PutToConfigDatastore.sh ${DIRECTORY}${FILE} ${place_to_put}
                ;;
			DELETE*)
				if ( [ ! -f ${DIRECTORY}${FILE} ] )
				then
					file_to_delete="`/bin/echo ${DIRECTORY}${FILE} | /bin/sed -e 's:/var/lib/adt-config/::' -e 's://:/:'`"
					${HOME}/providerscripts/datastore/config/tooling/DeleteFromConfigDatastore.sh "${file_to_delete}" "no" "no"
				fi
				;;
		esac
	fi
done
