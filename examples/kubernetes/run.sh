#!/bin/bash

# Stop on error
set -e

# Defaults
KUBERNETES_HOST=$(kubectl get node --selector='node-role.kubernetes.io/master' -o jsonpath={.items[*].status.addresses[?\(@.type==\"Hostname\"\)].address})
NAMESPACE=cloverdx

# Show help for this script
script_help() {
  echo "Usage:"
  echo "$0 [options] my-docker-registry:5000"
  echo "Options:"
  echo "-?, --help            show help"
  echo "-h, --host            Kubernetes hostname (autodetect if not specified)"
  echo "-n, --namespace       Kubernetes namespace (\"cloverdx\" by default)"
  echo "-p, --port            port number to run the example (random if not specified)"
}

# Parsing command-line arguments and flags 
while test $# -gt 0; do
  case "$1" in
    '-?'|--help)
      script_help
      exit 0
      ;;
    -n|--namespace)
      shift
      if test $# -gt 0; then
        NAMESPACE=$1
      else
        echo "No Kubernetes namespace specified"
        exit 1
      fi
      shift
      ;;
    -h|--host)
      shift
      if test $# -gt 0; then
        KUBERNETES_HOST=$1
      else
        echo "No Kubernetes hostname specified"
        exit 1
      fi
      shift
      ;;
    -p|--port)
      shift
      if test $# -gt 0; then
        GRAVITEE_PORT=$1
      else
        echo "No port number specified"
        exit 1
      fi
      shift
      ;;
    *)
      DOCKER_REGISTRY=$1
      break
      ;;
  esac
done

# Test if DOCKER_REGISTRY is existing
if [ -z $DOCKER_REGISTRY ]; then
  echo "The Docker registry host argument is missing"
  script_help
  exit 1
fi

if [ -n "$GRAVITEE_PORT" ]; then
  GRAVITEE_GATEWAY_NODE_PORT="nodePort: $GRAVITEE_PORT"
  echo "Gravitee Gateway port: $GRAVITEE_PORT"
fi

export DOCKER_REGISTRY
export NAMESPACE
export KUBERNETES_HOST
export GRAVITEE_GATEWAY_NODE_PORT

echo "Using \"$KUBERNETES_HOST\" as the Kubernetes hostname"

echo "Downloading libraries"
GRADLE_WRAPPER=../../gradlew
# Download JDBC drivers
$GRADLE_WRAPPER -b ../../build.gradle
# Download JMX Exporter JAR
$GRADLE_WRAPPER :copyJmxExporter

# Build and push the base image
echo "Building the base image"
BASE_IMAGE_TAG=$DOCKER_REGISTRY/cloverdx-server:latest
docker build -t $BASE_IMAGE_TAG ../..
docker push $BASE_IMAGE_TAG

# Build and push the image containing the example
echo "Building the example"
EXAMPLE_TAG=$DOCKER_REGISTRY/cloverdx-kubernetes-example:latest
docker build --build-arg DOCKER_REGISTRY=$DOCKER_REGISTRY -t $EXAMPLE_TAG .
docker push $EXAMPLE_TAG

echo "Deploying the example to Kubernetes"

# Shorthand for specifying Kubernetes namespace
kubectl_ns() {
  kubectl --namespace $NAMESPACE "$@"
}

# Cleanup
./cleanup.sh $NAMESPACE

# Create namespace
kubectl create namespace $NAMESPACE

# Create and expose CloverDX Server as a service
cat cloverdx.yaml | envsubst '$DOCKER_REGISTRY' | kubectl_ns create -f -

echo "Create and expose monitoring";
# Pod security policy is global - it is not a part of any namespace
kubectl create -f cloverdx-pod-security-policy.yaml
# cAdvisor, Prometheus, Grafana
cat cloverdx-monitoring.yaml | envsubst '$NAMESPACE' | kubectl_ns create -f -

kubectl_ns create -f elasticsearch.yaml 
kubectl_ns create -f mongodb.yaml

# Gravitee
kubectl_ns create -f gravitee-management-api.yaml
kubectl_ns create -f gravitee-am-management-api.yaml
cat gravitee-gateway.yaml | envsubst '$GRAVITEE_GATEWAY_NODE_PORT' | kubectl_ns create -f -
kubectl_ns create -f gravitee-am-gateway.yaml
export MGMT_API_PORT=`kubectl_ns get svc gravitee-management-api-svc -o go-template='{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}'`
cat gravitee-management-ui.yaml | envsubst '$KUBERNETES_HOST $MGMT_API_PORT' | kubectl_ns create -f -
export MGMT_API_PORT=`kubectl_ns get svc gravitee-am-management-api-svc -o go-template='{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}'`
cat gravitee-am-management-ui.yaml | envsubst '$KUBERNETES_HOST $MGMT_API_PORT' | kubectl_ns create -f -

# Waiting for startup of various services
echo "Waiting for Grafana startup"
kubectl_ns wait --for=condition=available --timeout=150s deployment/grafana
echo "Waiting for Gravitee Access Management API startup"
kubectl_ns wait --for=condition=available --timeout=150s deployment/gravitee-am-management-api
echo "Waiting for Gravitee Management API startup"
kubectl_ns wait --for=condition=available --timeout=150s deployment/gravitee-management-api

# Run container initialization job
kubectl_ns create -f init-containers.yaml

echo "Waiting for Gravitee Gateway startup"
kubectl_ns wait --for=condition=available --timeout=150s deployment/gravitee-gateway

# Print service description
kubectl_ns get services

# Start port forwarding to localhost:8090
kubectl_ns port-forward svc/gravitee-gateway-svc 8090:8082
