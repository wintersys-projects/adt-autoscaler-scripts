#!/bin/sh
######################################################################################################
# Description: This script will install clam av anti virus
# Author: Peter Winter
# Date: 17/01/2017
#######################################################################################################
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

if ( [ "${1}" != "" ] )
then
        buildos="${1}"
fi

if ( [ "${buildos}" = "" ] )
then
        BUILDOS="`${HOME}/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
else 
        BUILDOS="${buildos}"
fi
HOME="`/bin/cat /home/homedir.dat`"

apt=""
if ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
then
        apt="/usr/bin/apt"
elif ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt-get" ] )
then
        apt="/usr/bin/apt-get"
fi

export DEBIAN_FRONTEND=noninteractive
install_command="${apt} -o DPkg::Lock::Timeout=-1 -o Dpkg::Use-Pty=0 -qq -y install "

count="0"
while ( ( [ ! -x /usr/bin/freshclam ] || [ ! -x /usr/bin/clamscan ] ) && [ "${count}" = "5" ] )
do
        if ( [ "${apt}" != "" ] )
        then
                if ( [ "${BUILDOS}" = "ubuntu" ] )
                then
                        eval ${install_command} clamav clamav-daemon clamav-freshclam clamdscan
                fi

                if ( [ "${BUILDOS}" = "debian" ] )
                then
                        eval ${install_command} clamav clamav-daemon clamav-freshclam clamdscan
                fi
        fi
        count="`/usr/bin/expr ${count} + 1`"
done


if ( ( [ ! -x /usr/bin/freshclam ] || [ ! -x /usr/bin/clamscan ] ) && [ "${count}" = "5" ] )
then
        ${HOME}/providerscripts/email/SendEmail.sh "INSTALLATION ERROR ClamAV" "I believe that ClamAV hasn't installed correctly, please investigate" "ERROR"
else
        /bin/touch ${HOME}/runtime/installedsoftware/InstallClamAV.sh
fi

${HOME}/utilities/processing/RunServiceCommand.sh clamav-freshclam stop
/usr/bin/freshclam
