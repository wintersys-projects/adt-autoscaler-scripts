#!/bin/sh
if ( [ ! -d ${HOME}/runtime/installedsoftware ] )
then
  /bin/mkdir -p ${HOME}/runtime/installedsoftware
fi
#Install the programs that we need to use when building the autoscaler
>&2 /bin/echo "${0} Installing software packages "
/bin/echo "${0} `/bin/date`: Installing Software packages" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} UpdateAndUpgrade.sh"
${HOME}/installscripts/UpdateAndUpgrade.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallGo.sh"
${HOME}/installscripts/InstallGo.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallFirewall.sh"
${HOME}/installscripts/InstallFirewall.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallCurl.sh"
${HOME}/installscripts/InstallCurl.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallSSHPass.sh"
${HOME}/installscripts/InstallSSHPass.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallBC.sh"
${HOME}/installscripts/InstallBC.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallNetworkManager.sh"
${HOME}/installscripts/InstallNetworkManager.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallJQ.sh"
${HOME}/installscripts/InstallJQ.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallSendEmail.sh"
${HOME}/installscripts/InstallSendEmail.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallLibioSocket.sh"
${HOME}/installscripts/InstallLibioSocket.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallLibnetSsleay.sh"
${HOME}/installscripts/InstallLibnetSsleay.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallSysStat.sh"
${HOME}/installscripts/InstallSysStat.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallRsync.sh"
${HOME}/installscripts/InstallRsync.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} InstallCron.sh"
${HOME}/installscripts/InstallCron.sh ${BUILDOS} &
pids="${pids} $!"
>&2 /bin/echo "${0} Install Monitoring Gear"
${HOME}/installscripts/InstallMonitoringGear.sh &
pids="${pids} $!"
>&2 /bin/echo "${0} Installing cloudtools"
/bin/echo "${0} `/bin/date`: Installing cloudtools" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
#Install the tools for our particular cloudhost provider
${HOME}/installscripts/InstallCloudhostTools.sh &
pids="${pids} $!"
>&2 /bin/echo "${0} Installing Datastore tools"
/bin/echo "${0} `/bin/date`: Installing Datastore tools" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
#Install the S3 compatible service we are using
${HOME}/installscripts/InstallDatastoreTools.sh ${BUILDOS}
pids="${pids} $!"

for pid in ${pids}
do
        wait ${pid}
done
