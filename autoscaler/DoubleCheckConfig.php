

if ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/${headfile} | /bin/grep -E 'HTTP/2 200|HTTP/2 301|HTTP/2 302|HTTP/2 303|200 OK|302 Found|301 Moved Permanently'`" = "" ] )
