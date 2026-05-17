#!/bin/bash
echo ""
echo "Welcome to the Macbook Kubernetes Lab Setup"
echo "Masters are fixed to 1 in this lab"
MASTERS=1
echo ""
read -p "---- How many Workers you want to spin up ? : ----" WORKERS
read -p "---- Enter Kubernetes Version (default 1.31) (example: 1.31): -----" K8S_VERSION

K8S_VERSION=${K8S_VERSION:-1.31}

cat <<EOF > cluster_vars.yml
masters_count: $MASTERS
workers_count: $WORKERS
k8s_version: "$K8S_VERSION"
EOF

export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook site.yml -e "@cluster_vars.yml"