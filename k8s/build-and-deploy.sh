#!/bin/bash

# Human Benchmark - Build and Deploy Script
# This script builds the Docker image, pushes to Docker Hub, and deploys to Kubernetes

set -e  # Exit on any error

# Configuration
DOCKER_IMAGE_NAME="humanbenchmark"
DOCKER_TAG="latest"
DOCKER_USERNAME="msalekmouad"  # Your Docker Hub username
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

# Function to check if docker buildx is available
check_buildx() {
    if ! docker buildx version &> /dev/null; then
        print_error "docker buildx is not available. Please enable Docker Buildx in Docker Desktop."
        print_error "Go to Docker Desktop → Settings → Features → Use Docker Buildx"
        exit 1
    fi
}

# Function to check Docker login
check_docker_login() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running or you're not logged in."
        exit 1
    fi
    
    if ! docker system info &> /dev/null; then
        print_error "Docker daemon is not accessible."
        exit 1
    fi
}

# Function to check project structure
check_project_structure() {
    print_status "Checking project structure..."
    
    # Get the project root directory
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    print_status "Script location: $SCRIPT_DIR"
    print_status "Project root: $PROJECT_ROOT"
    
    # Check if we're in the right place
    if [ ! -f "$PROJECT_ROOT/Dockerfile" ]; then
        print_error "Dockerfile not found in project root: $PROJECT_ROOT"
        print_error "Current working directory: $(pwd)"
        print_error "Please run this script from the k8s/ directory"
        exit 1
    fi
    
    print_success "Project structure verified"
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

# Function to build Docker image
build_image() {
    print_status "Building Docker image: $DOCKER_IMAGE_NAME:$DOCKER_TAG"
    
    # Get the project root directory (parent of k8s folder)
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    print_status "Building from project root: $PROJECT_ROOT"
    
    # Check if Dockerfile exists in project root
    if [ ! -f "$PROJECT_ROOT/Dockerfile" ]; then
        print_error "Dockerfile not found in project root: $PROJECT_ROOT"
        print_error "Please ensure you have a Dockerfile in the root of your project"
        exit 1
    fi
    
    print_status "Found Dockerfile at: $PROJECT_ROOT/Dockerfile"
    
    # Check if buildx is available
    if ! docker buildx version &> /dev/null; then
        print_error "docker buildx is not available. Please enable Docker Buildx."
        exit 1
    fi
    
    # Create and use a new builder if needed
    print_status "Setting up buildx builder..."
    docker buildx create --name humanbenchmark-builder --use --bootstrap 2>/dev/null || true
    
    # Build and push directly to Docker Hub using buildx
    print_status "Building and pushing image for linux/amd64 platform..."
    docker buildx build \
        --platform linux/amd64 \
        -t $DOCKER_USERNAME/$DOCKER_IMAGE_NAME:$DOCKER_TAG \
        -t $DOCKER_USERNAME/$DOCKER_IMAGE_NAME:amd64 \
        --push \
        "$PROJECT_ROOT"
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built and pushed successfully for linux/amd64"
    else
        print_error "Failed to build and push Docker image"
        exit 1
    fi
}

# Function to tag and push to Docker Hub
push_to_dockerhub() {
    print_status "Tagging image for Docker Hub"
    docker tag $DOCKER_IMAGE_NAME:$DOCKER_TAG $DOCKER_USERNAME/$DOCKER_IMAGE_NAME:$DOCKER_TAG
    
    print_status "Pushing image to Docker Hub"
    docker push $DOCKER_USERNAME/$DOCKER_IMAGE_NAME:$DOCKER_TAG
    
    if [ $? -eq 0 ]; then
        print_success "Image pushed to Docker Hub successfully"
    else
        print_error "Failed to push image to Docker Hub"
        exit 1
    fi
}

# Function to deploy to Kubernetes
deploy_to_k8s() {
    print_status "Deploying to Kubernetes namespace: $K8S_NAMESPACE"
    
    # Update the deployment.yaml with the correct image (use amd64 tag for Ubuntu clusters)
    sed -i.bak "s|image:.*|image: $DOCKER_USERNAME/$DOCKER_IMAGE_NAME:amd64|" deployment.yaml
    
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
    
    echo ""
    print_status "Access your application at: https://$DOMAIN"
}

# Main execution
main() {
    print_status "Starting Human Benchmark deployment process..."
    echo "=================================================="
    
    # Pre-flight checks
    print_status "Performing pre-flight checks..."
    check_command docker
    check_command kubectl
    check_docker_login
    check_buildx
    check_k8s_access
    check_project_structure
    
    # Create namespace
    create_namespace
    
    # Build and push image
    build_image
    
    # Deploy to Kubernetes
    deploy_to_k8s
    
    # Wait for deployment
    wait_for_deployment
    
    # Show final status
    show_status
    
    print_success "Deployment completed successfully!"
    print_status "Your application should be accessible at: https://$DOMAIN"
    print_status "Note: DNS propagation may take a few minutes."
}

# Check if script is run with arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "IMPORTANT: Run this script from the k8s/ directory of your project"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --build-only   Only build and push Docker image (don't deploy)"
    echo "  --deploy-only  Only deploy to Kubernetes (don't build)"
    echo ""
    echo "Environment variables:"
    echo "  DOCKER_USERNAME  Your Docker Hub username (default: msalekmouad)"
    echo "  DOCKER_TAG      Docker image tag (default: latest)"
    echo "  K8S_NAMESPACE   Kubernetes namespace (default: human-benchmark)"
    echo "  DOMAIN          Domain name (default: humanbenchmark.xyz)"
    echo ""
    echo "Features:"
    echo "  - Uses docker buildx for multi-platform builds"
    echo "  - Builds specifically for linux/amd64 (Ubuntu clusters)"
    echo "  - Builds and pushes in a single command"
    echo "  - Creates both :latest and :amd64 tags"
    echo ""
    echo "Example:"
    echo "  cd k8s/"
    echo "  ./build-and-deploy.sh"
    exit 0
fi

if [ "$1" = "--build-only" ]; then
    print_status "Build-only mode selected"
    check_command docker
    check_docker_login
    build_image
    print_success "Build and push completed successfully!"
    exit 0
fi

if [ "$1" = "--deploy-only" ]; then
    print_status "Deploy-only mode selected"
    check_command kubectl
    check_k8s_access
    create_namespace
    deploy_to_k8s
    wait_for_deployment
    show_status
    print_success "Deployment completed successfully!"
    exit 0
fi

# Run main function
main
