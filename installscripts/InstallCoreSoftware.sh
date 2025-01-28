#!/bin/sh
if ( [ ! -d ${HOME}/runtime/installedsoftware ] )
then
  /bin/mkdir -p ${HOME}/runtime/installedsoftware
fi

BUILDOS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"

#>&2 /bin/echo "${0} UpdateAndUpgrade.sh"
#${HOME}/installscripts/UpdateAndUpgrade.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallNetworkManager.sh"
${HOME}/installscripts/InstallNetworkManager.sh ${BUILDOS} 
>&2 /bin/echo "${0} InstallFirewall.sh"
${HOME}/installscripts/InstallFirewall.sh ${BUILDOS} 
>&2 /bin/echo "${0} Installing Datastore tools"
${HOME}/installscripts/InstallDatastoreTools.sh ${BUILDOS}

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
${HOME}/installscripts/InstallCloudhostTools.sh 


