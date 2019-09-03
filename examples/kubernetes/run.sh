#!/bin/bash

# Stop on error
set -e

export DOCKER_REGISTRY=$1
if [ -z $DOCKER_REGISTRY ]; then
	echo "Usage: $0 my-docker-registry:5000"
	exit 1
fi

# Build and push the base image
echo "Building the base image"
BASE_IMAGE_TAG=$DOCKER_REGISTRY/cloverdx-server:latest
docker build -t $BASE_IMAGE_TAG ../..
docker push $BASE_IMAGE_TAG

echo "Building the example"
# Build and push the image containing the example
EXAMPLE_TAG=$DOCKER_REGISTRY/cloverdx-kubernetes-example:latest
docker build --build-arg DOCKER_REGISTRY=$DOCKER_REGISTRY -t $EXAMPLE_TAG .
docker push $EXAMPLE_TAG

# Constants
NAMESPACE=filip
DEPLOYMENT_NAME=cloverdx-example
SERVICE_NAME=cloverdx

echo "Deploying the example to Kubernetes"

echo "Create namespace $NAMESPACE"
kubectl create namespace $NAMESPACE

# Create and expose the deployment as a service
cat cloverdx.yaml | envsubst '$DOCKER_REGISTRY' | kubectl apply --namespace=$NAMESPACE -f -

echo "Waiting for CloverDX service startup"
kubectl wait --for=condition=available --timeout=120s --namespace=$NAMESPACE deployment/$DEPLOYMENT_NAME

echo "Create and expose monitoring";
# kubectl apply -f cloverdx-monitoring.yaml --namespace=$NAMESPACE

echo "Waiting for monitoring service startup"
#kubectl wait --for=condition=available --timeout=60s --namespace=$NAMESPACE deployment/prometheus
#kubectl wait --for=condition=available --timeout=60s --namespace=$NAMESPACE deployment/grafana

kubectl create --namespace=$NAMESPACE -f elasticsearch.yaml 
kubectl create --namespace=$NAMESPACE -f mongodb.yaml

kubectl create --namespace=$NAMESPACE -f gravitee-gateway.yaml
kubectl create --namespace=$NAMESPACE -f gravitee-management-api.yaml
kubectl create --namespace=$NAMESPACE -f gravitee-management-ui.yaml

kubectl create --namespace=$NAMESPACE -f gravitee-am-gateway.yaml
kubectl create --namespace=$NAMESPACE -f gravitee-am-management-api.yaml
kubectl create --namespace=$NAMESPACE -f gravitee-am-management-ui.yaml

# Print service description
kubectl get services --namespace=$NAMESPACE

kubectl port-forward --namespace=$NAMESPACE svc/gravitee-management-api-svc 8083:8083 &

kubectl port-forward --namespace=$NAMESPACE svc/gravitee-am-management-api-svc 8093:8093 &

kubectl port-forward --namespace=$NAMESPACE svc/gravitee-am-management-ui-svc 81:81 &

# Start port forwarding to localhost:8090
kubectl port-forward --namespace=$NAMESPACE svc/$SERVICE_NAME 8090:8080
