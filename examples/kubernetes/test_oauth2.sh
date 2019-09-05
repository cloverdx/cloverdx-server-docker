#!/bin/bash
TMP_FILE=/tmp/cloverdx_test_oauth2.json

# Show help for this script
script_help() {
   echo "Usage:"
   echo "$0 [options] -g gateway.host -a am-gateway.host"
   echo "Options:"
   echo "-h, --help          show help"
   echo "-g, --gateway       gateway"
   echo "-a, --am-gateway    Access management gateway"
}

# Parsing command-line arguments and flags 
while test $# -gt 0; do
  case "$1" in
    -h|--help)
	  script_help
      exit 0
      ;;
    -g|--gateway)
      shift
      if test $# -gt 0; then
        export GATEWAY=$1
      else
        echo "no Gateway specified"
        exit 1
      fi
      shift
      ;;
    -a|--am-gateway)
      shift
      if test $# -gt 0; then
        export AM_GATEWAY=$1
      else
        echo "no Access Management Gateway specified"
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

if [ -z $GATEWAY ] || [ -z $AM_GATEWAY ]; then
	script_help
	exit 1
fi

echo "Test oAuth2";

echo "Call CloverDX Data Service withou access token"
curl -X GET http://${GATEWAY}/ds-oauth2

echo "Obtain access token"
curl -X POST  'http://${AM_GATEWAY}/cloverdx-domain/oauth/token?grant_type=client_credentials&client_id=THE-CLIENT-ID&client_secret=THE-CLIENT-SECRET' -o TMP_FILE
ACCESS_TOKEN=`cat ${TMP_FILE} | jq -r .access_token`

echo "Call CloverDX Data Service with access token"
curl -X GET http://${GATEWAY}/ds-oauth2 -H 'Authorization: Bearer ${ACCESS_TOKEN}'
