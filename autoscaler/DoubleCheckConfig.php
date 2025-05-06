



config_status="not ok"

if ( [ "`${HOME}/providerscripts/utilities/config/CheckConfigValue.sh APPLICATION:joomla`" = "1" ] )
then
	if ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/configuration.php | /bin/grep -E 'HTTP*404'`" != "" ] )
	then
		config_status="ok"
	fi	
	if ( [ "`${HOME}/providerscripts/utilities/config/CheckConfigValue.sh APPLICATION:wordpress`" = "1" ] )
	then
		if ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/wp-config.php | /bin/grep -E 'HTTP*404'`" != "" ] )
		then
			config_status="ok"
		fi	
	if ( [ "`${HOME}/providerscripts/utilities/config/CheckConfigValue.sh APPLICATION:drupal`" = "1" ] )
	then 
		if ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/sites/default/settings.php | /bin/grep -E 'HTTP*404'`" != "" ] )
		then
			config_status="ok"
		fi	
	fi
	if ( [ "`${HOME}/providerscripts/utilities/config/CheckConfigValue.sh APPLICATION:moodle`" = "1" ] )
	then
		if ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/moodle/config.php | /bin/grep -E 'HTTP*404'`" != "" ] )
		then
			config_status="ok"
		fi	
	fi
fi
/bin/echo "${config_status}"
