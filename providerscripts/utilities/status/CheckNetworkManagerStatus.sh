if ( [ "`${HOME}/providerscripts/utilities/processing/RunServiceCommand.sh NetworkManager status | /bin/grep "inactive"`" != "" ] )
then
        ${HOME}/providerscripts/utilities/processing/RunServiceCommand.sh NetworkManager start
fi
