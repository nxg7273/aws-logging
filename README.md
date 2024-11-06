# AWS EKS Fargate Logging Setup

This repository contains the configuration files and instructions for setting up AWS CloudWatch logging for EKS Fargate pods in the test-app namespace.

## Prerequisites

- AWS EKS Cluster: protein-engineering-cluster-new
- Fargate Profile: fargate-test-app-profile
- Namespace: test-app
- AWS Region: us-east-1

## Configuration Files

1. `yaml/aws-logging-config.yaml`: ConfigMap for aws-observability namespace containing Fluent Bit configuration
2. `yaml/test-logs-pod.yaml`: Sample pod configuration for testing logging
3. `scripts/deploy-logging.sh`: Deployment script
4. `scripts/verify-logging.sh`: Verification script

## Setup Instructions

1. Create the aws-observability namespace:
```bash
kubectl create namespace aws-observability
```

2. Apply the logging configuration:
```bash
kubectl apply -f yaml/aws-logging-config.yaml
```

3. Deploy test pod:
```bash
kubectl apply -f yaml/test-logs-pod.yaml
```

## Logging Configuration Details

- Log Group: `/aws/eks/protein-engineering-cluster-new/test-app`
- Log Stream Prefix: `fargate-`
- Filtered Messages: Only ERROR, FATAL, EXCEPTION, and FAIL messages
- Namespace Scope: test-app only

## IAM Configuration

The following IAM policies are required:
- EKSFargateCloudWatchLogging
- CloudWatchAgentServerPolicy
- AmazonEKSFargatePodExecutionRolePolicy

## Verification

To verify the logging setup:
```bash
./scripts/verify-logging.sh
```

The script will check:
1. Pod status and events
2. CloudWatch log streams
3. Log filtering (only error messages)
4. IAM permissions

## Troubleshooting

If logs are not appearing in CloudWatch:
1. Check that the aws-logging ConfigMap exists in aws-observability namespace
2. Verify pod has the eks.amazonaws.com/logging: enabled annotation
3. Ensure IAM roles have proper CloudWatch permissions
4. Check pod events for any logging-related errors
