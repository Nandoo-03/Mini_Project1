#!/bin/bash

echo "Contents of workspace:"
ls -la
echo "Applying Kubernetes manifests..."
kubectl apply -f ./kubernetes/deployment.yaml
kubectl apply -f ./kubernetes/service.yaml