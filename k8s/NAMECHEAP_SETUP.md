# Namecheap DNS Configuration Guide

This guide will walk you through configuring your `humanbenchmark.xyz` domain in Namecheap to point to your Kubernetes cluster.

## Prerequisites

1. **Domain purchased** at Namecheap: `humanbenchmark.xyz`
2. **Kubernetes cluster** with NGINX Ingress Controller deployed
3. **External IP** of your Kubernetes load balancer

## Step-by-Step Instructions

### Step 1: Get Your Kubernetes Load Balancer IP

First, you need to get the external IP address of your Kubernetes load balancer:

```bash
# Check if you have an ingress-nginx controller
kubectl get svc -n ingress-nginx

# Look for the external IP of ingress-nginx-controller
kubectl get svc -n ingress-nginx ingress-nginx-controller -o wide
```

**Note**: If you don't see an external IP, you might need to:
- Wait a few minutes for the cloud provider to assign an IP
- Check if your cluster supports LoadBalancer services
- Use a NodePort or ClusterIP service instead

### Step 2: Access Namecheap Domain Management

1. **Login to Namecheap** (https://www.namecheap.com)
2. **Go to "Domain List"** in your dashboard
3. **Find `humanbenchmark.xyz`** and click **"Manage"**
4. **Click on "Advanced DNS"** tab

### Step 3: Configure DNS Records

In the "Advanced DNS" section, you'll see a table with existing records. You need to add/update the following records:

#### Option A: If you have a Static IP from your cloud provider

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A | @ | [YOUR_K8S_LOAD_BALANCER_IP] | 300 |
| A | www | [YOUR_K8S_LOAD_BALANCER_IP] | 300 |
| CNAME | * | humanbenchmark.xyz | 300 |

#### Option B: If you have a dynamic IP or hostname

| Type | Host | Value | TTL |
|------|------|-------|-----|
| CNAME | @ | [YOUR_K8S_HOSTNAME] | 300 |
| CNAME | www | [YOUR_K8S_HOSTNAME] | 300 |
| CNAME | * | humanbenchmark.xyz | 300 |

### Step 4: Add/Update Records

1. **Click "Add New Record"** for each record you need to add
2. **For existing records**, click the edit icon (pencil) to modify them
3. **Fill in the details** as shown in the table above
4. **Click "Save"** after each record

### Step 5: Remove Unnecessary Records

You might see some default records that you don't need:
- Remove any existing A records for `@` that point to Namecheap parking pages
- Remove any CNAME records for `www` that point to parking pages
- Keep any email-related records (MX, TXT for SPF, etc.) if you plan to use email

### Step 6: Verify Configuration

After saving all records, wait a few minutes and then verify:

```bash
# Check DNS propagation
nslookup humanbenchmark.xyz
nslookup www.humanbenchmark.xyz

# Test with dig (more detailed)
dig humanbenchmark.xyz
dig www.humanbenchmark.xyz

# Test the actual site
curl -I http://humanbenchmark.xyz
curl -I https://humanbenchmark.xyz
```

## Common Issues and Solutions

### Issue 1: DNS Not Propagating

**Symptoms**: `nslookup` shows old IP or no resolution
**Solution**: 
- DNS changes can take up to 48 hours to propagate globally
- Usually takes 5-30 minutes for most users
- Try using different DNS servers: `nslookup humanbenchmark.xyz 8.8.8.8`

### Issue 2: SSL Certificate Not Issuing

**Symptoms**: Site loads but shows SSL warning
**Solution**:
- Ensure your ingress is properly configured
- Check cert-manager logs: `kubectl logs -n cert-manager deployment/cert-manager`
- Verify DNS is pointing to the correct IP before requesting certificates

### Issue 3: Site Not Loading

**Symptoms**: Connection timeout or refused
**Solution**:
- Verify your Kubernetes ingress is working: `kubectl get ingress -n human-benchmark`
- Check if the external IP is correct
- Ensure your cluster's firewall allows HTTP/HTTPS traffic

### Issue 4: www Subdomain Not Working

**Symptoms**: Main domain works but www doesn't
**Solution**:
- Ensure you have both A records (for @ and www)
- Or use CNAME for www pointing to the main domain
- Check that your ingress handles both hosts

## Testing Your Setup

### 1. DNS Propagation Test

Visit https://www.whatsmydns.net/ and enter `humanbenchmark.xyz` to see global DNS propagation.

### 2. SSL Certificate Test

Visit https://www.ssllabs.com/ssltest/ and enter your domain to check SSL configuration.

### 3. Performance Test

Use tools like:
- https://pagespeed.web.dev/
- https://gtmetrix.com/
- https://webpagetest.org/

## Security Considerations

1. **Enable DNSSEC** in Namecheap (if available)
2. **Set up SPF records** if you plan to send email
3. **Consider using a CDN** like Cloudflare for additional security and performance
4. **Regular SSL certificate monitoring** (cert-manager handles this automatically)

## Monitoring

After setup, monitor your domain:
- **Uptime monitoring**: Use services like UptimeRobot or Pingdom
- **SSL certificate monitoring**: cert-manager will handle renewals
- **DNS monitoring**: Use tools like DNSViz or DNSCheck

## Support

If you encounter issues:
1. **Check Namecheap's DNS documentation**: https://www.namecheap.com/support/knowledgebase/article.aspx/319/2237/
2. **Contact Namecheap support** for DNS-related issues
3. **Check Kubernetes logs** for application-related issues
4. **Verify your ingress configuration** is correct
