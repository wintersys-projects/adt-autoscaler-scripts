#!/bin/sh
###################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Install the s3cmd tool for manipulating the Datastores
####################################################################################
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

BUILDOS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"

if ( [ "`${HOME}/providerscripts/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ] )
then
  if ( [ "${BUILDOS}" = "ubuntu" ] )
  then
    if ( [ -d /root/scratch ] )			#####UBUNTU-S5CMD-REPO#####
    then						#####UBUNTU-S5CMD-REPO#####
      /bin/rm -r /root/scratch/*		#####UBUNTU-S5CMD-REPO#####
    else						#####UBUNTU-S5CMD-REPO#####
      /bin/mkdir /root/scratch		#####UBUNTU-S5CMD-REPO#####
		fi						#####UBUNTU-S5CMD-REPO#####

    GOBIN=/root/scratch /usr/bin/go install github.com/peak/s5cmd/v2@latest                 #####UBUNTU-S5CMD-REPO#####
    if ( [ -f /root/scratch/s5cmd ] )                                                       #####UBUNTU-S5CMD-REPO#####
    then                                                                                    #####UBUNTU-S5CMD-REPO#####
      /bin/mv /root/scratch/s5cmd /usr/bin/s5cmd                                      #####UBUNTU-S5CMD-REPO#####
    fi  											#####UBUNTU-S5CMD-REPO#####
    if ( [ -d /root/scratch ] )								#####UBUNTU-S5CMD-REPO#####
    then											#####UBUNTU-S5CMD-REPO#####
      /bin/rm -r /root/scratch							#####UBUNTU-S5CMD-REPO#####
	 	fi											#####UBUNTU-S5CMD-REPO#####
 fi	

 if ( [ "${BUILDOS}" = "debian" ] )
 then
    if ( [ -d /root/scratch ] )			#####DEBIAN-S5CMD-REPO#####
		then						#####DEBIAN-S5CMD-REPO#####
      /bin/rm -r /root/scratch/*		#####DEBIAN-S5CMD-REPO#####
		else						#####DEBIAN-S5CMD-REPO#####
      /bin/mkdir /root/scratch		#####DEBIAN-S5CMD-REPO#####
		fi						#####DEBIAN-S5CMD-REPO#####

    GOBIN=/root/scratch /usr/bin/go install github.com/peak/s5cmd/v2@latest                 #####DEBIAN-S5CMD-REPO#####
    if ( [ -f /root/scratch/s5cmd ] )                                                       #####DEBIAN-S5CMD-REPO#####
    then                                                                                    #####DEBIAN-S5CMD-REPO#####
      /bin/mv /root/scratch/s5cmd /usr/bin/s5cmd                                      #####DEBIAN-S5CMD-REPO#####
    fi 											#####DEBIAN-S5CMD-REPO#####
    if ( [ -d /root/scratch ] )								#####DEBIAN-S5CMD-REPO#####
    then											#####DEBIAN-S5CMD-REPO#####
      /bin/rm -r /root/scratch							#####DEBIAN-S5CMD-REPO#####
    fi #####DEBIAN-S5CMD-REPO#####
  fi
  /bin/touch ${HOME}/runtime/installedsoftware/InstallS5CMD.sh				
fi 
