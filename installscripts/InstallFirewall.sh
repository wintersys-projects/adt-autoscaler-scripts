if ( [ "${1}" != "" ] )
then
	buildos="${1}"
fi

firewall=""
if ( [ "`${HOME}/providerscripts/utilities/ExtractBuildStyleValues.sh "FIREWALL" | /usr/bin/awk -F':' '{print $NF}'`" = "ufw" ] )
then
	firewall="ufw"
elif ( [ "`${HOME}/providerscripts/utilities/ExtractBuildStyleValues.sh "FIREWALL" | /usr/bin/awk -F':' '{print $NF}'`" = "iptables" ] )
then
	firewall="iptables"
fi

if ( [ "${firewall}" = "ufw" ] )
then

elif ( [ "${firewaall}" = "iptables"
then

fi
