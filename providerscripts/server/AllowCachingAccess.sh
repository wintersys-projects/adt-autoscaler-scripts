#!/bin/sh
###################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : If you use a managed in memory caching, then part of the security procedures
# might include a security group, so for our webservers to be able to access our
# caching we need to grant them access using their ip address.
###################################################################################
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
####################################################################################
####################################################################################
#set -x    

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "aws" ] )
then
    if ( [ "${INMEMORYCACHING_SECURITY_GROUP}" != "" ] )
    then
        /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${INMEMORYCACHING_SECURITY_GROUP} --protocol tcp --port ${INMEMORYCACHING_PORT} --cidr ${ip_to_deny}/32
    fi
fi
