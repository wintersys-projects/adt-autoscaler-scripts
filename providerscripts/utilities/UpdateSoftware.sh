set -x

BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"

for script in `/usr/bin/find ${HOME}/runtime/installedsoftware/ -name "*.sh" -print | /usr/bin/awk -F'/' '{print $NF}'`
do
        /bin/sh ${HOME}/installscripts/${script} ${BUILDOS}
done

/usr/sbin/shutdown -r now
