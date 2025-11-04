#!/bin/sh
#####################################################################################
# Author : Peter Winter
# Date   : 16/07/2016
# Description : List a repository - can be used as a check to see if a repository exists
#####################################################################################
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
#####################################################################################
#####################################################################################
#set -x

repository_provider="${1}"
repository_username="${2}"
repository_ownername="${3}"
repository_name="${4}"
repository_password="${5}"

authentication_token=""

if ( [ "${repository_token}" != "" ] )
then
        authentication_token=":${repository_token}"
fi


if ( [ "${repository_provider}" = "bitbucket" ] )
then
        /usr/bin/git ls-remote https://${repository_username}${authentication_token}@bitbucket.org/${repository_ownername}/${repository_name}.git | /bin/grep 'HEAD'
fi
if ( [ "${repository_provider}" = "github" ] )
then
        /usr/bin/git ls-remote https://${repository_username}${authentication_token}@github.com/${repository_ownername}/${repository_name}.git | /bin/grep 'HEAD'
fi
if ( [ "${repository_provider}" = "gitlab" ] )
then
        /usr/bin/git ls-remote https://${repository_username}${authentication_token}@gitlab.com/${repository_ownername}/${repository_name}.git | /bin/grep 'HEAD'
fi


