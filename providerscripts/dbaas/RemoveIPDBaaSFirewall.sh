
ip_address_to_remove="${1}"

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
	dbaas="`${HOME}/utilities/config/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
	cluster_name="`/bin/echo ${dbaas} | /usr/bin/awk '{print $8}'`"
	cluster_id="`/usr/local/bin/doctl database list -o json | /usr/bin/jq -r '.[] | select (.name == "'${cluster_name}'").id'`"

	if ( [ "${cluster_id}" != "" ] )
	then
        /usr/local/bin/doctldoctl databases firewalls remove ${cluster_id} --rule ip_addr:${ip_address_to_remove}
	fi
fi
