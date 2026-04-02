# Mini Finance Terraform Configuration

This Terraform configuration provisions an EC2 instance on AWS using a modular architecture.

## Architecture Overview

The configuration is organized into three main modules:

### 1. Networking Module (`modules/networking/`)
- Creates a VPC with CIDR block 10.0.0.0/16
- Creates a public subnet (10.0.1.0/24)
- Creates a private subnet (10.0.2.0/24)
- Sets up Internet Gateway for public internet access
- Configures NAT Gateway for private subnet outbound connectivity
- Creates public and private route tables with appropriate routes

### 2. Security Module (`modules/security/`)
- Creates a security group for the EC2 instance
- Allows SSH (port 22) from 0.0.0.0/0
- Allows HTTP (port 80) from 0.0.0.0/0
- Allows all outbound traffic

### 3. EC2 Module (`modules/ec2/`)
- Launches an Ubuntu 22.04 LTS instance in the public subnet
- Instance type: t3.micro
- Configures passwordless SSH authentication using public key
- Uses user_data to set up SSH public key during initialization

## Prerequisites

1. **AWS Account**: You need active AWS credentials configured
2. **Terraform**: Version 1.0 or higher
3. **SSH Key Pair** (Optional): If you want to configure passwordless SSH during EC2 initialization, generate one first:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
   ```
   
   This is optional - you can add your SSH key later to the `terraform.tfvars` file with:
   ```
   ssh_public_key_path = "~/.ssh/id_rsa.pub"
   ```

## Configuration Files

### Root Directory Files
- `providers.tf`: Defines AWS provider configuration
- `main.tf`: Calls the three modules
- `variables.tf`: Input variables with defaults (mini-finance prefix)
- `outputs.tf`: Outputs the public IP of the EC2 instance
- `terraform.tfvars`: Variable values

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Review the Deployment Plan
```bash
terraform plan
```

### 3. Apply the Configuration
```bash
terraform apply
```

### 4. Get the EC2 Instance Public IP
After successful deployment:
```bash
terraform output instance_public_ip
```

### 5. Connect to the Instance
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<instance_public_ip>
```

## Resource Naming Convention

All resources are prefixed with `mini-finance` for easy identification:
- VPC: `mini-finance-vpc`
- Internet Gateway: `mini-finance-igw`
- Public Subnet: `mini-finance-public-subnet`
- Private Subnet: `mini-finance-private-subnet`
- NAT Gateway: `mini-finance-nat-gw`
- Security Group: `mini-finance-ec2-sg`
- EC2 Instance: `mini-finance-instance`

## Customization

Edit `terraform.tfvars` to customize:
- AWS region (default: eu-west-2)
- VPC and subnet CIDR blocks
- Instance type
- SSH public key path

## Destroying Resources

To tear down all resources:
```bash
terraform destroy
```

## Notes

- The SSH public key is configured during instance initialization through user_data
- The instance is placed in the public subnet with automatic public IP assignment
- The NAT Gateway allows private resources to reach the internet while maintaining security
- All resources are tagged with Environment=mini-finance and ManagedBy=Terraform for tracking and cost allocation
