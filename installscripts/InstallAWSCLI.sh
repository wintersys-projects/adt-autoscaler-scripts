#!/bin/sh
###############################################################################################
# Description: This script will install AWS cli
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

    DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get  -o DPkg::Lock::Timeout=-1 -qq -y install unzip
    if ( [ ! -f /usr/local/src/aws ] )
    then
        /bin/mkdir /usr/local/src/aws
    fi
    cwd="`/usr/bin/pwd`"
    cd /usr/local/src/aws
    /usr/bin/curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    /usr/bin/unzip -o awscliv2.zip
    /bin/rm awscliv2.zip
    ./aws/install
    ./aws/install --update
    /bin/rm /usr/bin/aws
    /bin/ln -s /usr/local/bin/aws /usr/bin/aws
    cd ${cwd}
fi

if ( [ "${buildos}" = "debian" ] )
then
    DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get  -o DPkg::Lock::Timeout=-1 -qq -y install unzip
    if ( [ ! -f /usr/local/src/aws ] )
    then
        /bin/mkdir /usr/local/src/aws
    fi
    cwd="`/usr/bin/pwd`"
    cd /usr/local/src/aws
    /usr/bin/curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    /usr/bin/unzip -o awscliv2.zip
    /bin/rm awscliv2.zip
    ./aws/install
    ./aws/install --update
    /bin/rm /usr/bin/aws
    /bin/ln -s /usr/local/bin/aws /usr/bin/aws
    cd ${cwd}
fi
