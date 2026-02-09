#!/usr/bin/env bash
set -euo pipefail

echo "Installing RKE2 (single-node cluster)"

# ---------- Pre-flight ----------
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (or with sudo)"
  exit 1
fi

echo "Disabling swap"
swapoff -a
sed -i.bak '/ swap / s/^/#/' /etc/fstab || true

echo "Loading kernel modules"
cat <<EOF >/etc/modules-load.d/rke2.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo "Applying sysctl settings"
cat <<EOF >/etc/sysctl.d/rke2.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# ------ Install RKE2 ----------
echo "Installing RKE2 server"
curl -sfL https://get.rke2.io | sh -

echo "Enabling RKE2 service"
systemctl enable rke2-server
systemctl start rke2-server

echo "Applying rke2/config.yaml settings"
cat <<EOF >/etc/rancher/rke2/config.yaml
write-kubeconfig-mode: "0644"
EOF

# ------ Kubeconfig ----------
echo "Setting up kubeconfig"
mkdir -p ~/.kube
sudo cp /etc/rancher/rke2/rke2.yaml ~/.kube/config
sudo chown $(whoami):$(whoami) ~/.kube/config

echo "Waiting for Kubernetes API ready..."
until /var/lib/rancher/rke2/bin/kubectl get nodes >/dev/null 2>&1; do
  sleep 5
done

# Update server address to localhost
sed -i 's/127.0.0.1/localhost/' $HOME/.kube/config

# ---------- Export binaries ----------
echo "Exporting kubectl & crictl"
export PATH=$PATH:/var/lib/rancher/rke2/bin

cat <<EOF >/etc/profile.d/rke2.sh
export PATH=\$PATH:/var/lib/rancher/rke2/bin
EOF

echo "RKE2 installation complete"
echo "Run: kubectl get nodes"

