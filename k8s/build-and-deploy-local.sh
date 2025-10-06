#!/bin/bash

# Human Benchmark - Build and Deploy Script (Local Images)
# This script builds the Docker image locally and deploys to Kubernetes without pushing to Docker Hub

set -e  # Exit on any error

# Configuration
DOCKER_IMAGE_NAME="humanbenchmark"
DOCKER_TAG="latest"
DOCKER_USERNAME="msalekmouad"
K8S_NAMESPACE="human-benchmark"
DOMAIN="humanbenchmark.xyz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

# Function to check Kubernetes access
check_k8s_access() {
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot access Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
}

# Function to create namespace if it doesn't exist
create_namespace() {
    if ! kubectl get namespace $K8S_NAMESPACE &> /dev/null; then
        print_status "Creating namespace: $K8S_NAMESPACE"
        kubectl create namespace $K8S_NAMESPACE
        print_success "Namespace created successfully"
    else
        print_status "Namespace $K8S_NAMESPACE already exists"
    fi
}

# Function to build Docker image locally
build_image_local() {
    print_status "Building Docker image locally: $DOCKER_IMAGE_NAME:$DOCKER_TAG"
    
    # Get the project root directory (parent of k8s folder)
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    print_status "Building from project root: $PROJECT_ROOT"
    
    # Check if Dockerfile exists in project root
    if [ ! -f "$PROJECT_ROOT/Dockerfile" ]; then
        print_error "Dockerfile not found in project root: $PROJECT_ROOT"
        exit 1
    fi
    
    # Build image locally
    docker build -t $DOCKER_USERNAME/$DOCKER_IMAGE_NAME:$DOCKER_TAG "$PROJECT_ROOT"
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully locally"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to deploy to Kubernetes with local image
deploy_to_k8s_local() {
    print_status "Deploying to Kubernetes namespace: $K8S_NAMESPACE"
    
    # Update the deployment.yaml with the local image
    sed -i.bak "s|image:.*|image: $DOCKER_USERNAME/$DOCKER_IMAGE_NAME:$DOCKER_TAG|" deployment.yaml
    
    # Apply all Kubernetes manifests
    kubectl apply -f namespace.yaml
    kubectl apply -f configmap.yaml
    kubectl apply -f service.yaml
    kubectl apply -f deployment.yaml
    kubectl apply -f hpa.yaml
    kubectl apply -f cluster-issuer.yaml
    kubectl apply -f ingress.yaml
    
    print_success "Kubernetes resources deployed successfully"
}

# Function to wait for deployment to be ready
wait_for_deployment() {
    print_status "Waiting for deployment to be ready..."
    
    kubectl wait --for=condition=available --timeout=300s deployment/human-benchmark -n $K8S_NAMESPACE
    
    if [ $? -eq 0 ]; then
        print_success "Deployment is ready"
    else
        print_warning "Deployment might not be ready yet. Check with: kubectl get pods -n $K8S_NAMESPACE"
    fi
}

# Function to show deployment status
show_status() {
    print_status "Deployment Status:"
    echo "=================="
    
    print_status "Pods:"
    kubectl get pods -n $K8S_NAMESPACE
    
    echo ""
    print_status "Services:"
    kubectl get services -n $K8S_NAMESPACE
    
    echo ""
    print_status "Ingress:"
    kubectl get ingress -n $K8S_NAMESPACE
    
    echo ""
    print_status "Deployment:"
    kubectl get deployment -n $K8S_NAMESPACE
}

# Main execution
main() {
    print_status "Starting Human Benchmark deployment process (Local Images)..."
    echo "=================================================="
    
    # Pre-flight checks
    print_status "Performing pre-flight checks..."
    check_command docker
    check_command kubectl
    check_k8s_access
    
    # Create namespace
    create_namespace
    
    # Build image locally
    build_image_local
    
    # Deploy to Kubernetes
    deploy_to_k8s_local
    
    # Wait for deployment
    wait_for_deployment
    
    # Show final status
    show_status
    
    print_success "Deployment completed successfully!"
    print_status "Your application should be accessible at: https://$DOMAIN"
}

# Run main function
main
