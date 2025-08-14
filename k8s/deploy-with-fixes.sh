#!/bin/bash

# Human Benchmark Deployment with Ingress Fixes
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

echo "🚀 Human Benchmark Deployment with Ingress Fixes"
echo "================================================"

# Function to check if snippet annotations are allowed
check_snippet_support() {
    echo "🔍 Checking NGINX Ingress Controller snippet support..."
    
    # Try to apply a test ingress with snippet
    cat <<EOF | kubectl apply -f - --dry-run=server 2>&1 | grep -q "snippet" && echo "disabled" || echo "enabled"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-snippet
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/server-snippet: "add_header Test-Header test;"
spec:
  ingressClassName: nginx
  rules:
  - host: test.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-service
            port:
              number: 80
EOF
}

# Deploy with snippet support check
echo "📦 Deploying Kubernetes resources..."

# First, try with the full ingress (with security headers)
echo "🔄 Attempting deployment with security headers..."
if kubectl apply -f namespace.yaml -f configmap.yaml -f deployment.yaml -f service.yaml -f hpa.yaml; then
    print_status "Core resources deployed successfully"
else
    print_error "Failed to deploy core resources"
    exit 1
fi

# Check snippet support and deploy appropriate ingress
SNIPPET_STATUS=$(check_snippet_support)

if [ "$SNIPPET_STATUS" = "enabled" ]; then
    print_status "Snippet annotations are enabled, using full ingress"
    if kubectl apply -f ingress.yaml; then
        print_status "Full ingress with security headers deployed"
    else
        print_error "Failed to deploy full ingress"
        exit 1
    fi
else
    print_warning "Snippet annotations are disabled, using simple ingress"
    if kubectl apply -f ingress-simple.yaml; then
        print_status "Simple ingress deployed (security headers in nginx config)"
    else
        print_error "Failed to deploy simple ingress"
        exit 1
    fi
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

# Show status
echo "📋 Deployment Status:"
echo "===================="
kubectl get all -n ${NAMESPACE}
echo ""
kubectl get ingress -n ${NAMESPACE}
echo ""

# Get external IP
echo "🔍 External IP Information:"
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

echo ""
print_status "Deployment completed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure DNS in Namecheap to point to your Kubernetes load balancer IP"
echo "2. Wait for SSL certificate to be issued (usually takes 5-10 minutes)"
echo "3. Test your site at https://humanbenchmark.xyz"
echo ""
echo "Security headers are included in the nginx configuration (not via snippets)"
echo "Useful commands:"
echo "  kubectl logs -f deployment/human-benchmark -n ${NAMESPACE}"
echo "  kubectl get all -n ${NAMESPACE}"
echo "  kubectl describe ingress human-benchmark-ingress -n ${NAMESPACE}"
