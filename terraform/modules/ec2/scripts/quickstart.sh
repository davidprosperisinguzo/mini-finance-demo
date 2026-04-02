#!/bin/bash
# Quick start script for Terraform AWS VM provisioning

set -e

echo "======================================"
echo "Terraform AWS VM Provisioning Setup"
echo "======================================"

# Check prerequisites
echo ""
echo "Checking prerequisites..."

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed"
    echo "   Please install Terraform from https://www.terraform.io/downloads"
    exit 1
fi
echo "✓ Terraform $(terraform version -json | jq -r '.terraform_version')"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed"
    echo "   Please install AWS CLI from https://aws.amazon.com/cli/"
    exit 1
fi
echo "✓ AWS CLI installed"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials are not configured"
    echo "   Run: aws configure"
    exit 1
fi
echo "✓ AWS credentials configured"

# Check SSH key
if [ ! -f ~/.ssh/id_ed25519.pub ]; then
    echo "⚠️  SSH key not found at ~/.ssh/id_ed25519.pub"
    read -p "Generate SSH key now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
        echo "✓ SSH key generated"
    else
        echo "❌ SSH key is required to proceed"
        exit 1
    fi
else
    echo "✓ SSH key found at ~/.ssh/id_ed25519.pub"
fi

# Initialize Terraform
echo ""
echo "Initializing Terraform..."
terraform init

# Validate configuration
echo ""
echo "Validating Terraform configuration..."
terraform validate

# Plan deployment
echo ""
echo "Planning infrastructure..."
terraform plan -out=tfplan

# Confirm and apply
echo ""
read -p "Ready to apply? This will create AWS resources. Continue? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Applying Terraform configuration..."
    terraform apply tfplan
    
    echo ""
    echo "======================================"
    echo "✓ Infrastructure deployed successfully!"
    echo "======================================"
    echo ""
    echo "Instance Information:"
    terraform output instance_details
    echo ""
    echo "SSH Commands:"
    terraform output ssh_connections
    echo ""
    echo "Public IPs:"
    terraform output instance_public_ips_list
else
    echo "Deployment cancelled"
    rm -f tfplan
fi
