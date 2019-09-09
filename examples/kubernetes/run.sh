#!/bin/bash

# Show help for this script
script_help() {
   echo "Usage:"
   echo "$0 [options] my-docker-registry:5000"
   echo "Options:"
   echo "-?, --help            show help"
   echo "-h, --host            Kubernetes host"
   echo "-n, --namespace       Kubernetes namespace (optional, \"cloverdx\" by default)"
   echo "-p, --port            port number to run the example (optional, random if not specified)"
}

# Local variable
NAMESPACE=cloverdx

# Stop on error
set -e

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
        export NAMESPACE=$1
      else
        echo "The namespace not specified"
        exit 1
      fi
      shift
      ;;
    -h|--host)
      shift
      if test $# -gt 0; then
        export KUBERNETES_HOST=$1
      else
        echo "The kubernetes host not specified"
        exit 1
      fi
      shift
      ;;
    -p|--port)
      shift
      if test $# -gt 0; then
        GRAVITEE_PORT=$1
      else
        echo "no port number specified"
        exit 1
      fi
      shift
      ;;
    *)
      export DOCKER_REGISTRY=$1
      break
      ;;
  esac
done

# Test if DOCKER_REGISTRY is existing
if [ -z $DOCKER_REGISTRY ]; then
   echo "The docker registry host is empty"
   script_help
   exit 1
fi

# Test if Kubernetes host is existing
if [ -z $KUBERNETES_HOST ]; then
   echo "The kubernetes host is empty"
   script_help
   exit 1
fi

if [ -n "$GRAVITEE_PORT" ]; then
   GRAVITEE_GATEWAY_NODE_PORT="nodePort: ${GRAVITEE_PORT}"
   echo "Gravitee Gateway port: ${GRAVITEE_PORT}"
fi
export GRAVITEE_GATEWAY_NODE_PORT

# Prepare Prometheus JMX Agent JAR
../../gradlew -b ../../build.gradle :copyPrometheusJmxAgent

# Build and push the base image
echo "Building the base image"
# Download JDBC drivers
../../gradlew -b ../../build.gradle
BASE_IMAGE_TAG=$DOCKER_REGISTRY/cloverdx-server:latest
docker build -t $BASE_IMAGE_TAG ../..
docker push $BASE_IMAGE_TAG

echo "Building the example"
# Build and push the image containing the example
EXAMPLE_TAG=$DOCKER_REGISTRY/cloverdx-kubernetes-example:latest
docker build --build-arg DOCKER_REGISTRY=$DOCKER_REGISTRY -t $EXAMPLE_TAG .
docker push $EXAMPLE_TAG

echo "Deploying the example to Kubernetes"

# Cleanup
kubectl delete namespace $NAMESPACE --ignore-not-found
kubectl delete podsecuritypolicy cloverdx-cadvisor --ignore-not-found

# Create namespace
kubectl create namespace $NAMESPACE

# Create and expose the deployment as a service
cat cloverdx.yaml | envsubst '$DOCKER_REGISTRY' | kubectl create --namespace=$NAMESPACE -f -

echo "Create and expose monitoring";
kubectl create -f cloverdx-pod-security-policy.yaml
cat cloverdx-monitoring.yaml | envsubst '$NAMESPACE' | kubectl create --namespace=$NAMESPACE -f -

kubectl create --namespace=$NAMESPACE -f elasticsearch.yaml 
kubectl create --namespace=$NAMESPACE -f mongodb.yaml

kubectl create --namespace=$NAMESPACE -f gravitee-management-api.yaml
kubectl create --namespace=$NAMESPACE -f gravitee-am-management-api.yaml
cat gravitee-gateway.yaml | envsubst '$GRAVITEE_GATEWAY_NODE_PORT' | kubectl create --namespace=$NAMESPACE -f -
kubectl create --namespace=$NAMESPACE -f gravitee-am-gateway.yaml

export MGMT_API_PORT=`kubectl --namespace=$NAMESPACE get svc gravitee-management-api-svc -o go-template='{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}'`
echo "Gravitee Management API port: $MGMT_API_PORT"
cat gravitee-management-ui.yaml | envsubst '$KUBERNETES_HOST $MGMT_API_PORT' | kubectl apply --namespace=$NAMESPACE -f -

export MGMT_API_PORT=`kubectl --namespace=$NAMESPACE get svc gravitee-am-management-api-svc -o go-template='{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}'`
echo "Gravitee AM Management API port: $MGMT_API_PORT"
cat gravitee-am-management-ui.yaml | envsubst '$KUBERNETES_HOST $MGMT_API_PORT' | kubectl apply --namespace=$NAMESPACE -f -

echo "Waiting for Grafana startup"
kubectl wait --for=condition=available --timeout=150s --namespace=$NAMESPACE deployment/grafana
echo "Waiting for Gravitee Management API startup"
kubectl wait --for=condition=available --timeout=150s --namespace=$NAMESPACE deployment/gravitee-management-api
kubectl create --namespace=$NAMESPACE -f init-containers.yaml

echo "Waiting for Gravitee Gateway startup"
kubectl wait --for=condition=available --timeout=150s --namespace=$NAMESPACE deployment/gravitee-gateway

# Print service description
kubectl get services --namespace=$NAMESPACE

# Start port forwarding to localhost:8090
kubectl port-forward --namespace=$NAMESPACE svc/gravitee-gateway-svc 8090:8082
