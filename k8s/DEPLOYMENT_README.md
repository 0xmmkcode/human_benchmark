# Human Benchmark - Kubernetes Deployment Guide

This guide explains how to deploy the Human Benchmark application to Kubernetes using the provided scripts.

## Prerequisites

- Docker installed and running with Buildx enabled
- Docker Hub account and logged in (`docker login`)
- Kubernetes cluster with kubectl configured
- cert-manager installed (for SSL certificates)
- nginx-ingress controller installed

### Docker Buildx Setup

The deployment script uses `docker buildx` for optimized builds. To enable it:

1. **Docker Desktop**: Go to Settings → Features → Use Docker Buildx
2. **Docker CLI**: Run `docker buildx create --use --name humanbenchmark-builder`

## Project Structure

Your project should have this structure:
```
human_benchmark/
├── Dockerfile                 # Docker image definition
├── lib/                       # Application source code
├── k8s/                       # Kubernetes manifests and scripts
│   ├── build-and-deploy.sh   # Main deployment script
│   ├── quick-deploy.sh       # Quick deployment script
│   ├── undeploy.sh           # Undeployment script
│   ├── status.sh             # Status monitoring script
│   ├── deployment.yaml       # Application deployment
│   ├── service.yaml          # Service definition
│   ├── ingress.yaml          # Ingress configuration
│   └── ...                   # Other K8s manifests
└── ...                        # Other project files
```

## Quick Start

### 1. Configure Docker Hub Username

Edit the `build-and-deploy.sh` script and change the `DOCKER_USERNAME` variable to your actual Docker Hub username:

```bash
DOCKER_USERNAME="your-actual-username"
```

### 2. Full Deployment (Build + Deploy)

**Important**: Run this script from the `k8s/` directory of your project:

```bash
cd k8s/
./build-and-deploy.sh
```

This script will:
- Build the Docker image for `linux/amd64` platform (Ubuntu clusters)
- Push it to Docker Hub with both `:latest` and `:amd64` tags
- Deploy to Kubernetes using the `:amd64` tag
- Configure ingress for `humanbenchmark.xyz`

**Note**: Uses `docker buildx` for optimized builds and direct push to Docker Hub.

### 3. Quick Deploy (Existing Image)

If you already have an image built and pushed:

```bash
cd k8s/
./quick-deploy.sh
```

### 4. Check Status

```bash
cd k8s/
./status.sh
```

### 5. Undeploy

```bash
cd k8s/
./undeploy.sh
```

## Script Details

### build-and-deploy.sh

**Purpose**: Complete deployment pipeline from source code to running application

**Features**:
- Pre-flight checks (Docker, kubectl, cluster access)
- Docker image building
- Docker Hub push
- Kubernetes deployment
- Automatic namespace creation
- Health monitoring
- Colored output for better readability

**Options**:
- `--help`: Show help message
- `--build-only`: Only build Docker image
- `--deploy-only`: Only deploy to Kubernetes

**Environment Variables**:
- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_TAG`: Docker image tag (default: latest)
- `K8S_NAMESPACE`: Kubernetes namespace (default: human-benchmark)
- `DOMAIN`: Domain name (default: humanbenchmark.xyz)

### quick-deploy.sh

**Purpose**: Fast deployment of existing images

**Use Case**: When you want to redeploy without rebuilding

### undeploy.sh

**Purpose**: Clean removal of all resources

**Features**:
- Removes all Kubernetes resources
- Deletes the namespace
- Force cleanup with `--force --grace-period=0`

**Options**:
- `--help`: Show help message
- `--resources-only`: Remove resources but keep namespace

### status.sh

**Purpose**: Comprehensive deployment monitoring

**Features**:
- Pod status and details
- Service status
- Ingress configuration
- Deployment status
- HPA status
- Recent events
- Application health check
- Recent logs
- Resource usage

**Options**:
- `--help`: Show help message
- `--pods-only`: Show only pod status
- `--logs-only`: Show only recent logs
- `--health-only`: Show only health check

## Deployment Architecture

```
Internet → Ingress Controller → Service → Pods
    ↓
SSL Termination (cert-manager)
    ↓
Domain: humanbenchmark.xyz
```

## Configuration Files

- `namespace.yaml`: Creates the `human-benchmark` namespace
- `configmap.yaml`: Application configuration
- `deployment.yaml`: Application deployment
- `service.yaml`: Service definition
- `ingress.yaml`: Ingress configuration with SSL
- `cluster-issuer.yaml`: SSL certificate issuer
- `hpa.yaml`: Horizontal Pod Autoscaler

## Troubleshooting

### Common Issues

1. **Docker not running**
   ```bash
   # Start Docker Desktop or Docker daemon
   ```

2. **Not logged into Docker Hub**
   ```bash
   docker login
   ```

3. **Kubernetes cluster not accessible**
   ```bash
   kubectl cluster-info
   # Check your kubeconfig
   ```

4. **Namespace already exists**
   ```bash
   # The script will handle this automatically
   # Or manually delete: kubectl delete namespace human-benchmark
   ```

5. **SSL certificate issues**
   ```bash
   # Check cert-manager status
   kubectl get pods -n cert-manager
   ```

### Debug Commands

```bash
# Check pod logs
kubectl logs -n human-benchmark <pod-name>

# Check ingress status
kubectl get ingress -n human-benchmark

# Check SSL certificate
kubectl get certificate -n human-benchmark

# Check events
kubectl get events -n human-benchmark --sort-by='.lastTimestamp'
```

## DNS Configuration

Ensure your domain `humanbenchmark.xyz` points to your Kubernetes cluster's ingress controller IP address.

## Security Features

- SSL/TLS encryption with Let's Encrypt
- Security headers via nginx configuration
- HTTPS redirect enforcement
- Resource limits and requests

## Scaling

The deployment includes an HPA (Horizontal Pod Autoscaler) that automatically scales pods based on CPU usage.

## Monitoring

Use the `status.sh` script to monitor:
- Pod health
- Resource usage
- Application logs
- SSL certificate status
- Ingress configuration

## Best Practices

1. **Always check status after deployment**
   ```bash
   ./k8s/status.sh
   ```

2. **Use specific tags for production**
   ```bash
   export DOCKER_TAG="v1.0.0"
   ./k8s/build-and-deploy.sh
   ```

3. **Monitor resource usage**
   ```bash
   ./k8s/status.sh --health-only
   ```

4. **Check logs for issues**
   ```bash
   ./k8s/status.sh --logs-only
   ```

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Run `./k8s/status.sh` for comprehensive status
3. Check Kubernetes events: `kubectl get events -n human-benchmark`
4. Verify DNS configuration points to your cluster
5. Ensure cert-manager and nginx-ingress are properly installed
