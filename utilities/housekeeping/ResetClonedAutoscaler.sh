HOME="`/bin/cat /home/homedir.dat`"
BUILDOS="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"


/bin/rm ${HOME}/runtime/FIREWALL-ACTIVE

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
  ${HOME}/utilities/processing/RunServiceCommand.sh "snapd.apparmor" restart
fi

${HOME}/installscripts/UpdateAndUpgrade.sh ${BUILDOS} &
