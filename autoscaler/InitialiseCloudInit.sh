#set -x

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
TIMEZONE_CONTINENT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh SERVERTIMEZONECONTINENT`"
TIMEZONE_CITY="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh  SERVERTIMEZONECITY`"
TIMEZONE="${TIMEZONE_CONTINENT}/${TIMEZONE_CITY}"
SSH_PORT="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh  SSHPORT`"

if ( [ ! -d ${HOME}/runtime/cloud-init ] )
then
        /bin/mkdir -p ${HOME}/runtime/cloud-init
fi

/bin/cp ${HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/webserver.yaml ${HOME}/runtime/cloud-init/webserver.yaml

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


WEBSERVER_CHOICE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'WEBSERVERCHOICE'`"

if ( [ "${WEBSERVER_CHOICE}" = "NGINX" ] )
then
        /bin/sed -i "s/#XXXXNGINXXXXX//g" ${HOME}/runtime/cloud-init/webserver.yaml 
fi

if ( [ "${WEBSERVER_CHOICE}" = "APACHE" ] )
then
        /bin/sed -i "s/#XXXXAPACHEXXXX//g" ${HOME}/runtime/cloud-init/webserver.yaml 
fi

if ( [ "${WEBSERVER_CHOICE}" = "LIGHTTPD" ] )
then
        /bin/sed -i "s/#XXXXLIGHTTPDXXXX//g" ${HOME}/runtime/cloud-init/webserver.yaml 
fi

DATABASE_INSTALLATION_TYPE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DATABASEINSTALLATIONTYPE'`"
DATABASE_DBaaS_INSTALLATION_TYPE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'DATABASEDBaaSINSTALLATIONTYPE'`"

if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Maria" ] )
then
        if ( [ "`/bin/grep ^MARIADB:cloud-init ${HOME}/runtime/buildstyles.dat`" != "" ] )
        then
                /bin/sed -i 's/#XXXXMARIADB_CLIENTXXXX//g' ${HOME}/runtime/cloud-init/webserver.yaml
        fi
fi

if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep 'MySQL'`" != "" ] )
then
        if ( [ "`/bin/grep ^MARIADB:cloud-init ${HOME}/runtime/buildstyles.dat`" != "" ] )
        then
                /bin/sed -i 's/#XXXXMARIADB_CLIENTXXXX//g' ${HOME}/runtime/cloud-init/webserver.yaml
        else
                /bin/sed -i 's/#XXXXMYSQL_CLIENTXXXX//g' ${HOME}/runtime/cloud-init/webserver.yaml
        fi
fi


if ( [ "${DATABASE_INSTALLATION_TYPE}" = "Postgres" ]  )
then
        if ( [ "`/bin/grep ^POSTGRES:cloud-init ${HOME}/runtime/buildstyles.dat`" != "" ] )
        then
                /bin/sed -i 's/#XXXXPOSTRGESQL_CLIENTXXXX//g' ${HOME}/runtime/cloud-init/webserver.yaml
        fi
fi

if ( [ "`/bin/echo ${DATABASE_DBaaS_INSTALLATION_TYPE} | /bin/grep 'Postgres'`" != "" ] )
then
        if ( [ "`/bin/grep ^POSTGRES:cloud-init ${HOME}/runtime/buildstyles.dat`" != "" ] )
        then
                /bin/sed -i 's/#XXXXPOSTGRES_CLIENTXXXX//g' ${HOME}/runtime/cloud-init/webserver.yaml
        fi
fi

APPLICATION_LANGUAGE="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'APPLICATIONLANGUAGE'`"
PHP_VERSION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'PHPVERSION'`"

if ( [ "${APPLICATION_LANGUAGE}" = "PHP" ] )
then
        if ( [ "`/bin/grep ^PHP:cloud-init ${HOME}/runtime/buildstyles.dat`" != "" ] )
        then
                /bin/sed  -i 's/#XXXXPHPXXXX//g' ${HOME}/runtime/cloud-init/webserver.yaml
                /bin/sed  -i "s/XXXXPHP_VERSIONXXXX/${PHP_VERSION}/g" ${HOME}/runtime/cloud-init/webserver.yaml
                
                PHP_VERSION="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'PHPVERSION'`"
                php_modules="`/bin/grep ^PHP ${HOME}/runtime/buildstyles.dat | /bin/sed 's/^PHP:cloud-init://g' | /usr/bin/awk -F'|' '{print $1}' | /bin/sed 's/:/ /g'`"
                php_module_list=""
                for php_module in ${php_modules}
                do
                        php_modules_list="${php_modules_list} php${PHP_VERSION}-${php_module}"
                done
        fi
        /bin/sed -i "s/XXXXPHP_MODULESXXXX/${php_modules_list}/" ${HOME}/runtime/cloud-init/webserver.yaml

fi
