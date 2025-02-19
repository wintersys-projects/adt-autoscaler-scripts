



number_of_autoscalers="`${HOME}/providerscripts/server/NumberOfServers.sh "-as-" "${CLOUDHOST}"`"
number_of_webservers="${new_scale_value}"

/bin/echo "You are running ${number_autoscalers} and you are asking me to build ${new_scale_value} webservers"

base_number_of_webservers="`/usr/bin/expr ${number_of_webservers} / ${number_of_autoscalers}`"
total_base_number_of_webservers="`/usr/bin/expr ${base_number_of_webservers} \* ${number_of_autoscalers}`"
additional_number_of_webservers="`/usr/bin/expr ${number_of_webservers} - ${total_base_number_of_webservers}`"

new_scale_values="STATIC_SCALE"
for autoscaler_no in `printf "%d\n" $(seq 1 ${number_of_autoscalers})`
do
        if ( [ "${additional_number_of_webservers}" -gt "0" ] )
        then
                new_scale_values="${new_scale_values}:`/usr/bin/expr ${base_number_of_webservers} + 1`"
                additional_number_of_webservers="`/usr/bin/expr ${additional_number_of_webservers} - 1`"
        else
                new_scale_values="${new_scale_values}:${base_number_of_webservers}"
        fi
done

${BUILD_HOME}/providerscripts/datastore/configwrapper/MultiDeleteConfigDatastore.sh STATIC_SCALE:

if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:* ] )
then
        /bin/rm ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/STATIC_SCALE:*
fi

/bin/touch ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/${new_scale_values}
${BUILD_HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/${new_scale_values} ${new_scale_values}
