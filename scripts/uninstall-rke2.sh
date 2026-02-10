#!/bin/bash

set -euo pipefail

echo "=============================="
echo " Cleaning Kubernetes resources"
echo "=============================="

# Delete app deployments & services
for app in nginx ui-app; do
  echo "Deleting deployment: $app"
  kubectl delete deployment "$app" --ignore-not-found

  echo "Deleting service: $app"
  kubectl delete service "$app" --ignore-not-found
done

echo
echo "=============================="
echo " Removing Rancher & Cert-Manager"
echo "=============================="

# Uninstall Helm releases
helm uninstall rancher -n cattle-system || true
helm uninstall cert-manager -n cert-manager || true

# Delete namespaces
kubectl delete ns cattle-system --ignore-not-found
kubectl delete ns cert-manager --ignore-not-found

echo
echo "=============================="
echo " Stopping RKE2 services"
echo "=============================="

# Detect node role
if systemctl list-units --type=service | grep -q rke2-server; then
  echo "Master node detected"
  sudo systemctl stop rke2-server
  sudo systemctl disable rke2-server
fi

if systemctl list-units --type=service | grep -q rke2-agent; then
  echo "Worker node detected"
  sudo systemctl stop rke2-agent
  sudo systemctl disable rke2-agent
fi

echo
echo "=============================="
echo " Uninstalling RKE2"
echo "=============================="

# Uninstall RKE2 (path differs per install)
if [ -x /usr/local/bin/rke2-uninstall.sh ]; then
  sudo /usr/local/bin/rke2-uninstall.sh
elif [ -x /usr/bin/rke2-uninstall.sh ]; then
  sudo /usr/bin/rke2-uninstall.sh
else
  echo "RKE2 uninstall script not found"
fi

echo
echo "=============================="
echo " Cleanup completed successfully"
echo "=============================="

