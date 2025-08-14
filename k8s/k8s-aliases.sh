#!/bin/bash

# Kubernetes aliases for Human Benchmark project
# Add these to your ~/.zshrc or ~/.bashrc

# Project namespace
export HB_NAMESPACE="human-benchmark"

# Quick access to project resources
alias hb-get="kubectl get all -n $HB_NAMESPACE"
alias hb-pods="kubectl get pods -n $HB_NAMESPACE"
alias hb-svc="kubectl get svc -n $HB_NAMESPACE"
alias hb-ingress="kubectl get ingress -n $HB_NAMESPACE"
alias hb-deploy="kubectl get deployments -n $HB_NAMESPACE"
alias hb-hpa="kubectl get hpa -n $HB_NAMESPACE"
alias hb-config="kubectl get configmaps -n $HB_NAMESPACE"

# Quick access to logs
alias hb-logs="kubectl logs -f deployment/human-benchmark -n $HB_NAMESPACE"
alias hb-pod-logs="kubectl logs -f -l app=human-benchmark -n $HB_NAMESPACE"

# Quick access to describe
alias hb-desc="kubectl describe deployment human-benchmark -n $HB_NAMESPACE"
alias hb-desc-pod="kubectl describe pod -n $HB_NAMESPACE"
alias hb-desc-ingress="kubectl describe ingress human-benchmark-ingress -n $HB_NAMESPACE"

# Quick access to events
alias hb-events="kubectl get events -n $HB_NAMESPACE --sort-by='.lastTimestamp'"

# Quick access to exec into pods
alias hb-exec="kubectl exec -it deployment/human-benchmark -n $HB_NAMESPACE -- /bin/sh"

# Quick access to port forward
alias hb-port="kubectl port-forward -n $HB_NAMESPACE svc/human-benchmark-service 8080:80"

# Quick access to delete resources
alias hb-delete="kubectl delete namespace $HB_NAMESPACE"
alias hb-delete-pods="kubectl delete pods -l app=human-benchmark -n $HB_NAMESPACE"

# Quick access to restart deployment
alias hb-restart="kubectl rollout restart deployment/human-benchmark -n $HB_NAMESPACE"

# Quick access to scale
alias hb-scale="kubectl scale deployment human-benchmark -n $HB_NAMESPACE --replicas="

# Quick access to get external IP
alias hb-ip="kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"

# Quick access to check status
alias hb-status="kubectl rollout status deployment/human-benchmark -n $HB_NAMESPACE"

echo "Human Benchmark Kubernetes aliases loaded!"
echo "Use 'hb-get' to see all resources in the namespace"
