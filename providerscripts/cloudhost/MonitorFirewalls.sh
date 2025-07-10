BUILD_IDENTIFIER="test-gb-lon"
BUILD_IDENTIFIER="machine"

linode_ids=`/usr/local/bin/linode-cli --json linodes list | /usr/bin/jq -r '.[] | select (.label | contains ("adt-")) |  select (.label | endswith ("'-${BUILD_IDENTIFIER}'")).id'`

for linode_id in ${linode_ids}
do
        if ( [ "`/usr/local/bin/linode-cli --json --pretty firewalls list | /usr/bin/jq -r '.[].entities[].parent_entity.id'`" = "" ] )
        then
                /bin/echo "There seems to be a linode without a native firewall"
        fi
done
