#!/bin/sh
################################################################################
#Description: This makes sure that the config file for our new application has
#definitely been configured. Its a double check just to make sure
#Author: Peter Winter
#Date: 12/01/2024
#################################################################################
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
###############################################################################
###############################################################################
#set -x

private_ip="${1}"

config_status="not ok"

if ( [ "`${HOME}/utilities/config/CheckConfigValue.sh APPLICATION:joomla`" = "1" ] )
then
	if ( [ "`/usr/bin/curl -s -I --max-time 60 --insecure https://${private_ip}:443/configuration.php | /bin/grep -E 'HTTP*404'`" = "" ] )
	then
		config_status="ok"
	fi	
fi
if ( [ "`${HOME}/utilities/config/CheckConfigValue.sh APPLICATION:wordpress`" = "1" ] )
then
	if ( [ "`/usr/bin/curl -s -I --max-time 60 --insecure https://${private_ip}:443/wp-config.php | /bin/grep -E 'HTTP*404'`" = "" ] )
	then
		config_status="ok"
	fi	
fi
if ( [ "`${HOME}/utilities/config/CheckConfigValue.sh APPLICATION:drupal`" = "1" ] )
then 
	if ( [ "`/usr/bin/curl -s -I --max-time 60 --insecure https://${private_ip}:443/sites/default/settings.php | /bin/grep -E 'HTTP*404'`" = "" ] )
	then
		config_status="ok"
	fi	
fi
if ( [ "`${HOME}/utilities/config/CheckConfigValue.sh APPLICATION:moodle`" = "1" ] )
then
	if ( [ "`/usr/bin/curl -s -I --max-time 60 --insecure https://${private_ip}:443/config.php | /bin/grep -E 'HTTP*404'`" = "" ] )
	then
		config_status="ok"
	fi	
fi

/bin/echo "${config_status}"
