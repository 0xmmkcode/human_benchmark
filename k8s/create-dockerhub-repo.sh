#!/bin/bash

# Human Benchmark - Docker Hub Repository Creation Script
# This script helps create the Docker Hub repository

set -e

# Configuration
DOCKER_USERNAME="msalekmouad"
REPO_NAME="humanbenchmark"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

print_status "Docker Hub Repository Creation Helper"
echo "=========================================="

print_status "Username: $DOCKER_USERNAME"
print_status "Repository: $REPO_NAME"
echo ""

print_status "To create the repository, please follow these steps:"
echo ""
echo "1. Go to: https://hub.docker.com"
echo "2. Sign in with your account: $DOCKER_USERNAME"
echo "3. Click 'Create Repository'"
echo "4. Repository name: $REPO_NAME"
echo "5. Choose visibility (Public or Private)"
echo "6. Click 'Create'"
echo ""

print_warning "Note: You cannot create repositories via Docker CLI without Docker Hub Pro"
print_warning "Please create the repository manually using the steps above"
echo ""

print_status "After creating the repository, you can run:"
echo "  cd k8s/"
echo "  ./build-and-deploy.sh"
echo ""

print_status "Alternative: Test with a simple push first:"
echo "  docker tag hello-world:latest $DOCKER_USERNAME/$REPO_NAME:test"
echo "  docker push $DOCKER_USERNAME/$REPO_NAME:test"
echo ""

print_success "Repository creation instructions provided!"
