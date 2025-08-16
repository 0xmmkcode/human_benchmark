#!/bin/bash

# Human Benchmark - Status Check Script
# This script checks the status of the deployment and provides useful information

set -e

# Configuration
K8S_NAMESPACE="human-benchmark"
DOMAIN="humanbenchmark.xyz"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Function to check if namespace exists
check_namespace() {
    if ! kubectl get namespace $K8S_NAMESPACE &> /dev/null; then
        print_error "Namespace $K8S_NAMESPACE does not exist."
        exit 1
    fi
}

# Function to show pod status
show_pod_status() {
    print_status "Pod Status:"
    echo "============"
    kubectl get pods -n $K8S_NAMESPACE -o wide
    
    echo ""
    print_status "Pod Details:"
    echo "=============="
    kubectl describe pods -n $K8S_NAMESPACE
}

# Function to show service status
show_service_status() {
    print_status "Service Status:"
    echo "================"
    kubectl get services -n $K8S_NAMESPACE -o wide
}

# Function to show ingress status
show_ingress_status() {
    print_status "Ingress Status:"
    echo "================"
    kubectl get ingress -n $K8S_NAMESPACE -o wide
    
    echo ""
    print_status "Ingress Details:"
    echo "==================="
    kubectl describe ingress -n $K8S_NAMESPACE
}

# Function to show deployment status
show_deployment_status() {
    print_status "Deployment Status:"
    echo "===================="
    kubectl get deployment -n $K8S_NAMESPACE -o wide
    
    echo ""
    print_status "Deployment Details:"
    echo "======================="
    kubectl describe deployment -n $K8S_NAMESPACE
}

# Function to show HPA status
show_hpa_status() {
    print_status "HPA Status:"
    echo "============"
    kubectl get hpa -n $K8S_NAMESPACE -o wide
}

# Function to show events
show_events() {
    print_status "Recent Events:"
    echo "================"
    kubectl get events -n $K8S_NAMESPACE --sort-by='.lastTimestamp'
}

# Function to check application health
check_health() {
    print_status "Application Health Check:"
    echo "============================="
    
    # Get the service IP
    SERVICE_IP=$(kubectl get service human-benchmark -n $K8S_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "N/A")
    
    if [ "$SERVICE_IP" != "N/A" ]; then
        print_status "Service IP: $SERVICE_IP"
        
        # Try to curl the service (if curl is available)
        if command -v curl &> /dev/null; then
            print_status "Testing service connectivity..."
            if curl -s --connect-timeout 5 "http://$SERVICE_IP:80" &> /dev/null; then
                print_success "Service is responding"
            else
                print_warning "Service is not responding to HTTP requests"
            fi
        fi
    else
        print_warning "Service IP not available (may be using NodePort or ClusterIP)"
    fi
    
    echo ""
    print_status "Domain: $DOMAIN"
    print_status "Note: Ensure DNS is pointing to your cluster's ingress controller"
}

# Function to show logs
show_logs() {
    print_status "Recent Logs:"
    echo "=============="
    
    # Get the first pod name
    POD_NAME=$(kubectl get pods -n $K8S_NAMESPACE -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$POD_NAME" ]; then
        print_status "Showing logs for pod: $POD_NAME"
        kubectl logs -n $K8S_NAMESPACE $POD_NAME --tail=50
    else
        print_warning "No pods found to show logs"
    fi
}

# Function to show resource usage
show_resource_usage() {
    print_status "Resource Usage:"
    echo "================"
    kubectl top pods -n $K8S_NAMESPACE 2>/dev/null || print_warning "Metrics server not available"
    
    echo ""
    print_status "Node Resource Usage:"
    echo "========================"
    kubectl top nodes 2>/dev/null || print_warning "Metrics server not available"
}

# Main execution
main() {
    print_status "Checking Human Benchmark deployment status..."
    echo "=================================================="
    
    # Check if namespace exists
    check_namespace
    
    # Show all status information
    show_pod_status
    echo ""
    
    show_service_status
    echo ""
    
    show_ingress_status
    echo ""
    
    show_deployment_status
    echo ""
    
    show_hpa_status
    echo ""
    
    show_events
    echo ""
    
    check_health
    echo ""
    
    show_logs
    echo ""
    
    show_resource_usage
    
    print_success "Status check completed!"
}

# Check if script is run with arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --pods-only    Show only pod status"
    echo "  --logs-only    Show only recent logs"
    echo "  --health-only  Show only health check"
    echo ""
    echo "This script provides comprehensive status information about the deployment."
    exit 0
fi

if [ "$1" = "--pods-only" ]; then
    check_namespace
    show_pod_status
    exit 0
fi

if [ "$1" = "--logs-only" ]; then
    check_namespace
    show_logs
    exit 0
fi

if [ "$1" = "--health-only" ]; then
    check_namespace
    check_health
    exit 0
fi

# Run main function
main
