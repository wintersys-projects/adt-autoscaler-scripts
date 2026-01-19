#!/bin/sh
##########################################################################################################
# Description: This script will get a list of all ip addresses registered and active with the DNS provider
# If an IP address appears in this list that machine is basically considerded a "live" webserver
# This won't return IP addresses of machines that are merely "booted" and "ready" it will only apply IP
# addresses of machines that have been built and had their IP addresses added to the DNS provider
# The list of IP addresses that are returned are the IP addresses of machines that can be considered "live"
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

#If the toolkit isn't fully installed yet, we don't want to do anything
if ( [ "`${HOME}/providerscripts/datastore/config/toolkit/ListFromConfigDatastore.sh INSTALLED_SUCCESSFULLY`" = "" ] )
then
	exit
fi

WEBSITE_URL="`${HOME}/utilities/config/ExtractConfigValue.sh 'WEBSITEURL'`"
ALGORITHM="`${HOME}/utilities/config/ExtractConfigValue.sh 'ALGORITHM'`"
CLOUDHOST="`${HOME}/utilities/config/ExtractConfigValue.sh 'CLOUDHOST'`"
DNS_CHOICE="`${HOME}/utilities/config/ExtractConfigValue.sh 'DNSCHOICE'`"
DNS_SECURITY_KEY="`${HOME}/utilities/config/ExtractConfigValues.sh 'DNSSECURITYKEY' stripped | /bin/sed 's/ /:/g'`"
DNS_USERNAME="`${HOME}/utilities/config/ExtractConfigValue.sh 'DNSUSERNAME'`"

zonename="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
zoneid="`${HOME}/providerscripts/dns/GetZoneID.sh "${zonename}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"

dnsips=""
#Iterate across all the ip addresses registered with the dns provider
for ip in `${HOME}/providerscripts/dns/GetIPAddresses.sh "${zoneid}" "${WEBSITE_URL}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`
do
	dnsips=${dnsips}${ip}" "
done

dnsips="`/bin/echo ${dnsips} | /bin/sed 's/ $//g'`"

/bin/echo ${dnsips}
