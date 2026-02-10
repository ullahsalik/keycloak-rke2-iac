#!/bin/bash
set -e

curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE=server sh -

sudo mkdir -p /etc/rancher/rke2
cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
tls-san:
  - localhost
disable:
  - rke2-ingress-nginx
write-kubeconfig-mode: "0644"
EOF

sudo systemctl enable rke2-server
sudo systemctl start rke2-server

