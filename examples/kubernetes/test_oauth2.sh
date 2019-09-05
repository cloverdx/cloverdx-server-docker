#!/bin/bash
TMP_FILE=/tmp/cloverdx_test_oauth2.json

# Show help for this script
script_help() {
   echo "Usage:"
   echo "$0 -u host -n namespace"
   echo ""
   echo "Example:"
   echo "$0 -u http://some-host -n developNS"
   echo ""
   echo "Options:"
   echo "-h, --help          show help"
   echo "-u, --host       URL host"
   echo "-n, --namespace    namespace"
}

# Parsing command-line arguments and flags 
while test $# -gt 0; do
  case "$1" in
    -h|--help)
	  script_help
      exit 0
      ;;
    -u|--host)
      shift
      if test $# -gt 0; then
        export HOST=$1
      else
        echo "no host specified"
        exit 1
      fi
      shift
      ;;
    -n|--namespace)
      shift
      if test $# -gt 0; then
        export NAMESPACE=$1
      else
        echo "no namespace specified"
        exit 1
      fi
      shift
      ;;  
    *)
	  script_help
      exit 1
      ;;
  esac
done

if [ -z $HOST ] || [ -z $NAMESPACE ]; then
	script_help
	exit 1
fi

API_PORT=`kubectl --namespace=$NAMESPACE get svc gravitee-gateway-svc -o go-template='{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}'`
AM_API_PORT=`kubectl --namespace=$NAMESPACE get svc gravitee-am-gateway-svc -o go-template='{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}'`
GATEWAY="${HOST}:${API_PORT}"
AM_GATEWAY="${HOST}:${AM_API_PORT}"

echo "##### Start testing  oAuth2 on API  gateway";
echo "API gateway: ${GATEWAY}"
echo "Access management gateway: ${AM_GATEWAY}"
echo ""
echo "### Call CloverDX Data Service without access token"
curl -v ${GATEWAY}/ds-oauth2
echo ""
echo ""
echo "### Obtain access token"
curl -v -X POST "${AM_GATEWAY}/cloverdx-domain/oauth/token?grant_type=client_credentials&client_id=THE-CLIENT-ID&client_secret=THE-CLIENT-SECRET" -o $TMP_FILE
echo ""
echo "### Client credential response"
cat $TMP_FILE
echo ""
echo ""
ACCESS_TOKEN=`cat ${TMP_FILE} | jq -r .access_token`
echo "### Access token: ${ACCESS_TOKEN}"
echo "### Call CloverDX Data Service with access token"
curl -v  ${GATEWAY}/ds-oauth2/echo/Success -H "Authorization: Bearer ${ACCESS_TOKEN}"
echo ""
echo ""
echo "### End testing  oAuth2";