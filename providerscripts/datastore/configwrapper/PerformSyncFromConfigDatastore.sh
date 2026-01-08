set -x

${HOME}/providerscripts/datastore/configwrapper/SyncFromConfigDatastore.sh "" /var/lib/adt-config.$$

if ( [ -d /var/lib/adt-config ] )
then
        if ( [ -d /var/lib/adt-config.old ] )
        then
                /bin/rm -r /var/lib/adt-config.old
        fi
        /bin/mv /var/lib/adt-config /var/lib/adt-config.old
fi

/bin/mv /var/lib/adt-config.$$ /var/lib/adt-config
