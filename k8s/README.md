# Human Benchmark - Kubernetes Deployment

This directory contains all the Kubernetes manifests needed to deploy the Human Benchmark Flutter web app to your Kubernetes cluster.

## Prerequisites

1. **Kubernetes Cluster** with:
   - NGINX Ingress Controller
   - cert-manager (for SSL certificates)
   - Metrics Server (for HPA)

2. **Docker Hub Account** (for container registry)

3. **Domain**: `humanbenchmark.xyz` (configured in Namecheap)

## Quick Start

### 1. Build and Push Docker Image

```bash
# Build the image
docker build -t your-dockerhub-username/human-benchmark:latest .

# Push to Docker Hub
docker push your-dockerhub-username/human-benchmark:latest
```

### 2. Update Image Reference

Edit `deployment.yaml` and replace `your-dockerhub-username/human-benchmark:latest` with your actual Docker Hub username.

### 3. Deploy to Kubernetes

```bash
# Apply all resources
kubectl apply -k .

# Or apply individually
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
```

### 4. Verify Deployment

```bash
# Check all resources
kubectl get all -n human-benchmark

# Check ingress
kubectl get ingress -n human-benchmark

# Check pods
kubectl get pods -n human-benchmark

# Check logs
kubectl logs -f deployment/human-benchmark -n human-benchmark
```

## Namecheap DNS Configuration

### Step 1: Get Your Kubernetes Load Balancer IP

After deploying the ingress, get the external IP:

```bash
kubectl get svc -n ingress-nginx
# Look for the external IP of the ingress-nginx-controller service
```

### Step 2: Configure Namecheap DNS

1. **Login to Namecheap** and go to your domain management
2. **Select `humanbenchmark.xyz`** domain
3. **Go to "Advanced DNS"** tab
4. **Add/Update these records:**

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A | @ | [YOUR_K8S_LOAD_BALANCER_IP] | 300 |
| A | www | [YOUR_K8S_LOAD_BALANCER_IP] | 300 |
| CNAME | * | humanbenchmark.xyz | 300 |

### Step 3: Verify DNS Propagation

```bash
# Check if DNS is propagated
nslookup humanbenchmark.xyz
nslookup www.humanbenchmark.xyz

# Test the site
curl -I https://humanbenchmark.xyz
```

## SSL Certificate

The ingress is configured to automatically request SSL certificates from Let's Encrypt using cert-manager. Make sure you have:

1. **cert-manager installed** in your cluster
2. **ClusterIssuer configured** for Let's Encrypt

If you need to create a ClusterIssuer:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

## Monitoring and Scaling

- **HPA**: Automatically scales pods based on CPU (70%) and memory (80%) usage
- **Health Checks**: Liveness and readiness probes configured
- **Resource Limits**: CPU and memory limits set to prevent resource exhaustion

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   kubectl describe pod -n human-benchmark
   ```

2. **Ingress Not Working**
   ```bash
   kubectl get ingress -n human-benchmark -o yaml
   kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
   ```

3. **SSL Certificate Issues**
   ```bash
   kubectl get certificaterequests -n human-benchmark
   kubectl get certificates -n human-benchmark
   ```

### Useful Commands

```bash
# Port forward for local testing
kubectl port-forward -n human-benchmark svc/human-benchmark-service 8080:80

# View logs
kubectl logs -f -l app=human-benchmark -n human-benchmark

# Scale manually
kubectl scale deployment human-benchmark -n human-benchmark --replicas=5

# Delete everything
kubectl delete namespace human-benchmark
```

## Security Features

- **Security Headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **HTTPS Redirect**: All HTTP traffic redirected to HTTPS
- **Resource Limits**: Prevents resource exhaustion attacks
- **Health Checks**: Ensures only healthy pods serve traffic
