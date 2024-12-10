

if (  [ -f ${HOME}/runtime/GENERATING_SNAPSHOT ] || [ ! -f ${HOME}/runtime/SNAPSHOT_BUILT ] || [ -f ${HOME}/runtime/AUTOSCALER_UPDATED_FOR_SNAPSHOT ] )
then
        exit
fi

${HOME}/providerscripts/utilities/UpdateInfrastructure.sh

/bin/touch ${HOME}/runtime/AUTOSCALER_UPDATED_FOR_SNAPSHOT
