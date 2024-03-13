#!/bin/sh
###############################################################################################
# Description: This script will install python pip
# Author: Peter Winter
# Date: 12/01/2017
###############################################################################################
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
################################################################################################
################################################################################################

if ( [ "${1}" != "" ] )
then
    buildos="${1}"
fi

if ( [ "${buildos}" = "ubuntu" ] )
then
    DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install python3 
    DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install python3-pip
    DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install python3-magic

    if ( [ -f /usr/bin/python ] )
    then
        /bin/rm /usr/bin/python
    fi
    /bin/ln -s /usr/bin/python3 /usr/bin/python
    if ( [ -f /usr/bin/pip ] )
    then
        /bin/rm /usr/bin/pip
    fi
    /bin/ln /usr/bin/pip3 /usr/bin/pip
fi

if ( [ "${buildos}" = "debian" ] )
then
    DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install python3 
    DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install python3-pip
    DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y install python3-magic
    /bin/rm /usr/bin/python
    /bin/ln -s /usr/bin/python3 /usr/bin/python
    /bin/rm /usr/bin/pip
    /bin/ln /usr/bin/pip3 /usr/bin/pip
fi

