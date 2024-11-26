export HOME="`/bin/cat /home/homedir.dat`"

server_size="${1}"
server_name="`/bin/echo ${2} | /usr/bin/cut -c -32`"
snapshot_id="${3}"

cloudhost="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
build_identifier="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"

buildos="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
buildos_version="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOSVERSION'`"
region="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
ddos_protection="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ENABLEDDOSPROTECTION'`"
vpc_ip_range="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'VPCIPRANGE'`"
key_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'KEYID'`"

os_choice="`${HOME}/providerscripts/cloudhost/GetOperatingSystemVersion.sh ${cloudhost} ${buildos} ${buildos_version} | /bin/sed "s/'//g"`"
