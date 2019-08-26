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
NAMESPACE=cloverdx
DEPLOYMENT_NAME=cloverdx-example
SERVICE_NAME=cloverdx

echo "Deploying the example to Kubernetes"
# Create and expose the deployment as a service
cat cloverdx.yaml | envsubst '$DOCKER_REGISTRY' | kubectl apply -f -
echo "Waiting for CloverDX service startup"
kubectl wait --for=condition=available --timeout=120s --namespace=$NAMESPACE deployment/$DEPLOYMENT_NAME

kubectl apply -f cloverdx-monitoring.yaml
echo "Waiting for monitoring service startup"
kubectl wait --for=condition=available --timeout=60s --namespace=$NAMESPACE deployment/prometheus
kubectl wait --for=condition=available --timeout=60s --namespace=$NAMESPACE deployment/grafana

# Print service description
kubectl get services --namespace=$NAMESPACE

# Start port forwarding to localhost:8090
kubectl port-forward --namespace=$NAMESPACE svc/$SERVICE_NAME 8090:8080
