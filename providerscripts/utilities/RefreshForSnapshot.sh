if ( [ ! -f ${HOME}/runtime/SNAPSHOT_BUILT ] || [ -f ${HOME}/runtime/AUTOSCALER_UPDATED_FOR_SNAPSHOT ] )
then
        exit
fi

${HOME}/providerscripts/utilities/software/UpdateSoftware.sh "SNAPPED"
/bin/touch ${HOME}/runtime/AUTOSCALER_UPDATED_FOR_SNAPSHOT
