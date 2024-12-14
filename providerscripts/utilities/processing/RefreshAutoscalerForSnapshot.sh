
if ( [ -f ${HOME}/runtime/SNAPSHOT_BUILT ] )
then
        if ( [ "`/usr/bin/find ${HOME}/runtime/SNAPSHOT_BUILT -maxdepth 1 -mmin -10 -type f`" != "" ] )
        then
                exit
        fi
fi

if ( [ ! -f ${HOME}/runtime/SNAPSHOT_BUILT ] || [ -f ${HOME}/runtime/AUTOSCALER_UPDATED_FOR_SNAPSHOT ] )
then
        exit
fi

${HOME}/providerscripts/utilities/UpdateInfrastructure.sh

/bin/touch ${HOME}/runtime/AUTOSCALER_UPDATED_FOR_SNAPSHOT
