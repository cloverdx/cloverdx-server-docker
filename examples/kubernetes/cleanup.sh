#!/bin/bash

NAMESPACE=$1

if [ -z "$NAMESPACE" ]; then
  echo "Usage: $0 <namespace>"
  exit 1
fi

kubectl delete namespace $NAMESPACE --ignore-not-found
# Pod security policy is global - it is not a part of any namespace
kubectl delete podsecuritypolicy permissive-policy --ignore-not-found
