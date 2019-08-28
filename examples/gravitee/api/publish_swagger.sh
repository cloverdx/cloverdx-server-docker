#!/bin/bash

set -e

#sudo apt-get install jq

MANAGEMENT_URL=http://virt-oberon:32105/management/apis

# CREATE API
curl -X POST -H "Authorization: Basic YWRtaW46YWRtaW4=" -H "Content-Type: application/json;charset=UTF-8" -d "@swagger_import.json" ${MANAGEMENT_URL}/import/swagger -o /tmp/create_api_resp.json
#curl -X POST -H "Authorization: Basic YWRtaW46YWRtaW4=" -H "Content-Type: application/json;charset=UTF-8" -d "@create_api.json" ${MANAGEMENT_URL} -o /tmp/create_api_resp.json

API_ID=`cat /tmp/create_api_resp.json | jq -r .id`

# CREATE PLAN
curl -X POST -H "Authorization: Basic YWRtaW46YWRtaW4=" -H "Content-Type:application/json;charset=UTF-8" -d "@create_plan.json" ${MANAGEMENT_URL}/${API_ID}/plans -o /tmp/create_plan_resp.json

PLAN_ID=`cat /tmp/create_plan_resp.json | jq -r .id`

# PUBLISH PLAN REQUEST
curl -X POST -H "Authorization: Basic YWRtaW46YWRtaW4=" -H "Content-Type:application/json;charset=UTF-8" ${MANAGEMENT_URL}/${API_ID}/plans/${PLAN_ID}/_publish

# DEPLOY API
curl -X POST -H "Authorization: Basic YWRtaW46YWRtaW4=" ${MANAGEMENT_URL}/${API_ID}/deploy

# START API
curl -X POST -H "Authorization: Basic YWRtaW46YWRtaW4=" ${MANAGEMENT_URL}/${API_ID}?action=START