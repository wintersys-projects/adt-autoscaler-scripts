if ( [ -f ${HOME}/runtime/AUTOSCALER_READY ] && [ -f ${HOME}/runtime/SNAPSHOT_BUILT ] && [ ! -f ${HOME}/runtime/SNAPSHOT_PRIMED ] )
then
 	${HOME}/providerscripts/utilities/UpdateInfrastructure.sh
  /bin/touch ${HOME}/runtime/SNAPSHOT_PRIMED
fi
