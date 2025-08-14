#!/bin/bash

# Ingress Troubleshooting Script
set -e

NAMESPACE="human-benchmark"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔍 Ingress Troubleshooting"
echo "=========================="

# Check if ingress-nginx is installed
echo "1. Checking NGINX Ingress Controller..."
if kubectl get pods -n ingress-nginx &> /dev/null; then
    print_status "NGINX Ingress Controller found"
    kubectl get pods -n ingress-nginx
else
    print_error "NGINX Ingress Controller not found in ingress-nginx namespace"
    print_warning "You may need to install it:"
    echo "   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml"
fi

# Check ingress class
echo ""
echo "2. Checking Ingress Classes..."
kubectl get ingressclass

# Check if our ingress exists
echo ""
echo "3. Checking our Ingress..."
if kubectl get ingress -n ${NAMESPACE} &> /dev/null; then
    print_status "Ingress found"
    kubectl get ingress -n ${NAMESPACE} -o yaml
else
    print_error "Ingress not found"
fi

# Check ingress events
echo ""
echo "4. Checking Ingress Events..."
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | grep -i ingress

# Check if cert-manager is installed
echo ""
echo "5. Checking cert-manager..."
if kubectl get pods -n cert-manager &> /dev/null; then
    print_status "cert-manager found"
    kubectl get pods -n cert-manager
else
    print_error "cert-manager not found"
    print_warning "You may need to install it:"
    echo "   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml"
fi

# Check cluster issuers
echo ""
echo "6. Checking Cluster Issuers..."
kubectl get clusterissuer

# Check if service exists
echo ""
echo "7. Checking Service..."
kubectl get svc -n ${NAMESPACE}

# Check if pods are running
echo ""
echo "8. Checking Pods..."
kubectl get pods -n ${NAMESPACE}

# Check external IP
echo ""
echo "9. Checking External IP..."
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Not found")
if [ "$EXTERNAL_IP" != "Not found" ]; then
    print_status "External IP: $EXTERNAL_IP"
else
    EXTERNAL_HOSTNAME=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not found")
    if [ "$EXTERNAL_HOSTNAME" != "Not found" ]; then
        print_status "External Hostname: $EXTERNAL_HOSTNAME"
    else
        print_warning "No external IP/hostname found"
    fi
fi

# Test DNS resolution
echo ""
echo "10. Testing DNS Resolution..."
if command -v nslookup &> /dev/null; then
    nslookup humanbenchmark.xyz || print_warning "DNS resolution failed"
else
    print_warning "nslookup not available"
fi

echo ""
echo "🔧 Common Solutions:"
echo "==================="
echo "1. If snippets are disabled, use ingress-simple.yaml instead of ingress.yaml"
echo "2. If ingress class not found, check your NGINX Ingress Controller installation"
echo "3. If cert-manager not found, install it for SSL certificates"
echo "4. If external IP not assigned, wait a few minutes or check your cloud provider"
echo ""
echo "To use simple ingress (no security headers):"
echo "  kubectl delete ingress human-benchmark-ingress -n ${NAMESPACE}"
echo "  kubectl apply -f ingress-simple.yaml"
