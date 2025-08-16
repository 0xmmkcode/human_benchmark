#!/bin/bash

# Human Benchmark - Undeploy Script
# This script removes all resources from the Kubernetes namespace

set -e

# Configuration
K8S_NAMESPACE="human-benchmark"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if namespace exists
check_namespace() {
    if ! kubectl get namespace $K8S_NAMESPACE &> /dev/null; then
        print_warning "Namespace $K8S_NAMESPACE does not exist. Nothing to undeploy."
        exit 0
    fi
}

# Function to undeploy resources
undeploy_resources() {
    print_status "Undeploying resources from namespace: $K8S_NAMESPACE"
    
    # Delete resources in reverse order of dependencies
    kubectl delete -f ingress.yaml --ignore-not-found=true
    kubectl delete -f cluster-issuer.yaml --ignore-not-found=true
    kubectl delete -f hpa.yaml --ignore-not-found=true
    kubectl delete -f deployment.yaml --ignore-not-found=true
    kubectl delete -f service.yaml --ignore-not-found=true
    kubectl delete -f configmap.yaml --ignore-not-found=true
    
    print_status "Resources undeployed successfully"
}

# Function to delete namespace
delete_namespace() {
    print_status "Deleting namespace: $K8S_NAMESPACE"
    
    # Force delete the namespace and all its resources
    kubectl delete namespace $K8S_NAMESPACE --force --grace-period=0
    
    print_status "Namespace deleted successfully"
}

# Function to show remaining resources
show_remaining() {
    print_status "Checking for remaining resources..."
    
    # Check if namespace still exists
    if kubectl get namespace $K8S_NAMESPACE &> /dev/null; then
        print_warning "Namespace still exists. Checking for remaining resources..."
        kubectl get all -n $K8S_NAMESPACE
    else
        print_status "Namespace has been completely removed"
    fi
}

# Main execution
main() {
    print_status "Starting undeployment process..."
    echo "====================================="
    
    # Check if namespace exists
    check_namespace
    
    # Undeploy resources
    undeploy_resources
    
    # Delete namespace
    delete_namespace
    
    # Show remaining resources
    show_remaining
    
    print_status "Undeployment completed successfully!"
}

# Check if script is run with arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --resources-only  Only remove resources, keep namespace"
    echo ""
    echo "This script will remove all resources and the namespace from Kubernetes."
    exit 0
fi

if [ "$1" = "--resources-only" ]; then
    print_status "Resources-only mode selected"
    check_namespace
    undeploy_resources
    print_status "Resources removed successfully!"
    exit 0
fi

# Run main function
main
