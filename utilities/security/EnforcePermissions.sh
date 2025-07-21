#!/bin/sh
##########################################################################################################################
# Description: This will keep the permissions tight of the most sensitive areas
# Author: Peter Winter
# Date: 12/01/2017
########################################################################################################################
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
#!/bin/sh

HOME="`/bin/cat /home/homedir.dat`"

SERVER_USER="`${HOME}/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"

/usr/bin/find ${HOME} -type d -exec chmod 755 {} \;
/usr/bin/find ${HOME} -type f -exec chmod 750 {} \;
/usr/bin/find ${HOME} -type f -exec chown ${SERVER_USER}:root {} \;
/usr/bin/find ${HOME} -type d -exec chown ${SERVER_USER}:root {} \;
/bin/chmod 700 ${HOME}/.ssh
/bin/chmod 600 ${HOME}/.ssh/authorized_keys
/bin/chmod 600 ${HOME}/.ssh/id_*
/bin/chmod 644 ${HOME}/.ssh/id_*pub

if ( [ -f ${HOME}/.bashrc ] )
then
	/bin/chmod 644 ${HOME}/.bashrc
	/bin/chown ${SERVER_USER}:root ${HOME}/.bashrc
fi

if ( [ -f ${HOME}/.ssh/autoscaler_configuration_settings.dat.gz ] )
then
	/bin/chown root:root ${HOME}/.ssh/autoscaler_configuration_settings.dat.gz
	/bin/chmod 660 ${HOME}/.ssh/autoscaler_configuration_settings.dat.gz
fi

if ( [ -f ${HOME}/.ssh/autoscaler_configuration_settings.dat ] )
then
	/bin/chown root:root ${HOME}/.ssh/autoscaler_configuration_settings.dat
	/bin/chmod 660 ${HOME}/.ssh/autoscaler_configuration_settings.dat
fi

if ( [ -f ${HOME}/.ssh/buildstyles.dat.gz ] )
then
	/bin/chown root:root ${HOME}/.ssh/buildstyles.dat.gz
	/bin/chmod 660 ${HOME}/.ssh/buildstyles.dat.gz
fi

if ( [ -f ${HOME}/.ssh/buildstyles.dat ] )
then
	/bin/chown root:root ${HOME}/.ssh/buildstyles.dat
	/bin/chmod 660 ${HOME}/.ssh/buildstyles.dat
fi

#If you want to harden the security of your system you  can change the ownerships of these files to root but you won't be able
#to "get rooted" using ${HOME}/super/Super.sh
if ( [ -f ${HOME}/runtime/autoscaler_configuration_settings.dat ] )
then
	#/bin/chown root:root ${HOME}/runtime/autoscaler_configuration_settings.dat
	/bin/chmod 660 ${HOME}/runtime/autoscaler_configuration_settings.dat
fi

if ( [ -f ${HOME}/runtime/buildstyles.dat ] )
then
	#/bin/chown root:root ${HOME}/runtime/buildstyles.dat
	/bin/chmod 660 ${HOME}/runtime/buildstyles.dat
fi





