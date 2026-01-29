#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: This abstracts the deleting of a file so that ultimate implementation is 
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
file_to_delete="${2}"
additional_specifier="${3}"

if ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "DATASTORECONFIGSTYLE" | /usr/bin/awk -F':' '{print $NF}'`" = "tool" ] )
then
	${HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "${bucket_type}" "${file_to_delete}" "local" "${additional_specifier}"
elif ( [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "DATASTORECONFIGSTYLE" | /usr/bin/awk -F':' '{print $NF}'`" = "lightweight" ] ||  [ "`${HOME}/utilities/config/ExtractBuildStyleValues.sh "DATASTORECONFIGSTYLE" | /usr/bin/awk -F':' '{print $NF}'`" = "heavyweight" ] )
then
	if ( [ -f /var/lib/adt-config/${file_to_delete} ] )
	then
		/bin/rm /var/lib/adt-config/${file_to_delete}
	fi
	if ( [ -d /var/lib/adt-config/${file_to_delete} ] )
	then
		if ( [ "${recursive}" = "yes" ] )
		then
			/bin/rm -r /var/lib/adt-config/${file_to_delete}
		else
			/bin/rmdir /var/lib/adt-config/${file_to_delete}
		fi
	fi
fi
