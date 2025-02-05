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

SERVER_USER="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'SERVERUSER'`"

/usr/bin/find ${HOME} -type d -exec chmod 755 {} \;
/usr/bin/find ${HOME} -type f -exec chmod 640 {} \;
/usr/bin/find ${HOME} -name "*.sh" -type f -exec chmod ug+x {} \;
/usr/bin/find ${HOME} -type f -exec chown ${SERVER_USER}:root {} \;
/usr/bin/find ${HOME} -type d -exec chown ${SERVER_USER}:root {} \;
/bin/chmod 700 ${HOME}/.ssh
/bin/chmod 644 ${HOME}/.ssh/authorized_keys
/bin/chmod 600 ${HOME}/.ssh/id_*
/bin/chmod 644 ${HOME}/.ssh/id_*pub



#/bin/chmod -R 640 ${HOME}/.ssh/*
#/bin/chown -R ${SERVER_USER}:root ${HOME}/.ssh
#/bin/chmod 640 ${HOME}/super/Super.sh
#/bin/chown ${SERVER_USER}:root ${HOME}/super/Super.sh
#/bin/chmod -R 640 ${HOME}/runtime
#/bin/chown ${SERVER_USER}:root ${HOME}/runtime
#/bin/chmod 644 ${HOME}/runtime/AUTOSCALER_READY



