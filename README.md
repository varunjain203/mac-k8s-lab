# Mac K8s Lab

A fully automated Kubernetes cluster setup on macOS using Multipass VMs and Ansible. This project provisions a production-like Kubernetes cluster with configurable master and worker nodes, complete networking, and monitoring capabilities.

## Overview

This repository contains Ansible playbooks and scripts to automate the creation and management of a Kubernetes cluster on macOS. It leverages:

- **Multipass**: Lightweight Ubuntu VM management for macOS
- **Ansible**: Infrastructure-as-code automation
- **Kubeadm**: Kubernetes cluster initialization
- **Calico**: Container Network Interface (CNI) plugin
- **Metrics Server**: Kubernetes metrics collection

The setup is fully configurable, allowing you to specify the number of master/worker nodes and the Kubernetes version at deployment time.

## Prerequisites

### System Requirements
- **macOS** (Intel or Apple Silicon)
- **8GB+ RAM** (minimum, 16GB+ recommended for multi-node clusters)
- **10GB+ free disk space**
- **Ansible 2.9+** installed locally

### Required Tools

1. **Multipass** - VM management tool for macOS
   ```bash
   brew install multipass
   ```

2. **Ansible** - Automation framework
   ```bash
   pip install ansible
   ```

3. **kubectl** - Kubernetes command-line tool (optional, for local testing)
   ```bash
   brew install kubectl
   ```

### SSH Configuration
The setup uses SSH keys for communication between nodes:
- Ensure you have `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub` generated
- If not present, generate them:
  ```bash
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
  ```

## Architecture

The cluster consists of:

```
┌─────────────────────────────────────────┐
│         Local macOS Machine              │
│  (Runs Ansible playbooks & setup.sh)    │
└──────────┬──────────────────────────────┘
           │
           ├─── Multipass VMs ───────────┐
           │                             │
        ┌──▼───────────────────────┐    │
        │ k8s-master-1             │    │
        │ (Control Plane)          │    │
        │ - kubeadm                │    │
        │ - kubectl                │    │
        │ - kubelet                │    │
        │ - Calico CNI             │    │
        │ - Metrics Server         │    │
        └─────────────────────────┘    │
        ┌──────────────────────────┐    │
        │ k8s-worker-1             │    │
        │ - kubelet                │    │
        │ - containerd             │    │
        └──────────────────────────┘    │
        ┌──────────────────────────┐    │
        │ k8s-worker-2             │    │
        │ - kubelet                │    │
        │ - containerd             │    │
        └──────────────────────────┘    │
           │                             │
           └─────────────────────────────┘
```

### Network Configuration
- **Pod Network CIDR**: `10.244.0.0/16` (Calico)
- **VM Network**: `192.168.64.0/24` (Multipass default)

## Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd mac-k8s-lab
```

### 2. Run the Setup Script
```bash
./setup.sh
```

The script will prompt you for:
- **Masters Count**: Number of master nodes (typically 1 or 3 for HA)
- **Workers Count**: Number of worker nodes (typically 2+)
- **Kubernetes Version**: K8s version (e.g., 1.31, 1.32) or press Enter for default (1.31)

### 3. Wait for Cluster to Be Ready
The playbook will:
1. Create VMs using Multipass
2. Install Kubernetes components on all nodes
3. Initialize the master node
4. Join worker nodes to the cluster
5. Install Calico networking
6. Install Metrics Server with kubelet insecure TLS flag

This typically takes **5-10 minutes** depending on your system and internet speed.

## Project Structure

```
mac-k8s-lab/
├── README.md                 # This file
├── setup.sh                  # Main setup script (interactive)
├── destroy.sh                # Cluster cleanup script
├── site.yml                  # Main Ansible playbook
├── ansible.cfg               # Ansible configuration
├── inventory.ini             # Hosts inventory (auto-generated)
├── cluster_vars.yml          # Cluster configuration (auto-generated)
└── roles/                    # Ansible roles
    ├── common/
    │   └── tasks/main.yml    # Common setup for all nodes
    ├── infra/
    │   └── tasks/main.yml    # Infrastructure provisioning (VMs)
    ├── master/
    │   └── tasks/main.yml    # Master node initialization
    └── worker/
        └── tasks/main.yml    # Worker node join setup
```

## Configuration

### Cluster Variables
Edit `cluster_vars.yml` to customize:
```yaml
masters_count: 1           # Number of master nodes
workers_count: 2           # Number of worker nodes
k8s_version: "1.32"        # Kubernetes version
```

### Ansible Configuration
The `ansible.cfg` file contains:
- Inventory file path
- SSH key checking disabled (for convenience in lab environments)

### Customizing Node Names
Edit `roles/infra/tasks/main.yml` to change VM naming or specifications.

## Usage

### View Cluster Status
```bash
# SSH into master node
multipass shell k8s-master-1

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

### Access the Cluster Locally
After successful setup, your kubeconfig is copied to `~/.kube/config`:
```bash
kubectl get nodes
kubectl get pods -A
```

### Deploy Applications
```bash
# Example: Deploy a simple nginx deployment
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=NodePort --port=80
```

### Check Metrics
Verify metrics server is working:
```bash
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
kubectl top pods --all-namespaces
```

## Cleanup

To completely remove the cluster and all VMs:
```bash
./destroy.sh
```

This script will:
1. Read the inventory file
2. Confirm deletion with you
3. Delete all Multipass VMs
4. Preserve local configuration for reference

## Components Installed

### On All Nodes
- **containerd**: Container runtime
- **kubelet**: Node agent
- **kubeadm**: Cluster provisioning tool
- **kubectl**: CLI tool
- **conntrack**: Connection tracking for networking
- **Kernel modules**: overlay, br_netfilter

### On Master Node(s)
- Kubernetes control plane components
- etcd (distributed database)
- Calico CNI plugin
- Metrics Server

### Networking
- **Calico**: Pod-to-pod networking
- **Pod CIDR**: 10.244.0.0/16

## Troubleshooting

### Nodes Not Joining
```bash
# Check kubelet logs on worker
multipass shell k8s-worker-1
journalctl -u kubelet -n 50
```

### Pods Not Starting
```bash
# Check if CNI plugin (Calico) is ready
kubectl get daemonset -n kube-system
kubectl describe pod <pod-name> -n kube-system
```

### Metrics Server Issues
```bash
# Check metrics server logs
kubectl logs -n kube-system deployment/metrics-server
kubectl top nodes  # Should work once metrics are available
```

### VM Creation Issues
```bash
# Check Multipass status
multipass list
multipass info k8s-master-1
```

### Ansible Connectivity Issues
```bash
# Test SSH to a node
ssh -i ~/.ssh/id_rsa ubuntu@192.168.64.29
```

## Security Considerations

This is a **lab environment** for learning and testing. For production use:

1. **Disable SSH key checking** in ansible.cfg (currently disabled for convenience)
2. **Use proper RBAC** instead of admin kubeconfig everywhere
3. **Enable TLS verification** for kubelet (currently disabled via --kubelet-insecure-tls)
4. **Use network policies** to restrict traffic
5. **Implement pod security policies** or Pod Security Standards
6. **Regular security updates** and patching
7. **Backup etcd** regularly if using multi-master setup

## Known Issues

- **Apple Silicon Macs**: May experience performance variations
- **Multipass Networking**: Limited to 192.168.64.0/24 by default
- **Memory Pressure**: With limited resources, nodes may take time to become ready

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Calico Networking](https://www.tigera.io/project-calico/)
- [Kubeadm Documentation](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)
- [Ansible Documentation](https://docs.ansible.com/)

## License

This project is provided as-is for educational purposes.

## Contributing

Suggestions and improvements are welcome! Feel free to:
- Report issues
- Suggest enhancements
- Submit pull requests
- Improve documentation

## FAQ

**Q: Can I use this on Linux?**
A: The setup is designed for macOS with Multipass, but you can adapt it for Linux with appropriate VM management tools.

**Q: How much resource does each VM use?**
A: By default, Multipass allocates 1 CPU and 1GB RAM per VM. Adjust in `roles/infra/tasks/main.yml` as needed.

**Q: Can I add more workers after initial setup?**
A: Yes, modify `cluster_vars.yml` and run the setup script again. Existing nodes will be preserved.

**Q: Is this suitable for production?**
A: No, this is designed for lab and learning purposes. See Security Considerations section.

