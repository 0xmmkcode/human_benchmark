#!/bin/bash

# Human Benchmark - Quick Deploy Script
# This script quickly deploys the application to Kubernetes without rebuilding

set -e

# Configuration
K8S_NAMESPACE="human-benchmark"
DOMAIN="humanbenchmark.xyz"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if namespace exists, create if not
if ! kubectl get namespace $K8S_NAMESPACE &> /dev/null; then
    print_status "Creating namespace: $K8S_NAMESPACE"
    kubectl create namespace $K8S_NAMESPACE
fi

# Deploy all resources
print_status "Deploying to Kubernetes..."
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f service.yaml
kubectl apply -f deployment.yaml
kubectl apply -f hpa.yaml
kubectl apply -f cluster-issuer.yaml
kubectl apply -f ingress.yaml

print_success "Deployment completed!"
print_status "Your application should be accessible at: https://$DOMAIN"

# Show status
kubectl get pods -n $K8S_NAMESPACE
