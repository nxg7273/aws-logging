# AWS EKS Fargate Logging Setup

This repository contains configuration and scripts for setting up AWS CloudWatch logging for EKS Fargate pods in multiple namespaces.

## Features

- Multi-namespace support (test-app and logging namespaces)
- Automated Fargate profile management
- Namespace-specific log groups in CloudWatch
- Error and fatal message logging
- JSON-formatted log output

## Prerequisites

- AWS CLI configured with appropriate credentials
- kubectl configured for your EKS cluster
- eksctl installed

## Configuration Files

- `yaml/aws-logging-config.yaml`: AWS Logging configuration for Fargate
- `scripts/manage-namespace-logging.sh`: Script for managing namespace logging
- `yaml/test-logs-pod.yaml`: Test pod configuration for log verification

## Setup Instructions

1. Create required namespaces:
```bash
kubectl create namespace test-app
kubectl create namespace logging
```

2. Create Fargate profiles:
```bash
eksctl create fargateprofile \
  --cluster protein-engineering-cluster-new \
  --name test-app-profile \
  --namespace test-app

eksctl create fargateprofile \
  --cluster protein-engineering-cluster-new \
  --name logging-profile \
  --namespace logging
```

3. Apply logging configuration:
```bash
kubectl apply -f yaml/aws-logging-config.yaml
```

## Verification

Logs are collected in the following CloudWatch log groups:
- /aws/eks/protein-engineering-cluster-new/test-app
- /aws/eks/protein-engineering-cluster-new/logging

To verify logging:
1. Deploy test pods to both namespaces
2. Check CloudWatch log groups for log entries
3. Verify namespace-specific log capture

## Cleanup

To remove logging setup:
```bash
./scripts/manage-namespace-logging.sh --delete test-app
./scripts/manage-namespace-logging.sh --delete logging
```

## Troubleshooting

1. If pods are stuck in Pending state:
   - Verify Fargate profile exists for the namespace
   - Check pod events using `kubectl describe pod`

2. If logs are not appearing:
   - Verify pod has `eks.amazonaws.com/compute-type: fargate` annotation
   - Check CloudWatch log group permissions
