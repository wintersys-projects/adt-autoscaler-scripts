#!/bin/sh
if ( [ ! -d ${HOME}/runtime/installedsoftware ] )
then
  /bin/mkdir -p ${HOME}/runtime/installedsoftware
fi

BUILDOS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"

>&2 /bin/echo "${0} UpdateAndUpgrade.sh"
${HOME}/installscripts/UpdateAndUpgrade.sh ${BUILDOS}

if ( [ "${1}" = "preinstall" ] )
then
  scripts="`/bin/cat ${HOME}/installscripts/InstallCoreSoftware.sh | /bin/grep BUILDOS | /bin/grep -v "Up.*" | /usr/bin/awk '{print $1}'`"
  
  package_names=""

  for script in ${scripts}
  do
        script="`/bin/echo ${script} | /bin/sed -e 's,\${HOME},'${HOME}',g'`"
        package_names="${package_names} `/bin/cat ${script} | /bin/grep DEBIAN_FRONTEND | /usr/bin/awk '{print $8}' | /usr/bin/sort -u | /usr/bin/uniq | /usr/bin/tr '\n' ' '`"
  done

  apt=""
  if ( [ "`${HOME}/providerscripts/utilities/config/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
  then
        apt="/usr/bin/apt-get"
  elif ( [ "`${HOME}/providerscripts/utilities/config/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt-fast" ] )
  then
        apt="/usr/sbin/apt-fast"
  fi

  if ( [ "${apt}" != "" ] )
  then
        if ( [ "${BUILDOS}" = "ubuntu" ] )
        then
                DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install ${package_names}
        fi
        if ( [ "${BUILDOS}" = "debian" ] )
        then
                DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1 -qq -y install ${package_names}
        fi
  fi
fi
#Install the programs that we need to use when building the autoscaler
>&2 /bin/echo "${0} Installing software packages "

>&2 /bin/echo "${0} InstallGo.sh"
${HOME}/installscripts/InstallGo.sh ${BUILDOS} 
>&2 /bin/echo "${0} InstallFirewall.sh"
${HOME}/installscripts/InstallFirewall.sh ${BUILDOS} 
>&2 /bin/echo "${0} InstallCurl.sh"
${HOME}/installscripts/InstallCurl.sh ${BUILDOS} 
>&2 /bin/echo "${0} InstallSSHPass.sh"
${HOME}/installscripts/InstallSSHPass.sh ${BUILDOS} 
>&2 /bin/echo "${0} InstallBC.sh"
${HOME}/installscripts/InstallBC.sh ${BUILDOS} 
>&2 /bin/echo "${0} InstallNetworkManager.sh"
${HOME}/installscripts/InstallNetworkManager.sh ${BUILDOS} 
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
>&2 /bin/echo "${0} Installing cloudtools"
#Install the tools for our particular cloudhost provider
${HOME}/installscripts/InstallCloudhostTools.sh 
>&2 /bin/echo "${0} Installing Datastore tools"
#Install the S3 compatible service we are using
${HOME}/installscripts/InstallDatastoreTools.sh ${BUILDOS}
pids="${pids} $!"

for pid in ${pids}
do
        wait ${pid}
done
