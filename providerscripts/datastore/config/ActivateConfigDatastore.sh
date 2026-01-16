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
				if ( [ -d /var/lib/adt-config ] )
                then
                	/usr/bin/find /var/lib/adt-config -type d -empty -delete
                fi
        done
}

monitor_for_datastore_changes &

/usr/bin/inotifywait -q -m -r -e modify,delete,create /var/lib/adt-config | while read DIRECTORY EVENT FILE 
do
	if ( [ -f ${DIRECTORY}${FILE} ] && [ "`/bin/echo ${FILE} | /bin/grep "^\."`" = "" ] )
	then
		case ${EVENT} in
			MODIFY*)
				if ( [ "`/bin/echo ${DIRECTORY}${FILE} | /bin/sed 's:/: :g' | /usr/bin/wc -w`" -gt "4" ] )
				then
					place_to_put="`/bin/echo ${DIRECTORY}${FILE} | /bin/sed 's:/[^/]*$::' | /bin/sed 's:/var/lib/adt-config/::g'`"
				else
					place_to_put="root"
				fi
				${HOME}/providerscripts/datastore/config/tooling/PutToConfigDatastore.sh ${DIRECTORY}${FILE} ${place_to_put}
				;;
			CREATE*)
				if ( [ "`/bin/echo ${DIRECTORY}${FILE} | /bin/sed 's:/: :g' | /usr/bin/wc -w`" -gt "4" ] )
				then
					place_to_put="`/bin/echo ${DIRECTORY}${FILE} | /bin/sed 's:/[^/]*$::' | /bin/sed 's:/var/lib/adt-config/::g'`"
				else
					place_to_put="root"
				fi
				${HOME}/providerscripts/datastore/config/tooling/PutToConfigDatastore.sh ${DIRECTORY}${FILE} ${place_to_put}
                ;;
			DELETE*)
                file_to_delete="`/bin/echo ${DIRECTORY}${FILE} | /bin/sed -e 's:/var/lib/adt-config/::' -e 's://:/:'`"
                ${HOME}/providerscripts/datastore/config/tooling/DeleteFromConfigDatastore.sh "${file_to_delete}" "no" "no"
				;;
		esac
	fi
done
