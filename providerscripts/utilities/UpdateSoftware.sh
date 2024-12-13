set -x

BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"

if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh BUILDOS:ubuntu`" = "1" ] || [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh BUILDOS:debian`" = "1" ] )
then
	 ${HOME}/installscripts/UpdateAndUpgrade.sh ${BUILDOS}   
fi

for script in `/usr/bin/find ${HOME}/runtime/installedsoftware/ -name "*.sh" -print | /usr/bin/awk -F'/' '{print $NF}'`
do
        /bin/sh ${HOME}/installscripts/${script} ${BUILDOS}
done

 ${HOME}/providerscripts/utilities/UpdateInfrastructure.sh

if ( [ "${1}" != "SNAPPED" ] )
then
	/usr/sbin/shutdown -r now
fi

