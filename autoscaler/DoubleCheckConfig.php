

if ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/configuration.php | /bin/grep -E 'HTTP*404'`" != "" ] )
then

fi
