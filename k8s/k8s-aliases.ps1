# Kubernetes aliases for Human Benchmark project (PowerShell version)
# Add these to your PowerShell profile or run this script

# Project namespace
$env:HB_NAMESPACE = "human-benchmark"

# Quick access to project resources
function hb-get { kubectl get all -n $env:HB_NAMESPACE }
function hb-pods { kubectl get pods -n $env:HB_NAMESPACE }
function hb-svc { kubectl get svc -n $env:HB_NAMESPACE }
function hb-ingress { kubectl get ingress -n $env:HB_NAMESPACE }
function hb-deploy { kubectl get deployments -n $env:HB_NAMESPACE }
function hb-hpa { kubectl get hpa -n $env:HB_NAMESPACE }
function hb-config { kubectl get configmaps -n $env:HB_NAMESPACE }

# Quick access to logs
function hb-logs { kubectl logs -f deployment/human-benchmark -n $env:HB_NAMESPACE }
function hb-pod-logs { kubectl logs -f -l app=human-benchmark -n $env:HB_NAMESPACE }

# Quick access to describe
function hb-desc { kubectl describe deployment human-benchmark -n $env:HB_NAMESPACE }
function hb-desc-pod { kubectl describe pod -n $env:HB_NAMESPACE }
function hb-desc-ingress { kubectl describe ingress human-benchmark-ingress -n $env:HB_NAMESPACE }

# Quick access to events
function hb-events { kubectl get events -n $env:HB_NAMESPACE --sort-by='.lastTimestamp' }

# Quick access to exec into pods
function hb-exec { kubectl exec -it deployment/human-benchmark -n $env:HB_NAMESPACE -- /bin/sh }

# Quick access to port forward
function hb-port { kubectl port-forward -n $env:HB_NAMESPACE svc/human-benchmark-service 8080:80 }

# Quick access to delete resources
function hb-delete { kubectl delete namespace $env:HB_NAMESPACE }
function hb-delete-pods { kubectl delete pods -l app=human-benchmark -n $env:HB_NAMESPACE }

# Quick access to restart deployment
function hb-restart { kubectl rollout restart deployment/human-benchmark -n $env:HB_NAMESPACE }

# Quick access to scale
function hb-scale { param($replicas) kubectl scale deployment human-benchmark -n $env:HB_NAMESPACE --replicas=$replicas }

# Quick access to get external IP
function hb-ip { kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' }

# Quick access to check status
function hb-status { kubectl rollout status deployment/human-benchmark -n $env:HB_NAMESPACE }

Write-Host "Human Benchmark Kubernetes aliases loaded!" -ForegroundColor Green
Write-Host "Use 'hb-get' to see all resources in the namespace" -ForegroundColor Yellow
