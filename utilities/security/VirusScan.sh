#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description: This script will scan your filesystem for viruses 
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

/usr/bin/clamscan --max-filesize=2000M --max-scansize=2000M --recursive=yes --infected / > ${HOME}/runtime/virus_report/latest.log

if ( [ "$?" != "0" ] )
then
  ${HOME}/providerscripts/email/SendEmail.sh "TROUBLE PERFORMING VIRUS SCAN" "Failed to perform virus scan correctly" "ERROR"
  exit
fi

${HOME}/providerscripts/email/SendEmail.sh "VIRUS SCAN REPORT FOR `/usr/bin/hostname`" "`/bin/cat ${HOME}/runtime/virus_report/latest.log`" "MANDATORY"
