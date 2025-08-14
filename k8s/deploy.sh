#!/bin/bash

# Human Benchmark Kubernetes Deployment Script
set -e

# Configuration
REGISTRY=${REGISTRY:-"msalekmouad"}
IMAGE_NAME="human-benchmark"
TAG=${TAG:-"latest"}
NAMESPACE="human-benchmark"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Human Benchmark Kubernetes Deployment${NC}"
echo "=========================================="

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ docker is not installed. Please install docker first.${NC}"
    exit 1
fi

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Build Docker image
echo "📦 Building Docker image..."
echo "Building from: $(pwd)/.."
echo "Dockerfile location: $(pwd)/../Dockerfile"

# Check if Dockerfile exists
if [ ! -f "../Dockerfile" ]; then
    print_error "Dockerfile not found at ../Dockerfile"
    print_error "Current directory: $(pwd)"
    print_error "Please run this script from the k8s/ directory"
    exit 1
fi

docker build -t ${REGISTRY}/${IMAGE_NAME}:${TAG} ..
if [ $? -eq 0 ]; then
    print_status "Docker image built successfully"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Push Docker image
echo "📤 Pushing Docker image to registry..."
docker push ${REGISTRY}/${IMAGE_NAME}:${TAG}
if [ $? -eq 0 ]; then
    print_status "Docker image pushed successfully"
else
    print_error "Failed to push Docker image"
    exit 1
fi

# Update deployment.yaml with correct image
echo "🔧 Updating deployment with image reference..."
sed -i.bak "s|your-dockerhub-username/human-benchmark:latest|${REGISTRY}/${IMAGE_NAME}:${TAG}|g" deployment.yaml
print_status "Deployment file updated"

# Apply Kubernetes manifests
echo "🚀 Deploying to Kubernetes..."
kubectl apply -k .
if [ $? -eq 0 ]; then
    print_status "Kubernetes resources deployed successfully"
else
    print_error "Failed to deploy Kubernetes resources"
    exit 1
fi

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/human-benchmark -n ${NAMESPACE} --timeout=300s
if [ $? -eq 0 ]; then
    print_status "Deployment is ready"
else
    print_error "Deployment failed to become ready"
    exit 1
fi

# Get service information
echo "📋 Service Information:"
kubectl get svc -n ${NAMESPACE}

# Get ingress information
echo "🌐 Ingress Information:"
kubectl get ingress -n ${NAMESPACE}

# Get pods status
echo "📦 Pod Status:"
kubectl get pods -n ${NAMESPACE}

# Get external IP (if available)
echo "🔍 External IP Information:"
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || \
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || \
print_warning "External IP not available yet. Check ingress-nginx service."

echo ""
print_status "Deployment completed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure DNS in Namecheap to point to your Kubernetes load balancer IP"
echo "2. Wait for SSL certificate to be issued (usually takes 5-10 minutes)"
echo "3. Test your site at https://humanbenchmark.xyz"
echo ""
echo "Useful commands:"
echo "  kubectl logs -f deployment/human-benchmark -n ${NAMESPACE}"
echo "  kubectl get all -n ${NAMESPACE}"
echo "  kubectl describe ingress human-benchmark-ingress -n ${NAMESPACE}"
