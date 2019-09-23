#!/bin/sh

set -e
apk add curl
apk add jq

MANAGEMENT_URL=http://gravitee-management-api-svc:8083/management/apis
AUTHORIZATION='--user admin:admin'
AM_MANAGEMENT_URL=http://gravitee-am-management-api-svc:8093/management/domains
AM_AUTHORIZATION='--user admin:adminadmin'

function http_wait() {
	until curl --output /dev/null --silent --fail "$@"
	do
		echo '.'
		sleep 10
	done
}

function http_call {
	curl --silent --show-error -w '%{http_code} %{url_effective}\n' "$@"
}

function http_call_silent {
	http_call "$@" --output /dev/null
}

function echo_nl {
	echo -e "\r\n"
	echo "$@"
} 

echo_nl "Waiting for Gravitee Access Management API startup"
http_wait -X POST ${AM_AUTHORIZATION} http://gravitee-am-management-api-svc:8093/admin/token
echo "Gravitee Access Management API available at http://gravitee-am-management-api-svc:8093"

echo_nl "Creating CloverDX Domain in Gravitee Access Management"
ACCESS_TOKEN=`curl --silent -X POST ${AM_AUTHORIZATION} http://gravitee-am-management-api-svc:8093/admin/token | jq -r .access_token`
http_call_silent -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type:application/json;charset=UTF-8" -X POST -d '{"name":"CloverDX Domain","description":"CloverDX Security Domain"}' ${AM_MANAGEMENT_URL}
http_call_silent -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type:application/json;charset=UTF-8" -X PUT -d '{"enabled": true}' ${AM_MANAGEMENT_URL}/cloverdx-domain
CLIENT_ID=`curl --silent -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type:application/json;charset=UTF-8" -X POST -d '{"clientName":"cloverdx", "clientId":"THE-CLIENT-ID", "clientSecret":"THE-CLIENT-SECRET"}' ${AM_MANAGEMENT_URL}/cloverdx-domain/clients | jq -r .id`
http_call_silent -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type:application/json;charset=UTF-8" -X PUT -d '{"authorizedGrantTypes":["client_credentials"]}' ${AM_MANAGEMENT_URL}/cloverdx-domain/clients/${CLIENT_ID}

echo_nl "Waiting for Gravitee Gateway Management API startup"
http_wait ${AUTHORIZATION} --head ${MANAGEMENT_URL}
echo "Gravitee Gateway Management API available at ${MANAGEMENT_URL}"

for f in /config/*_api.json; do
	BASENAME=$(basename $f "_api.json")
	TITLE=`cat /config/${BASENAME}_api.json | jq -r .name`

	echo_nl "===== $TITLE ====="
	echo "Importing API from $f"

	# Create API
	http_call -X POST ${AUTHORIZATION} -H "Content-Type:application/json;charset=UTF-8" -d "@/config/${BASENAME}_api.json" ${MANAGEMENT_URL} -o /tmp/${BASENAME}_api_resp.json
	API_ID=`cat /tmp/${BASENAME}_api_resp.json | jq -r .id`
	echo
	echo "API ID: $API_ID"

	# Create plan for the API
	http_call -X POST ${AUTHORIZATION} -H "Content-Type:application/json;charset=UTF-8" -d "@/config/${BASENAME}_plan.json" ${MANAGEMENT_URL}/${API_ID}/plans -o /tmp/${BASENAME}_plan_resp.json
	PLAN_ID=`cat /tmp/${BASENAME}_plan_resp.json | jq -r .id`
	echo
	echo "Plan ID: $PLAN_ID"
	http_call_silent -X POST ${AUTHORIZATION} -H "Content-Type:application/json;charset=UTF-8" ${MANAGEMENT_URL}/${API_ID}/plans/${PLAN_ID}/_publish

	# Update the API (additional configuration, oAuth2 for example)
	if [ -f /config/${BASENAME}_update.json ]; then
		echo "Updating API ID: $API_ID"
		http_call_silent -X PUT ${AUTHORIZATION} -H "Content-Type:application/json;charset=UTF-8" -d "@/config/${BASENAME}_update.json" ${MANAGEMENT_URL}/${API_ID}
	fi

	# Deploy and start the API
	http_call_silent -X POST ${AUTHORIZATION} ${MANAGEMENT_URL}/${API_ID}/deploy
	http_call_silent -X POST ${AUTHORIZATION} ${MANAGEMENT_URL}/${API_ID}?action=START
done

GRAFANA_URL=http://grafana-svc:3000
echo_nl "Waiting for Grafana startup"
http_wait --head ${GRAFANA_URL}
echo "Grafana available at ${GRAFANA_URL}"

# Select default dashboard in Grafana
http_call_silent -X PUT -H "Content-Type: Content-Type: application/json" -d '{ "homeDashboardId": 2 }' ${GRAFANA_URL}/api/org/preferences

echo_nl "FINISHED"