#!/bin/sh
##########################################################################################################
# Description : This will configure cloud-init scripts for each new  webservers that
# you want to build. The result of this script is a valid cloud-init script with 
# live data ready to be passed to a VPS instance when it is provisioned using the CLI
# Author: Peter Winter
# Date: 12/01/2017
#########################################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# The Agile Deployment Toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with The Agile Deployment Toolkit.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################################################
#######################################################################################################
#set -x

CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
SERVER_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"
SERVER_USER_PASSWORD_HASHED="`/usr/bin/mkpasswd -m sha512crypt ${SERVER_USER_PASSWORD}`"
ALGORITHM="`${HOME}/utilities/config/ExtractConfigValue.sh 'ALGORITHM'`"
BUILD_IDENTIFIER="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${HOME}/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
INFRASTRUCTURE_REPOSITORY_PROVIDER="`${HOME}/utilities/config/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPROVIDER'`"
SSH_PUBLIC_KEY="`/bin/cat ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub`"
SSH_PRIVATE_KEY_TRIMMED="`/bin/cat ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} | /bin/grep -v '^----' | /usr/bin/tr -d '\n'`"
webserver_configuration_settings="`/bin/cat ${HOME}/runtime/webserver_configuration_settings.dat | /usr/bin/gzip -f | /usr/bin/base64 | /usr/bin/tr -d '\n'`"
build_styles_settings="`/bin/cat ${HOME}/runtime/buildstyles.dat  | /bin/grep -v "^#" | /usr/bin/gzip -f | /usr/bin/base64 | /usr/bin/tr -d '\n'`"
TIMEZONE_CONTINENT="`${HOME}/utilities/config/ExtractConfigValue.sh SERVERTIMEZONECONTINENT`"
TIMEZONE_CITY="`${HOME}/utilities/config/ExtractConfigValue.sh  SERVERTIMEZONECITY`"
BUILD_FROM_SNAPSHOT="`${HOME}/utilities/config/ExtractConfigValue.sh  BUILDFROMSNAPSHOT`"
TIMEZONE="${TIMEZONE_CONTINENT}/${TIMEZONE_CITY}"
SSH_PORT="`${HOME}/utilities/config/ExtractConfigValue.sh  SSHPORT`"

if ( [ ! -d ${HOME}/runtime/cloud-init ] )
then
	/bin/mkdir -p ${HOME}/runtime/cloud-init
fi

#Transfer the default cloud-init script to our working area so it can be filled with live data
if ( [ "${BUILD_FROM_SNAPSHOT}" = "1" ] )
then
	/bin/cp ${HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/webserver-by-snapshot.yaml ${HOME}/runtime/cloud-init/webserver.yaml
else
	/bin/cp ${HOME}/providerscripts/server/cloud-init/${CLOUDHOST}/webserver.yaml ${HOME}/runtime/cloud-init/webserver.yaml
fi

git_provider_domain="`${HOME}/providerscripts/git/GitProviderDomain.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER}`"

# Replace placholder tokens with live data that is needed for this build
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


#Activate the correct webserver by removing the block on it
WEBSERVER_CHOICE="`${HOME}/utilities/config/ExtractConfigValue.sh 'WEBSERVERCHOICE'`"
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

#Activate the relevant database client by removing the block on it
DATABASE_INSTALLATION_TYPE="`${HOME}/utilities/config/ExtractConfigValue.sh 'DATABASEINSTALLATIONTYPE'`"
DATABASE_DBaaS_INSTALLATION_TYPE="`${HOME}/utilities/config/ExtractConfigValue.sh 'DATABASEDBaaSINSTALLATIONTYPE'`"
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

#Activate the application language by removing the block on it being installed
APPLICATION_LANGUAGE="`${HOME}/utilities/config/ExtractConfigValue.sh 'APPLICATIONLANGUAGE'`"
PHP_VERSION="`${HOME}/utilities/config/ExtractConfigValue.sh 'PHPVERSION'`"
BUILDOS="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"

if ( [ "${APPLICATION_LANGUAGE}" = "PHP" ] )
then
	if ( [ "`/bin/grep ^PHP:cloud-init ${HOME}/runtime/buildstyles.dat`" != "" ] )
	then
		/bin/sed  -i 's/#XXXXPHPXXXX//g' ${HOME}/runtime/cloud-init/webserver.yaml
		/bin/sed  -i "s/XXXXPHP_VERSIONXXXX/${PHP_VERSION}/g" ${HOME}/runtime/cloud-init/webserver.yaml

		PHP_VERSION="`${HOME}/utilities/config/ExtractConfigValue.sh 'PHPVERSION'`"
		php_modules="`/bin/grep ^PHP ${HOME}/runtime/buildstyles.dat | /bin/sed 's/^PHP:cloud-init://g' | /usr/bin/awk -F'|' '{print $1}' | /bin/sed 's/:/ /g'`"
		php_module_list=""
		for php_module in ${php_modules}
		do
			php_modules_list="${php_modules_list} php${PHP_VERSION}-${php_module}"
		done
	fi
	/bin/sed -i "s/XXXXPHP_MODULESXXXX/${php_modules_list}/" ${HOME}/runtime/cloud-init/webserver.yaml
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		/bin/sed -i "s/#XXXXPHPUBUNTUXXXX//" ${HOME}/runtime/cloud-init/webserver.yaml
	fi
	if ( [ "${BUILDOS}" = "debian" ] )
	then
		/bin/sed -i "s/#XXXXPHPDEBIANXXXX//" ${HOME}/runtime/cloud-init/webserver.yaml
	fi
fi
