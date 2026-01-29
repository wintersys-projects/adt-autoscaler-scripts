#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: When we find that there are updates to the filesystem of our current
# filesystem (additions or deletions) archives of those additions and deletions are written
# to the datastore which other machines in our webserver fleet can apply to their own
# filesystem keeping them up to date with us
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

exclude_list=`${HOME}/application/configuration/GetApplicationConfigFilename.sh`
machine_ip="`${HOME}/utilities/processing/GetIP.sh`"
WEBSITE_URL="`${HOME}/utilities/config/ExtractConfigValue.sh 'WEBSITEURL'`"

if ( [ "`${HOME}/utilities/config/CheckConfigValue.sh PERSISTASSETSTODATASTORE:1`" = "0" ] )
then
        exclude_list="${exclude_list} `/usr/bin/mount | /bin/grep -Eo "${target_directory}.* " | /usr/bin/awk '{print $1}' | /usr/bin/tr '\n' ' ' | /bin/sed 's;'${target_directory}'/;;g'`"
fi

exclude_command=""
if ( [ "${exclude_list}" != "" ] )
then
        /bin/echo "${exclude_list}" | /bin/tr ' ' '\n' | /bin/sed '/^$/d' | /bin/sed -e 's;^/;;' -e 's;^;/;' > ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/exclusion_list.dat
        exclude_command="--exclude-from ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/exclusion_list.dat"
fi

first_run="0"
if ( [ ! -d ${target_directory}1 ] )
then
        first_run="1"
fi

additions_command='cd '${target_directory}' ; /usr/bin/rsync -ri --dry-run --ignore-existing '${exclude_command}'  '${target_directory}'/ '${target_directory}'1/ | /usr/bin/cut -d" " -f2 | /bin/sed -e "s;^;\./;g" -e "/.*\/$/d" | /usr/bin/cpio -pdmvu '${target_directory}'1 2>&1 | /bin/grep "^/" | /bin/sed "s;'${target_directory}'1/;;g" | /usr/bin/tr " " "\\n"'
modifieds_command='cd '${target_directory}'1 ; /usr/bin/rsync -ri --dry-run --checksum '${exclude_command}' '${target_directory}'/ '${target_directory}'1/ | /usr/bin/cut -d" " -f2 | /bin/sed -e "s;^;\./;g" -e  "/.*\/$/d" | /usr/bin/cpio -pdmvu '${target_directory}'1 2>&1 | /bin/grep "^/" | /bin/sed "s;'${target_directory}'1/;;g" | /usr/bin/tr " " "\\n"'
additions=""
additions=`eval ${additions_command}`
modifieds=`eval ${modifieds_command}`
additions="${additions} ${modifieds}"

if ( [ "${first_run}" = "1" ] )
then
        exit
fi

/bin/touch ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.log

for file in ${additions}
do
        /bin/echo "${target_directory}/${file}" | /bin/sed 's:/\./:/:g' >> ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.log
        /bin/echo "${target_directory}1/${file}" | /bin/sed 's:/\./:/:g' >> ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.log
done 

if ( [ -s ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.log ] )
then
        /usr/bin/tar cfzp ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.tar.gz -T ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.log  --same-owner --same-permissions
fi

/bin/rm ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.log

deletes_command='/usr/bin/rsync --dry-run -vr '${exclude_command}' '${target_directory}'1/ '${target_directory}' 2>&1 | /bin/sed -e "/^$/d" -e  "/.*\/$/d" | /usr/bin/tail -n +2 | /usr/bin/head -n -2 | /usr/bin/tr " " "\\n" '
deletes=`eval ${deletes_command}`

for file in ${deletes}
do
        if ( [ -f ${target_directory}1/${file} ] )
        then
                /bin/echo "${target_directory}/${file}"  >> ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/deletions/deletions.${machine_ip}.$$.log
                /bin/echo "${target_directory}1/${file}" >> ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/deletions/deletions.${machine_ip}.$$.log
                /bin/rm ${target_directory}1/${file}
        fi
done

/usr/bin/find ${target_directory} -type d -empty -delete
/usr/bin/find ${target_directory}1 -type d -empty -delete

rnd="`/usr/bin/shuf -i1-10000 -n1`"

if ( [ -f ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.tar.gz ] )
then
        ${HOME}/providerscripts/datastore/operations/PutToDatastore.sh  "${bucket_type}" "${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.tar.gz" "filesystem-sync/${bucket_type}/additions" "distributed" "no" "${target_directory}"
        /bin/mv ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.tar.gz ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.${rnd}.tar.gz
        ${HOME}/providerscripts/datastore/operations/PutToDatastore.sh  "${bucket_type}"  "${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/additions/additions.${machine_ip}.$$.${rnd}.tar.gz" "filesystem-sync/${bucket_type}/historical/additions" "distributed" "no" "${target_directory}"
fi

if ( [ -f ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/deletions/deletions.${machine_ip}.$$.log ] )
then
        ${HOME}/providerscripts/datastore/operations/PutToDatastore.sh   "${bucket_type}"  "${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/deletions/deletions.${machine_ip}.$$.log" "filesystem-sync/${bucket_type}/deletions" "distributed" "no" "${target_directory}"
        /bin/mv ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/deletions/deletions.${machine_ip}.$$.log ${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/deletions/deletions.${machine_ip}.$$.${rnd}.log 
        ${HOME}/providerscripts/datastore/operations/PutToDatastore.sh   "${bucket_type}" "${HOME}/runtime/filesystem_sync/${bucket_type}/outgoing/deletions/deletions.${machine_ip}.$$.${rnd}.log" "filesystem-sync/${bucket_type}/historical/deletions" "distributed" "no" "${target_directory}"
fi
