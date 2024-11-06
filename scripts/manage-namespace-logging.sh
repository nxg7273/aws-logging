#!/bin/bash

# Script to manage namespaces and Fargate profiles for AWS logging
# Usage: ./manage-namespace-logging.sh --action [create|delete] --namespaces "namespace1,namespace2,..."

set -e

# Default values
CLUSTER_NAME=${CLUSTER_NAME:-"protein-engineering-cluster-new"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
ACTION=""
NAMESPACES=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --action)
            ACTION="$2"
            shift
            shift
            ;;
        --namespaces)
            NAMESPACES="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ -z "$ACTION" || -z "$NAMESPACES" ]]; then
    echo "Error: Both --action and --namespaces are required"
    echo "Usage: ./manage-namespace-logging.sh --action [create|delete] --namespaces \"namespace1,namespace2,...\""
    exit 1
fi

if [[ "$ACTION" != "create" && "$ACTION" != "delete" ]]; then
    echo "Error: Action must be either 'create' or 'delete'"
    exit 1
fi

# Function to create Fargate profile
create_fargate_profile() {
    local namespace=$1
    echo "Creating Fargate profile for namespace: $namespace"

    eksctl create fargateprofile \
        --cluster "$CLUSTER_NAME" \
        --name "fp-$namespace" \
        --namespace "$namespace" \
        --region "$AWS_REGION" || {
            echo "Failed to create Fargate profile for $namespace"
            return 1
        }
}

# Function to delete Fargate profile
delete_fargate_profile() {
    local namespace=$1
    echo "Deleting Fargate profile for namespace: $namespace"

    eksctl delete fargateprofile \
        --cluster "$CLUSTER_NAME" \
        --name "fp-$namespace" \
        --region "$AWS_REGION" || {
            echo "Failed to delete Fargate profile for $namespace"
            return 1
        }
}

# Function to create namespace and configure logging
create_namespace_logging() {
    local namespace=$1

    # Create namespace
    echo "Creating namespace: $namespace"
    kubectl create namespace "$namespace" || true

    # Label namespace for logging
    kubectl label namespace "$namespace" logging=enabled --overwrite

    # Create Fargate profile
    create_fargate_profile "$namespace"

    # Update AWS logging configuration
    echo "Updating logging configuration for namespace: $namespace"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-logging-${namespace}-config
  namespace: aws-observability
data:
  output.conf: |
    [OUTPUT]
        Name cloudwatch
        Match ${namespace}.*
        region ${AWS_REGION}
        log_group_name /aws/eks/${CLUSTER_NAME}/${namespace}
        log_stream_prefix fargate-
        auto_create_group true
EOF
}

# Function to delete namespace and cleanup logging
delete_namespace_logging() {
    local namespace=$1

    # Delete Fargate profile first
    delete_fargate_profile "$namespace"

    # Delete logging configuration
    echo "Deleting logging configuration for namespace: $namespace"
    kubectl delete configmap "aws-logging-${namespace}-config" -n aws-observability || true

    # Delete namespace
    echo "Deleting namespace: $namespace"
    kubectl delete namespace "$namespace" || true
}

# Main execution
IFS=',' read -ra NAMESPACE_ARRAY <<< "$NAMESPACES"
for namespace in "${NAMESPACE_ARRAY[@]}"; do
    namespace=$(echo "$namespace" | tr -d ' ')
    if [[ "$ACTION" == "create" ]]; then
        echo "=== Creating namespace and logging setup for: $namespace ==="
        create_namespace_logging "$namespace"
    else
        echo "=== Deleting namespace and logging setup for: $namespace ==="
        delete_namespace_logging "$namespace"
    fi
done

echo "Operation completed successfully!"
