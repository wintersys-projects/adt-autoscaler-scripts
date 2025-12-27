#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description: This script will scan your filesystem for viruses this can help protect
# windows users in some circumstances
#######################################################################################
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
########################################################################################
########################################################################################
#set -x

/usr/bin/freshclam

if ( [ "$?" != "0" ] )
then
  ${HOME}/providerscripts/email/SendEmail.sh "TROUBLE UPDATING VIRUS DATABASE" "Failed to update the virus database successfully" "ERROR"
fi

if ( [ ! -d ${HOME}/runtime/virus_report ] )
then
  /bin/mkdir -p ${HOME}/runtime/virus_report
fi

if ( [ "`${HOME}/utilities/config/CheckBuildStyle.sh 'VIRUSSCANNER:clamav'`" = "1" ] )
then
  /usr/bin/clamscan --max-filesize=2000M --max-scansize=2000M --recursive=yes --infected /var /home /tmp > ${HOME}/runtime/virus_report/latest.log 2>/dev/null
fi

if ( [ ! -f ${HOME}/runtime/virus_report/latest.log ] || [ "`/usr/bin/find ${HOME}/runtime/virus_report/latest.log -cmin -5`" = "" ] )
then
        ${HOME}/providerscripts/email/SendEmail.sh "TROUBLE PERFORMING PRODUCING VIRUS SCAN REPORT" "Failed to perform virus scan correctly" "ERROR"
else
  message="`/bin/cat ${HOME}/runtime/virus_report/latest.log  | /bin/grep "Infected files"`"
  machine="`/usr/bin/hostname`"
  message="\n\n`/bin/cat ${HOME}/runtime/virus_report/latest.log`\n on machine ${machine}`"
        
  ${HOME}/providerscripts/email/SendEmail.sh "VIRUS SCAN REPORT FOR ${machine}" "${message}" "MANDATORY"
fi
