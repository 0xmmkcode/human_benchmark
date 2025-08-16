# DNS Setup Guide for HTTPS

Your Human Benchmark website needs DNS configuration to enable HTTPS with Let's Encrypt.

## 🌐 **Current Ingress Configuration**

- **Ingress Controller**: NodePort (accessible from internet)
- **HTTP Port**: 32729
- **HTTPS Port**: 32304
- **VPS IP**: 5.189.172.176 (control plane node)

## 📝 **DNS Records to Add**

### **Primary Domain (humanbenchmark.xyz)**
```
Type: A
Name: @ (or leave empty)
Value: 5.189.172.176
TTL: 300 (or default)
```

### **WWW Subdomain (www.humanbenchmark.xyz)**
```
Type: A
Name: www
Value: 5.189.172.176
TTL: 300 (or default)
```

## 🔧 **Firewall Configuration**

On your VPS, open the required ports:

```bash
# SSH into your VPS
ssh root@5.189.172.176

# Open the required ports
sudo ufw allow 32729/tcp  # HTTP
sudo ufw allow 32304/tcp  # HTTPS

# Check firewall status
sudo ufw status
```

## 🌍 **DNS Provider Instructions**

### **Namecheap**
1. Go to your domain management
2. Click "Advanced DNS"
3. Add the A records above
4. Wait for propagation (5-30 minutes)

### **GoDaddy**
1. Go to DNS Management
2. Add A records
3. Wait for propagation

### **Cloudflare**
1. Go to DNS settings
2. Add A records
3. Ensure proxy is OFF (gray cloud)
4. Wait for propagation

## ✅ **Verification Steps**

After DNS changes:

1. **Check DNS propagation:**
   ```bash
   nslookup humanbenchmark.xyz
   nslookup www.humanbenchmark.xyz
   ```

2. **Test HTTP access:**
   ```bash
   curl -I http://5.189.172.176:32729
   ```

3. **Check certificate status:**
   ```bash
   kubectl get certificate -n human-benchmark
   kubectl get order -n human-benchmark
   ```

## 🚀 **Expected Result**

Once DNS is configured:
- Let's Encrypt will validate your domain
- SSL certificate will be issued
- HTTPS will work at https://humanbenchmark.xyz
- HTTP will redirect to HTTPS automatically

## 🔍 **Troubleshooting**

If HTTPS still doesn't work:

1. **Check DNS propagation:**
   ```bash
   dig humanbenchmark.xyz
   ```

2. **Verify ports are open:**
   ```bash
   telnet 5.189.172.176 32729
   telnet 5.189.172.176 32304
   ```

3. **Check ingress logs:**
   ```bash
   kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
   ```

4. **Check cert-manager logs:**
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager
   ```

## 📞 **Support**

If you need help:
1. Check the troubleshooting section above
2. Verify DNS propagation with online tools
3. Ensure firewall ports are open
4. Check that your VPS is accessible from the internet
