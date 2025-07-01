SERVER_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"

if ( [ ! -d ${HOME}/credentials ] )
then
  /bin/mkdir -p ${HOME}/credentials
fi

/bin/echo "USERNAME:${SERVER_USER}" > ${HOME}/credentials/credentials.dat
/bin/echo "PASSWORD:${SERVER_USER_PASSWORD}" >> ${HOME}/credentials/credentials.dat
