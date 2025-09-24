#!/bin/sh
###############################################################################################
# Description: This script will set up your crontab for you
# Date: 28/01/2017
# Author: Peter Winter
###############################################################################################
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
#######################################################################################
#######################################################################################
#set -x

if ( [ -f /var/spool/cron/crontabs/root ] )
then
        /bin/rm /var/spool/cron/crontabs/root
fi

#Setup crontab

/bin/echo "MAILTO=''" > /var/spool/cron/crontabs/root
HOME="`/bin/cat /home/homedir.dat`"

#These scripts are set to run every minute
/bin/echo "*/1 * * * * export HOME="${HOME}" && /bin/sleep 30 && ${HOME}/utilities/processing/UpdateIPs.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOME}" && ${HOME}/cron/SetupFirewallFromCron.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOME}" && ${HOME}/utilities/housekeeping/RemoveExpiredLocks.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOME}" && ${HOME}/utilities/status/MonitorForOverload.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOME}" && ${HOME}/utilities/status/CheckNetworkManagerStatus.sh" >> /var/spool/cron/crontabs/root

MULTI_REGION="`${HOME}/utilities/config/ExtractConfigValue.sh 'MULTIREGION'`"

if ( [ "${MULTI_REGION}" = "1" ] )
then
	/bin/echo "*/1 * * * * export HOME="${HOME}" && ${HOME}/providerscripts/dbaas/TightenDBaaSFirewall.sh" >> /var/spool/cron/crontabs/root
fi

#These scripts are set to run every 5 minutes
/bin/echo "*/5 * * * * export HOME="${HOME}" && /bin/sleep 23 && ${HOME}/security/MonitorFirewall.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/5 * * * * export HOME="${HOME}" && ${HOME}/autoscaler/RecordNumberOfWebserversRunning.sh" >> /var/spool/cron/crontabs/root

#This script will run every 10 minutes
/bin/echo "*/10 * * * * export HOME="${HOME}" && ${HOME}/utilities/security/EnforcePermissions.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/10 * * * * export HOME="${HOME}" && ${HOME}/utilities/status/MonitorCron.sh" >> /var/spool/cron/crontabs/root

/bin/echo "@hourly export HOME="${HOME}" && ${HOME}/utilities/status/LoadMonitoring.sh" >> /var/spool/cron/crontabs/root


/bin/echo "22 4 * * *  export HOME="${HOME}" && ${HOME}/utilities/software/UpdateSoftware.sh" >> /var/spool/cron/crontabs/root

SERVER_TIMEZONE_CONTINENT="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERTIMEZONECONTINENT'`"
SERVER_TIMEZONE_CITY="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERTIMEZONECITY'`"
/bin/echo '@reboot export TZ="':${SERVER_TIMEZONE_CONTINENT}/${SERVER_TIMEZONE_CITY}'"' >> /var/spool/cron/crontabs/root

/bin/echo "@reboot export HOME="${HOME}" && ${HOME}/utilities/software/UpdateInfrastructure.sh" >>/var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME="${HOME}" && ${HOME}/utilities/housekeeping/RemoveExpiredLocks.sh reboot" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME="${HOME}" && ${HOME}/utilities/status/LoadMonitoring.sh 'reboot'" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME="${HOME}" && ${HOME}/utilities/status/CheckNetworkManagerStatus.sh" >> /var/spool/cron/crontabs/root

#If we are building for production, then these scripts are also installed in the crontab. If it's for development then they are not
#installed.
if ( [ "`${HOME}/utilities/config/CheckConfigValue.sh PRODUCTION:1`" = "1" ] )
then
	/bin/echo "*/2 * * * * export HOME="${HOME}" && ${HOME}/cron/PerformScalingFromCron.sh" >> /var/spool/cron/crontabs/root
	/bin/echo "*/3 * * * * export HOME="${HOME}" && ${HOME}/cron/DeadOrAliveFromCron.sh" >> /var/spool/cron/crontabs/root
	#/bin/echo "30 8 * * *  export HOME="${HOME}" && ${HOME}/utilities/processing/ScalingUpdateEvent.sh 5" >> /var/spool/cron/crontabs/root
	#/bin/echo "30 17 * * *  export HOME="${HOME}" && ${HOME}/utilities/processing/ScalingUpdateEvent.sh 3" >> /var/spool/cron/crontabs/root
fi

/bin/echo "30 3 * * *  export HOME="${HOME}" && ${HOME}/utilities/housekeeping/RemoveExpiredLogs.sh" >> /var/spool/cron/crontabs/root

#Install our new crontab
/usr/bin/crontab /var/spool/cron/crontabs/root

${HOME}/utilities/processing/RunServiceCommand.sh "cron" restart
