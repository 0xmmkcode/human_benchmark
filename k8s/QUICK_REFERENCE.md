# Quick Reference - Human Benchmark K8s Deployment

## 🚀 Quick Deploy

```bash
# Set your Docker Hub username
export REGISTRY="your-dockerhub-username"

# Deploy everything
./deploy.sh

# Or manually
kubectl apply -k .
```

## 📋 Essential Commands

### Check Status
```bash
# All resources
kubectl get all -n human-benchmark

# Pods
kubectl get pods -n human-benchmark

# Services
kubectl get svc -n human-benchmark

# Ingress
kubectl get ingress -n human-benchmark

# Certificates
kubectl get certificates -n human-benchmark
```

### View Logs
```bash
# Application logs
kubectl logs -f deployment/human-benchmark -n human-benchmark

# Ingress logs
kubectl logs -f -n ingress-nginx deployment/ingress-nginx-controller

# Cert-manager logs
kubectl logs -f -n cert-manager deployment/cert-manager
```

### Troubleshooting
```bash
# Describe resources
kubectl describe pod -n human-benchmark
kubectl describe ingress -n human-benchmark human-benchmark-ingress
kubectl describe certificate -n human-benchmark

# Port forward for testing
kubectl port-forward -n human-benchmark svc/human-benchmark-service 8080:80

# Check events
kubectl get events -n human-benchmark --sort-by='.lastTimestamp'
```

## 🌐 DNS Configuration (Namecheap)

### Required Records
| Type | Host | Value | TTL |
|------|------|-------|-----|
| A | @ | [K8S_LOAD_BALANCER_IP] | 300 |
| A | www | [K8S_LOAD_BALANCER_IP] | 300 |
| CNAME | * | humanbenchmark.xyz | 300 |

### Get Load Balancer IP
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## 🔧 Configuration Files

- `namespace.yaml` - Creates namespace
- `configmap.yaml` - Nginx configuration
- `deployment.yaml` - App deployment
- `service.yaml` - Internal service
- `ingress.yaml` - External access + SSL
- `hpa.yaml` - Auto-scaling
- `cluster-issuer.yaml` - SSL certificates

## 🚨 Common Issues

### Pod Not Starting
```bash
kubectl describe pod -n human-benchmark
kubectl logs -n human-benchmark deployment/human-benchmark
```

### SSL Certificate Issues
```bash
kubectl get certificaterequests -n human-benchmark
kubectl describe certificaterequest -n human-benchmark
```

### DNS Not Working
```bash
nslookup humanbenchmark.xyz
dig humanbenchmark.xyz
```

### Ingress Not Working
```bash
kubectl get ingress -n human-benchmark -o yaml
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## 📊 Monitoring

### Resource Usage
```bash
# CPU/Memory usage
kubectl top pods -n human-benchmark

# HPA status
kubectl get hpa -n human-benchmark
```

### Health Checks
```bash
# Test health endpoint
curl https://humanbenchmark.xyz/health

# Check readiness
kubectl get pods -n human-benchmark -o wide
```

## 🔄 Updates

### Update Image
```bash
# Build new image
docker build -t your-dockerhub-username/human-benchmark:v1.1 .

# Push to Docker Hub
docker push your-dockerhub-username/human-benchmark:v1.1

# Update deployment
kubectl set image deployment/human-benchmark human-benchmark=your-dockerhub-username/human-benchmark:v1.1 -n human-benchmark
```

### Rollback
```bash
kubectl rollout undo deployment/human-benchmark -n human-benchmark
```

## 🗑️ Cleanup

```bash
# Delete everything
kubectl delete namespace human-benchmark

# Or delete individually
kubectl delete -k .
```

## 📞 Support

- **K8s Issues**: Check logs and events
- **DNS Issues**: Verify Namecheap configuration
- **SSL Issues**: Check cert-manager and ClusterIssuer
- **Performance**: Monitor HPA and resource usage
