
# 🛡️ Keycloak Deployment: RKE2 + Pulumi (IaC)

This repository provides a complete automation pipeline to deploy a hardened, single-node **RKE2** Kubernetes cluster and a **Keycloak** instance with a PostgreSQL backend and self-signed certificate.

## 📋 Project Overview

* **Provisioning**: Bootstraping the RKE2 single node cluster using ansible.
* **Configuration**: Kubeconfig management on local
* **Deployment**: Pulumi Python (Keycloak + PostgreSQL)
* **Security**: Self-signed HTTPS/TLS, automated secret management.

## Prerequisites
- Local Machine: Ansible, Pulumi (Python), and kubectl installed.
- Target Node: A fresh Ubuntu 24.04/25.04 VM with SSH access.
- Network: Ports 80, 443, and 6443 must be open.

---

### Step 1: Bootstraping the RKE2 single node cluster using Ansible

First clone this git repo on local, we use Ansible to install RKE2 on Ubuntu VM. RKE2 is a secure-by-default Kubernetes distribution.

1. **Update Inventory**:
Edit `rke2-bootstrap/inventory/hosts.ini` (or your equivalent) with new VM's IP:

```ini
[rke2]
rke2-master ansible_host=<host-ip> ansible_port=22

[rke2:vars]
ansible_user=<vm-username>
ansible_become=true
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=<private-key path>
```


2. **Run the Playbook**:
Execute the RKE2 installation script:
```bash
cd rke2-bootstrap
ansible-playbook playbooks/rke2-install.yml
```


*This script installs the RKE2 server, enables the service, and prepares the cluster.*

---

### Step 2: Accessing the Cluster

Once Ansible completes, we need to pull the cluster credentials (`kubeconfig`) from the VM to our local machine so Pulumi can deploy to it.

1. **Copy the k8s Config**:
```bash
# Create a local dir for the config
mkdir -p ~/.kube

# SCP the rke2.yaml from the VM to your local machine
scp ubuntu@<VM-IP>:~/.kube/config ~/.kube/config-rke2
```

2. **Update the IP Address**:
Open `~/.kube/config-rke2` locally and change the server URL from `https://127.0.0.1:6443` to `https://<VM-IP>:6443`.

3. **Set your Environment**:
```bash
export KUBECONFIG=~/.kube/config-rke2

# Verify connection
kubectl get nodes
```

---

### Step 3: Application Deployment (Pulumi)

With cluster access verified, use Pulumi to deploy the application stack.

1. Log in to the Local Filesystem
```sh
cd keycloak-rke2-iac/pulumi/
pulumi login --local
```

2. Set the Local Configuration for kube config file
``` 
pulumi config set kubernetes:configPath ~/.kube/config-rke2 
```

3. Initialize Pulumi Secrets for DB:
```bash
pulumi config set dbPassword --secret
```

2. **Deploy**:
```bash
pulumi up
```

*Pulumi will now deploy PostgreSQL and Keycloak, including the Ingress and TLS secrets we configured.*

---

### Step 4: Accessing the Keycloak Dashboard

Since we are using `keycloak.local`, you must map the IP address in your local machine's `hosts` file.

1. **Update Local Hosts File**:
* **Linux/Mac**: `sudo vim /etc/hosts`
* **Windows**: `notepad C:\Windows\System32\drivers\etc\hosts` (as Admin)

Add this line:
```text
<VM-IP>  keycloak.local
```

2. **Retrieve the Admin Password (Decoded)**:

```bash
kubectl get secret keycloak -o jsonpath='{.data.admin-password}' | base64 --decode
```

3. **Open the Dashboard**:
Navigate to [https://keycloak.local](https://www.google.com/search?q=https://keycloak.local) in your browser.
> **Note**: Because we are using a self-signed certificate, you will see a "Not Secure" warning. Click **Advanced** -> **Proceed to keycloak.local (unsafe)** to reach the login page.