#!/bin/bash

set -euo pipefail

INVENTORY="inventory.ini"

if [ ! -f "$INVENTORY" ]; then
    echo "Error: $INVENTORY not found. Did you already delete the cluster?"
    exit 1
fi

echo "--> Detecting nodes from $INVENTORY..."

# Extract node names from the inventory file
# It looks for lines that start with k8s- or haproxy
NODES=$(grep -E "^(k8s-|haproxy)" "$INVENTORY" | awk '{print $1}' | sort -u || true)

if [ -z "$NODES" ]; then
    echo "No nodes found to destroy."
    exit 0
fi

echo "The following nodes will be deleted and purged:"
echo "$NODES"
read -r -p "Are you sure? (y/N): " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "--> Destroying nodes..."
    # shellcheck disable=SC2086
    multipass delete $NODES

    echo "--> Purging deleted VMs to reclaim disk space..."
    multipass purge

    echo "--> Removing local configuration files..."
    rm -f inventory.ini cluster_vars.yml
    
    echo "Done! Your Mac is clean."
else
    echo "Cleanup aborted."
fi