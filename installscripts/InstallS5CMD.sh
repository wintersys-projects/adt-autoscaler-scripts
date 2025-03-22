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

if ( [ "${1}" != "" ] )
then
	buildos="${1}"
fi

if ( [ "${buildos}" = "" ] )
then
	BUILDOS="`${HOME}/providerscripts/utilities/config/ExtractConfigValue.sh 'BUILDOS'`"
else 
	BUILDOS="${buildos}"
fi

if ( [ "`${HOME}/providerscripts/utilities/config/CheckBuildStyle.sh 'DATASTORETOOL:s5cmd'`" = "1" ] )
then
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		if ( [ -d /root/scratch ] )			
		then						
			/bin/rm -r /root/scratch/*		
		else						
			/bin/mkdir /root/scratch		
		fi						

		GOBIN=/root/scratch /usr/bin/go install github.com/peak/s5cmd/v2@latest                
    
		if ( [ -f /root/scratch/s5cmd ] )                                                      
		then                                                                                    
			/bin/mv /root/scratch/s5cmd /usr/bin/s5cmd                                     
		fi  											
    
		if ( [ -d /root/scratch ] )								
		then											
			/bin/rm -r /root/scratch							
		fi											
	fi	

	if ( [ "${BUILDOS}" = "debian" ] )
	then
		if ( [ -d /root/scratch ] )			
		then						
			/bin/rm -r /root/scratch/*		
		else						
			/bin/mkdir /root/scratch		
		fi						

		GOBIN=/root/scratch /usr/bin/go install github.com/peak/s5cmd/v2@latest               
  
  		if ( [ -f /root/scratch/s5cmd ] )                                                      
		then                                                                                  
			/bin/mv /root/scratch/s5cmd /usr/bin/s5cmd                                      
		fi 											

		if ( [ -d /root/scratch ] )								
		then											
			/bin/rm -r /root/scratch							
		fi 
	fi
	/bin/touch ${HOME}/runtime/installedsoftware/InstallS5CMD.sh				
fi 
