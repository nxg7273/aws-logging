#!/bin/bash
set -e

echo "=== Setting up AWS EKS Fargate Logging ==="

# Create namespace if it doesn't exist
echo "Creating aws-observability namespace..."
kubectl create namespace aws-observability || true

# Apply logging configuration
echo "Applying logging configuration..."
kubectl apply -f ../yaml/aws-logging-config.yaml

# Create test pod
echo "Deploying test pod..."
kubectl apply -f ../yaml/test-logs-pod.yaml

# Wait for pod to start
echo "Waiting for pod to start..."
sleep 30

# Check pod status
echo "Checking pod status..."
kubectl get pods -n test-app

# Verify logging configuration
echo "Verifying logging configuration..."
kubectl describe pod -n test-app test-log-pod | grep -A 5 Events

echo "Deployment complete. Run verify-logging.sh to check the setup."
