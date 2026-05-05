#!/bin/bash
read -p "Masters: " MASTERS
read -p "Workers: " WORKERS
read -p "Kubernetes Version (e.g., 1.29): " K8S_VERSION

K8S_VERSION=${K8S_VERSION:-1.29}

cat <<EOF > cluster_vars.yml
masters_count: $MASTERS
workers_count: $WORKERS
k8s_version: "$K8S_VERSION"
EOF

export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook site.yml -e "@cluster_vars.yml"