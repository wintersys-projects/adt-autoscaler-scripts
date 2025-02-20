export HOME=`/bin/cat /home/homedir.dat`
WEBSITE_URL="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'WEBSITEURL'`"

SERVER_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"
TOKEN="`/bin/echo ${SERVER_USER} | /usr/bin/fold -w 4 | /usr/bin/head -n 1 | /usr/bin/tr '[:upper:]' '[:lower:]'`"

config_bucket="`/bin/echo "${WEBSITE_URL}"-config | /bin/sed 's/\./-/g'`-${TOKEN}"

inspected_file="${config_bucket}/${1}"

if ( [ "`${HOME}/providerscripts/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
  time_file_written="`/usr/bin/s3cmd info s3://${inspected_file}| /bin/grep "Last mod" | /usr/bin/awk -F',' '{print $2}'`"
elif ( [ "`${HOME}/providerscripts/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ]  )
then
  time_file_written="`/usr/bin/s5cmd ls s3://${inspected_file} | /usr/bin/awk '{print $1,$2}'`"
fi

time_file_written="`/usr/bin/date -d "${time_file_written}" +%s`"

time_now="`/usr/bin/date +%s`"
age_of_file_in_seconds="`/usr/bin/expr ${time_now} - ${time_file_written}`"
/bin/echo ${age_of_file_in_seconds}
