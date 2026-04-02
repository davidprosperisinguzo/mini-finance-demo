#!/bin/bash
# Quick deployment script for Mini Finance

set -e

echo "=================================================="
echo "Mini Finance - Ansible Deployment Script"
echo "=================================================="
echo ""

# Check prerequisites
echo "[*] Checking prerequisites..."

if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible is not installed"
    echo "   Install: pip install ansible"
    exit 1
fi
echo "✓ Ansible $(ansible --version | head -1)"

if ! command -v terraform &> /dev/null; then
    echo "⚠️  Terraform is not found (optional, needed if deploying EC2)"
fi

# Get public IP from Terraform if available
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

if [ -d "$TERRAFORM_DIR" ]; then
    echo ""
    echo "[*] Getting EC2 public IP from Terraform..."
    
    if [ -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
        cd "$TERRAFORM_DIR"
        PUBLIC_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")
        cd "$SCRIPT_DIR"
        
        if [ -n "$PUBLIC_IP" ]; then
            echo "✓ Public IP: $PUBLIC_IP"
            
            # Update inventory
            echo ""
            echo "[*] Updating inventory with public IP..."
            sed -i "s/<public_ip>/$PUBLIC_IP/" "$SCRIPT_DIR/inventory.ini"
            echo "✓ Inventory updated"
        else
            echo "⚠️  Could not retrieve public IP from Terraform"
            echo "   Please manually update inventory.ini with the EC2 public IP"
        fi
    else
        echo "⚠️  Terraform state not found"
        echo "   Please manually update inventory.ini with the EC2 public IP"
    fi
fi

# Verify SSH connectivity
echo ""
echo "[*] Testing SSH connectivity..."
if ansible web -i "$SCRIPT_DIR/inventory.ini" -m ping -q 2>/dev/null; then
    echo "✓ SSH connectivity verified"
else
    echo "❌ SSH connectivity failed"
    echo "   Ensure the EC2 instance is running and the inventory.ini is correct"
    exit 1
fi

# Run the playbook
echo ""
echo "[*] Running Ansible playbook..."
echo "=================================================="
ansible-playbook "$SCRIPT_DIR/site.yml" "$@"

echo ""
echo "=================================================="
echo "✓ Deployment completed successfully!"
echo "=================================================="
