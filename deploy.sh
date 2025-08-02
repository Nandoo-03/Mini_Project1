#!/bin/bash
kubectl apply -f /root/kubernetes/namespace.yaml
kubectl apply -f /root/kubernetes/deployment.yaml
kubectl apply -f /root/kubernetes/service.yaml
