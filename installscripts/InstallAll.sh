#!/bin/sh


#Install the programs that we need to use when building the autoscaler
>&2 /bin/echo "${0} Installing software packages "
/bin/echo "${0} `/bin/date`: Installing Software packages" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} InstallFirewall.sh"
${HOME}/installscripts/InstallFirewall.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallCurl.sh"
${HOME}/installscripts/InstallCurl.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallSSHPass.sh"
${HOME}/installscripts/InstallSSHPass.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallBC.sh"
${HOME}/installscripts/InstallBC.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallJQ.sh"
${HOME}/installscripts/InstallJQ.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallSendEmail.sh"
${HOME}/installscripts/InstallSendEmail.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallLibioSocket.sh"
${HOME}/installscripts/InstallLibioSocket.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallLibnetSsleay.sh"
${HOME}/installscripts/InstallLibnetSsleay.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallSysStat.sh"
${HOME}/installscripts/InstallSysStat.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallRsync.sh"
${HOME}/installscripts/InstallRsync.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallCron.sh"
${HOME}/installscripts/InstallCron.sh ${BUILDOS}
>&2 /bin/echo "${0} Install Monitoring Gear"
${HOME}/installscripts/InstallMonitoringGear.sh
>&2 /bin/echo "${0} InstallGo.sh"
${HOME}/installscripts/InstallGo.sh ${BUILDOS}
>&2 /bin/echo "${0} Installing cloudtools"
/bin/echo "${0} `/bin/date`: Installing cloudtools" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
#Install the tools for our particular cloudhost provider
${HOME}/installscripts/InstallCloudhostTools.sh
>&2 /bin/echo "${0} Installing Datastore tools"
/bin/echo "${0} `/bin/date`: Installing Datastore tools" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
#Install the S3 compatible service we are using
. ${HOME}/installscripts/InstallDatastoreTools.sh
