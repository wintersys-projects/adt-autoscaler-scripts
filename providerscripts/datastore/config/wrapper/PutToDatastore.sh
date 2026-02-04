#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: This abstracts the putting of a file so that ultimate implementation is 
# not known by the calling script
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
####################################################################################
####################################################################################
#set -x

bucket_type="${1}"
file_to_put="${2}"
place_to_put="${3}"
delete="${4}"
additional_specifier="${5}"

if ( [ "${place_to_put}" = "root" ] )
then
        place_to_put=""
fi

if ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "DATASTORECONFIGSTYLE" | /usr/bin/awk -F':' '{print $NF}'`" = "tool" ] )
then
        ${HOME}/providerscripts/datastore/operations/PutToDatastore.sh "${bucket_type}" "${file_to_put}" "${place_to_put}" "local" "${delete}" "${additional_specifier}"
elif ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "DATASTORECONFIGSTYLE" | /usr/bin/awk -F':' '{print $NF}'`" = "lightweight" ] ||  [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "DATASTORECONFIGSTYLE" | /usr/bin/awk -F':' '{print $NF}'`" = "heavyweight" ] )
then
        if ( [ ! -d /var/lib/adt-config/${place_to_put} ] )
        then
                /bin/mkdir -p /var/lib/adt-config/${place_to_put}
        fi
        
        if ( [ -f ${file_to_put} ] )
        then
                /bin/cp ${file_to_put} /var/lib/adt-config/${place_to_put}
        else
                if ( [ "${place_to_put}" != "" ] )
                then
                        /bin/echo "" > /var/lib/adt-config/${place_to_put}/${file_to_put}
                else
                        /bin/echo "" > /var/lib/adt-config/${file_to_put}
                fi
        fi
fi
