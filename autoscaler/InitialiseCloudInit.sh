CLOUDHOST="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
SERVER_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"
SERVER_USER_PASSWORD_HASHED="`/usr/bin/mkpasswd -m sha512crypt ${SERVER_USER_PASSWORD}`"
ALGORITHM="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'ALGORITHM'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
SSH_PUBLIC_KEY="`/bin/cat ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub`"
SSH_PRIVATE_KEY_TRIMMED="`/bin/cat ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} | /bin/grep -v '^----' | /usr/bin/tr -d '\n'`"
webserver_configuration_settings="`/bin/cat ${HOME}/runtime/webserver_configuration_settings.dat | /usr/bin/gzip -f | /usr/bin/base64 | /usr/bin/tr -d '\n'`"
build_styles_settings="`/bin/cat ${HOME}/runtime/buildstyles.dat  | /bin/grep -v "^#" | /usr/bin/gzip -f | /usr/bin/base64 | /usr/bin/tr -d '\n'`"
TIMEZONE_CONTINENT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh SERVER_TIMEZONE_CONTINENT`"
TIMEZONE_CITY="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh  SERVER_TIMEZONE_CITY`"
TIMEZONE="${TIMEZONE_CONTINENT}/${TIMEZONE_CITY}"
SSH_PORT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh  SSH_PORT`"

if ( [ ! -d ${HOME}/runtime/cloud-init ] )
then
        /bin/mkdir -p ${HOME}/runtime/cloud-init
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
        /bin/cp ${HOME}/providerscripts/server/cloud-init/linode.yaml ${HOME}/runtime/cloud-init/webserver.yaml
fi

git_provider_domain="github.com"

/bin/sed -i "s;XXXXSSH_PORTXXXX;${SSH_PORT};g" ${HOME}/runtime/cloud-init/webserver.yaml
/bin/sed -i "s;XXXXTIMEZONEXXXX;${TIMEZONE};g" ${HOME}/runtime/cloud-init/webserver.yaml
/bin/sed -i "s/XXXXALGORITHMXXXX/${ALGORITHM}/g" ${HOME}/runtime/cloud-init/webserver.yaml 
/bin/sed -i "s/XXXXSERVER_USERXXXX/${SERVER_USER}/g" ${HOME}/runtime/cloud-init/webserver.yaml 
/bin/sed -i "s;XXXXSERVER_USER_PASSWORDXXXX;${SERVER_USER_PASSWORD_HASHED};g" ${HOME}/runtime/cloud-init/webserver.yaml 
/bin/sed -i "s/XXXXBUILD_IDENTIFIERXXXX/${BUILD_IDENTIFIER}/g" ${HOME}/runtime/cloud-init/webserver.yaml 
/bin/sed -i "s/XXXXINFRASTRUCTURE_REPOSITORY_OWNERXXXX/${INFRASTRUCTURE_REPOSITORY_OWNER}/g" ${HOME}/runtime/cloud-init/webserver.yaml 
/bin/sed -i "s;XXXXSSH_PUBLIC_KEYXXXX;${SSH_PUBLIC_KEY};g" ${HOME}/runtime/cloud-init/webserver.yaml 
/bin/sed -i "s;XXXXSSH_PRIVATE_KEYXXXX;${SSH_PRIVATE_KEY_TRIMMED};g" ${HOME}/runtime/cloud-init/webserver.yaml 
/bin/sed -i "s;XXXXWEBSERVER_CONFIGURATIONXXXX;${webserver_configuration_settings};g" ${HOME}/runtime/cloud-init/webserver.yaml 
/bin/sed -i "s;XXXXBUILDSTYLES_SETTINGSXXXX;${build_styles_settings};g" ${HOME}/runtime/cloud-init/webserver.yaml 
/bin/sed -i "s/XXXXGIT_PROVIDER_DOMAINXXXX/${git_provider_domain}/g" ${HOME}/runtime/cloud-init/webserver.yaml 
