#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Keep addition archives around for 5 minutes (300 seconds)
# and once these archives are more than 5 minutes old they can be deleted and the 
# historical copy will then become the authoritative archive.
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

target_directory="${1}"
bucket_type="${2}"

deletions="`${HOME}/providerscripts/datastore/operations/ListFromDatastore.sh "${bucket_type}" "filesystem-sync/${bucket_type}/deletions/*" "${target_directory}"`"

for deletion in ${deletions}
do
        if ( [ "`${HOME}/providerscripts/datastore/operations/AgeOfDatastoreFile.sh "${bucket_type}" "filesystem-sync/${bucket_type}/deletions/${deletion}" "${target_directory}"`" -gt "60" ] )
        then
                ${HOME}/providerscripts/datastore/operations/DeleteFromDatastore.sh "${bucket_type}" "filesystem-sync/${bucket_type}/deletions/${deletion}" "distributed" "${target_directory}"
        fi
done
