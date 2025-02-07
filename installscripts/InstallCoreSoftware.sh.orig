#!/bin/sh

#while ( [ ! -f /home/SOFTWARE_FOUNDATION_INSTALLED ] )
#do
#  /bin/sleep 1
#done

if ( [ ! -d ${HOME}/runtime/installedsoftware ] )
then
  /bin/mkdir -p ${HOME}/runtime/installedsoftware
fi

if ( [ "${1}" != "" ] )
then
    buildos="${1}"
fi

if ( [ "${buildos}" = "" ] )
then
    BUILDOS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
else 
    BUILDOS="${buildos}"
fi

#BUILDOS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"

#>&2 /bin/echo "${0} UpdateAndUpgrade.sh"
#${HOME}/installscripts/UpdateAndUpgrade.sh ${BUILDOS}

#/bin/sed -i "s/mirrors.linode.com/mirror.katapult.io/g" /etc/apt/sources.list
#/bin/sed -i "s/mirrors.digitalocean.com/mirror.katapult.io/g" /etc/apt/mirrors/debian.list

>&2 /bin/echo "${0} InitialUpdate.sh"
${HOME}/installscripts/InitialUpdate.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallNetworkManager.sh"
${HOME}/installscripts/InstallNetworkManager.sh  ${BUILDOS}
>&2 /bin/echo "${0} InstallFirewall.sh"
${HOME}/installscripts/InstallFirewall.sh ${BUILDOS}
>&2 /bin/echo "${0} Installing Datastore tools"
${HOME}/installscripts/InstallDatastoreTools.sh ${BUILDOS}

if ( [ ! -f /usr/bin/s3cmd ] && [ ! -f /usr/bin/s5cmd ] )
then
>&2 /bin/echo "${0} Failed to install essential datastore tooling, I have to exit"
  exit
fi

>&2 /bin/echo "${0} InstallJQ.sh"
${HOME}/installscripts/InstallJQ.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallGo.sh"
${HOME}/installscripts/InstallGo.sh ${BUILDOS} &
#>&2 /bin/echo "${0} InstallCurl.sh"
#${HOME}/installscripts/InstallCurl.sh ${BUILDOS} 
#>&2 /bin/echo "${0} InstallSSHPass.sh"
#${HOME}/installscripts/InstallSSHPass.sh ${BUILDOS} 
>&2 /bin/echo "${0} InstallBC.sh"
${HOME}/installscripts/InstallBC.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallEmailUtil.sh"
${HOME}/installscripts/InstallEmailUtil.sh ${BUILDOS}
#>&2 /bin/echo "${0} InstallLibioSocket.sh"
#${HOME}/installscripts/InstallLibioSocket.sh ${BUILDOS} 
#>&2 /bin/echo "${0} InstallLibnetSsleay.sh"
#${HOME}/installscripts/InstallLibnetSsleay.sh ${BUILDOS} 
#>&2 /bin/echo "${0} InstallSysStat.sh"
#${HOME}/installscripts/InstallSysStat.sh ${BUILDOS} 
>&2 /bin/echo "${0} InstallRsync.sh"
${HOME}/installscripts/InstallRsync.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallCron.sh"
${HOME}/installscripts/InstallCron.sh ${BUILDOS}
#>&2 /bin/echo "${0} Install Monitoring Gear"
#${HOME}/installscripts/InstallMonitoringGear.sh 
>&2 /bin/echo "${0} Installing cloudtools"
${HOME}/installscripts/InstallCloudhostTools.sh ${BUILDOS}


