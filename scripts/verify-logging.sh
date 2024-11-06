#!/bin/bash
set -e

echo "=== Verifying AWS EKS Fargate Logging Setup ==="

echo "=== Checking Pod Status ==="
kubectl get pods -n test-app

echo -e "\n=== Checking Pod Events ==="
kubectl describe pod -n test-app test-log-pod

echo -e "\n=== Checking Pod Logs ==="
kubectl logs -n test-app test-log-pod --tail=10

echo -e "\n=== Checking CloudWatch Log Streams ==="
aws logs describe-log-streams \
    --log-group-name "/aws/eks/protein-engineering-cluster-new/test-app" \
    --order-by LastEventTime \
    --descending \
    --limit 5

echo -e "\n=== Getting Recent CloudWatch Logs ==="
LATEST_STREAM=$(aws logs describe-log-streams \
    --log-group-name "/aws/eks/protein-engineering-cluster-new/test-app" \
    --order-by LastEventTime \
    --descending \
    --limit 1 \
    --query 'logStreams[0].logStreamName' \
    --output text)

if [ "$LATEST_STREAM" != "None" ]; then
    aws logs get-log-events \
        --log-group-name "/aws/eks/protein-engineering-cluster-new/test-app" \
        --log-stream-name "$LATEST_STREAM" \
        --limit 10
else
    echo "No log streams found yet. Please wait a few moments and try again."
fi

echo -e "\n=== Verification Complete ==="
