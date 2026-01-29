#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: This is called from cron to initiate heavyweight syncing for the config
# directories that this toolkit relies on. 
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
if ( [ ! -d /var/lib/adt-config ] )
then
        /bin/mkdir /var/lib/adt-config
        ${HOME}/providerscripts/datastore/operations/SyncFromDatastore.sh "config" "root" "/var/lib/adt-config"

        while ( [ "`${HOME}/providerscripts/datastore/operations/ListFromDatastore.sh "config" "INSTALLED_SUCCESSFULLY"`" = "" ] )
        do
                /bin/sleep 1
        done

        ${HOME}/providerscripts/datastore/operations/SyncFromDatastore.sh "config" "root" "/var/lib/adt-config"
fi

while ( [ 1 ] )
do
  /bin/sleep 2 && ${HOME}/providerscripts/datastore/filesystems-sync/heavyweight/FileSystemsSyncingController.sh '2' '/var/lib/adt-config' 'config-sync' 
  /bin/sleep 15 && ${HOME}/providerscripts/datastore/filesystems-sync/heavyweight/FileSystemsSyncingController.sh '15' '/var/lib/adt-config' 'config-sync' 
  /bin/sleep 15 && ${HOME}/providerscripts/datastore/filesystems-sync/heavyweight/FileSystemsSyncingController.sh '30' '/var/lib/adt-config' 'config-sync' 
  /bin/sleep 15 && ${HOME}/providerscripts/datastore/filesystems-sync/heavyweight/FileSystemsSyncingController.sh '45' '/var/lib/adt-config' 'config-sync' 
done
