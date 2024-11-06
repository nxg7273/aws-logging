# AWS EKS Fargate Logging Setup

This repository contains the configuration files and automation scripts for setting up AWS CloudWatch logging for EKS Fargate pods across multiple namespaces.

## Prerequisites

- AWS CLI configured with appropriate permissions
- kubectl configured to access your EKS cluster
- eksctl installed
- AWS EKS Cluster running
- AWS Region configured

## Features

- Multi-namespace support for CloudWatch logging
- Automated Fargate profile management
- Namespace-specific log filtering
- Error-level message filtering (ERROR, FATAL, EXCEPTION, FAIL)
- Automated deployment and cleanup

## Configuration Files

1. `yaml/aws-logging-config.yaml`: Base ConfigMap for aws-observability namespace
2. `yaml/test-logs-pod.yaml`: Sample pod configuration for testing logging
3. `scripts/deploy-logging.sh`: Base logging deployment script
4. `scripts/verify-logging.sh`: Logging verification script
5. `scripts/manage-namespace-logging.sh`: Namespace and Fargate profile automation script

## Automated Namespace Management

The `manage-namespace-logging.sh` script provides automated management of namespaces and their associated Fargate profiles:

### Usage

```bash
# Create new namespace(s) with logging enabled
./scripts/manage-namespace-logging.sh --action create --namespaces "namespace1,namespace2"

# Delete namespace(s) and cleanup logging
./scripts/manage-namespace-logging.sh --action delete --namespaces "namespace1,namespace2"
```

### Environment Variables

- `CLUSTER_NAME`: EKS cluster name (default: protein-engineering-cluster-new)
- `AWS_REGION`: AWS region (default: us-east-1)

### Features

- Creates/deletes Fargate profiles
- Sets up namespace-specific logging configuration
- Manages CloudWatch log groups
- Handles cleanup of resources
- Supports multiple namespaces in a single command

## Manual Setup Instructions

1. Create the aws-observability namespace:
```bash
kubectl create namespace aws-observability
```

2. Apply the base logging configuration:
```bash
kubectl apply -f yaml/aws-logging-config.yaml
```

3. Deploy test pods (optional):
```bash
kubectl apply -f yaml/test-logs-pod.yaml
```

## Logging Configuration Details

- Log Group Pattern: `/aws/eks/<cluster-name>/<namespace>`
- Log Stream Prefix: `fargate-`
- Filtered Messages: Only ERROR, FATAL, EXCEPTION, and FAIL messages
- Namespace Scope: Configurable per namespace

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

The script checks:
1. Pod status and events
2. CloudWatch log streams
3. Log filtering (only error messages)
4. IAM permissions

## Adding New Namespaces

To add a new namespace to logging:

1. Use the automation script:
```bash
./scripts/manage-namespace-logging.sh --action create --namespaces "new-namespace"
```

2. Deploy your applications to the new namespace
3. Verify logging is working:
```bash
kubectl logs -n new-namespace <pod-name>
aws logs get-log-events --log-group-name "/aws/eks/<cluster-name>/new-namespace"
```

## Troubleshooting

If logs are not appearing in CloudWatch:
1. Check that the aws-logging ConfigMap exists in aws-observability namespace
2. Verify pod has the eks.amazonaws.com/logging: enabled annotation
3. Ensure IAM roles have proper CloudWatch permissions
4. Check pod events for any logging-related errors
5. Verify Fargate profile exists for the namespace
6. Check namespace labels for logging=enabled

## Examples

### Adding Multiple Namespaces
```bash
./scripts/manage-namespace-logging.sh --action create --namespaces "dev,staging,prod"
```

### Cleaning Up Namespaces
```bash
./scripts/manage-namespace-logging.sh --action delete --namespaces "old-namespace"
```

### Verifying Logs
```bash
# Check CloudWatch logs for specific namespace
aws logs get-log-events \
    --log-group-name "/aws/eks/<cluster-name>/<namespace>" \
    --log-stream-name $(aws logs describe-log-streams \
        --log-group-name "/aws/eks/<cluster-name>/<namespace>" \
        --query 'logStreams[0].logStreamName' \
        --output text)
```
