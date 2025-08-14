# Docker Hub Setup Guide

This guide will help you set up Docker Hub for your Human Benchmark Flutter web app deployment.

## Prerequisites

1. **Docker Hub Account**: Create one at https://hub.docker.com/
2. **Docker CLI**: Installed and configured on your machine
3. **Docker Hub Access Token**: For secure authentication

## Step 1: Create Docker Hub Account

1. **Visit** https://hub.docker.com/
2. **Sign up** for a free account
3. **Choose a username** (this will be your registry name)
4. **Verify your email**

## Step 2: Create Access Token

For secure authentication (recommended over password):

1. **Login to Docker Hub**
2. **Go to Account Settings** → **Security**
3. **Click "New Access Token"**
4. **Give it a name** (e.g., "k8s-deployment")
5. **Copy the token** (you won't see it again)

## Step 3: Login to Docker Hub

```bash
# Login with your username and access token
docker login -u your-dockerhub-username

# When prompted for password, use your access token
```

## Step 4: Create Repository

1. **Go to Docker Hub** → **Repositories**
2. **Click "Create Repository"**
3. **Repository name**: `human-benchmark`
4. **Visibility**: Public (free) or Private (paid)
5. **Click "Create"**

## Step 5: Build and Push Image

### Option A: Using the Deploy Script

```bash
# Set your Docker Hub username
export REGISTRY="your-dockerhub-username"

# Run the deployment script
cd k8s
./deploy.sh
```

### Option B: Manual Build and Push

```bash
# Build the image
docker build -t your-dockerhub-username/human-benchmark:latest .

# Tag with version (optional)
docker tag your-dockerhub-username/human-benchmark:latest your-dockerhub-username/human-benchmark:v1.0.0

# Push to Docker Hub
docker push your-dockerhub-username/human-benchmark:latest
docker push your-dockerhub-username/human-benchmark:v1.0.0
```

## Step 6: Update Kubernetes Configuration

### Update deployment.yaml

Replace `your-dockerhub-username` with your actual Docker Hub username:

```yaml
containers:
- name: human-benchmark
  image: your-dockerhub-username/human-benchmark:latest
```

### Or use environment variable

```bash
# Set your username
export DOCKERHUB_USERNAME="your-dockerhub-username"

# Update the deployment file
sed -i "s/your-dockerhub-username/$DOCKERHUB_USERNAME/g" k8s/deployment.yaml
```

## Step 7: Deploy to Kubernetes

```bash
# Apply the configuration
kubectl apply -k k8s/

# Or apply individually
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml
```

## Image Management

### List Images

```bash
# List local images
docker images | grep human-benchmark

# List remote images (via Docker Hub API)
curl -s "https://hub.docker.com/v2/repositories/your-dockerhub-username/human-benchmark/tags/" | jq '.results[].name'
```

### Update Image

```bash
# Build new version
docker build -t your-dockerhub-username/human-benchmark:v1.1 .

# Push new version
docker push your-dockerhub-username/human-benchmark:v1.1

# Update Kubernetes deployment
kubectl set image deployment/human-benchmark human-benchmark=your-dockerhub-username/human-benchmark:v1.1 -n human-benchmark
```

### Rollback Image

```bash
# Rollback to previous version
kubectl rollout undo deployment/human-benchmark -n human-benchmark

# Or specify a specific version
kubectl set image deployment/human-benchmark human-benchmark=your-dockerhub-username/human-benchmark:v1.0.0 -n human-benchmark
```

## Best Practices

### 1. Use Semantic Versioning

```bash
# Tag with semantic versions
docker tag your-dockerhub-username/human-benchmark:latest your-dockerhub-username/human-benchmark:1.0.0
docker tag your-dockerhub-username/human-benchmark:latest your-dockerhub-username/human-benchmark:1.0.1
```

### 2. Multi-stage Builds

Your Dockerfile already uses multi-stage builds for optimization.

### 3. Security Scanning

```bash
# Scan for vulnerabilities (if you have Docker Scout)
docker scout cves your-dockerhub-username/human-benchmark:latest
```

### 4. Image Size Optimization

```bash
# Check image size
docker images your-dockerhub-username/human-benchmark

# Use .dockerignore to exclude unnecessary files
```

## Troubleshooting

### Image Pull Errors

```bash
# Check if image exists
docker pull your-dockerhub-username/human-benchmark:latest

# Check Kubernetes events
kubectl describe pod -n human-benchmark
```

### Authentication Issues

```bash
# Re-login to Docker Hub
docker logout
docker login -u your-dockerhub-username

# Check if you can pull the image
docker pull your-dockerhub-username/human-benchmark:latest
```

### Build Failures

```bash
# Check build logs
docker build -t your-dockerhub-username/human-benchmark:latest . --progress=plain

# Check if Dockerfile is valid
docker build -t test-image . --dry-run
```

## Docker Hub Limits

### Free Account Limits

- **Public repositories**: Unlimited
- **Private repositories**: 1
- **Image pulls**: 200 per 6 hours for anonymous users
- **Image pushes**: Unlimited

### Paid Account Benefits

- **Private repositories**: Unlimited
- **Higher pull limits**: 5000 per 6 hours
- **Advanced features**: Vulnerability scanning, etc.

## Automation

### GitHub Actions Example

```yaml
name: Build and Push to Docker Hub

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Login to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}
    
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        push: true
        tags: your-dockerhub-username/human-benchmark:latest
```

## Useful Commands

```bash
# Check Docker Hub rate limits
curl -H "Authorization: Bearer $(docker system info --format '{{.RegistryConfig.Auths.hub.docker.com.Password}}')" https://registry-1.docker.io/v2/ratelimitpreview/testimage/manifests/latest

# View repository on Docker Hub
open https://hub.docker.com/r/your-dockerhub-username/human-benchmark

# Check image layers
docker history your-dockerhub-username/human-benchmark:latest
```
