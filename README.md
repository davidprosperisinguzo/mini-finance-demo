# Mini Finance - Complete Infrastructure as Code Project

A comprehensive Infrastructure as Code (IaC) solution for provisioning and deploying the Mini Finance application on AWS using Terraform for infrastructure and Ansible for application deployment.

> **IMPORTANT**: Before using this project, please read the [Security & Warnings](#security--warnings) section below.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Security & Warnings](#security--warnings)
- [Important Notes for Others](#important-notes-for-others)
- [Detailed Documentation](#detailed-documentation)
- [Support & Issues](#support--issues)

## Project Overview

This project automates the complete lifecycle of deploying a Mini Finance web application:

1. **Terraform** provisions cloud infrastructure on AWS (VPC, Subnets, Security Groups, EC2 instance)
2. **Ansible** configures the instance, installs Nginx, deploys the application, and verifies the deployment

The entire stack is designed for learning, demos, and proof-of-concept deployments. It follows infrastructure and configuration management best practices with modular architecture.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud (eu-west-2)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  VPC: 10.0.0.0/16                                               │
│  ├─ Public Subnet: 10.0.1.0/24                                 │
│  │  ├─ Internet Gateway                                         │
│  │  └─ EC2 Instance (t3.micro, Ubuntu 22.04 LTS)              │
│  │     ├─ Nginx Web Server (Port 80)                           │
│  │     └─ Mini Finance Application                             │
│  │                                                               │
│  └─ Private Subnet: 10.0.2.0/24                                │
│     └─ NAT Gateway (for future private resources)              │
│                                                                   │
│  Security Group: mini-finance-ec2-sg                            │
│  ├─ Ingress: SSH (22) from 0.0.0.0/0                          │
│  ├─ Ingress: HTTP (80) from 0.0.0.0/0                         │
│  └─ Egress: All traffic to 0.0.0.0/0                          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
mini-finance-demo/
├── README.md                          # This file
├── terraform/                         # Infrastructure as Code
│   ├── main.tf                        # Root module calling sub-modules
│   ├── providers.tf                   # AWS provider configuration
│   ├── variables.tf                   # Input variables
│   ├── outputs.tf                     # Output: EC2 public IP
│   ├── terraform.tfvars               # Variable values
│   ├── README.md                      # Terraform documentation
│   └── modules/
│       ├── networking/                # VPC, Subnets, Gateways, Routes
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── security/                  # Security Groups
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── ec2/                       # EC2 Instance
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           └── scripts/
│               ├── user_data.sh       # SSH key setup
│               └── quickstart.sh      # Prerequisites validation
│
└── ansible/                           # Configuration Management
    ├── site.yml                       # Main playbook
    ├── inventory.ini                  # Host inventory
    ├── ansible.cfg                    # Ansible configuration
    ├── README.md                      # Ansible documentation
    ├── QUICKSTART.md                  # Quick start guide
    └── roles/
        ├── nginx/                     # Install & Configure Nginx
        │   ├── tasks/main.yml
        │   ├── handlers/main.yml
        │   └── ... (other role dir
        ├── deployment/                # Clone & Deploy Application
        │   ├── tasks/main.yml
        │   ├── handlers/main.yml
        │   └── ... (other role dirs)
        └── verification/              # Verify Deployment
            ├── tasks/main.yml
            └── ... (other role dirs)
```

## Component Details

### Terraform - Infrastructure Provisioning

Terraform creates the complete AWS infrastructure using a modular architecture with three main modules:

#### Networking Module (`terraform/modules/networking/`)
Creates the network foundation:
- **VPC**: CIDR block 10.0.0.0/16
- **Public Subnet**: 10.0.1.0/24 with automatic public IP assignment
- **Private Subnet**: 10.0.2.0/24 for future private resources
- **Internet Gateway**: Enables public subnet internet access
- **NAT Gateway**: Enables private subnet outbound connectivity
- **Route Tables**: Public and private routes with appropriate associations

**Resources**: `mini-finance-vpc`, `mini-finance-igw`, `mini-finance-nat-gw`, `mini-finance-*-subnet`, `mini-finance-*-rt`

#### Security Module (`terraform/modules/security/`)
Creates security policies:
- **Security Group**: `mini-finance-ec2-sg`
  - **Inbound**: SSH (22) and HTTP (80) from 0.0.0.0/0
  - **Outbound**: All traffic to 0.0.0.0/0

#### EC2 Module (`terraform/modules/ec2/`)
Provisions the compute instance:
- **Instance Type**: t3.micro (cost-optimized)
- **OS**: Ubuntu 22.04 LTS (latest LTS)
- **AMI**: Canonical's official Ubuntu image
- **Placement**: Public subnet with auto-assigned public IP
- **Security**: Security group and SSH public key authentication

**Resource**: `mini-finance-instance`

#### Terraform Root Configuration
- **Output**: Exports EC2 public IP for Ansible inventory
- **Provider**: AWS with eu-west-2 region
- **Tags**: All resources tagged with `Environment=mini-finance`, `ManagedBy=Terraform`, `Project=mini-finance`

### Ansible - Configuration Management & Deployment

Ansible configures the EC2 instance, deploys the application, and verifies the deployment using a single playbook with three roles:

#### Nginx Role (`ansible/roles/nginx/`)
**Purpose**: Install and configure the web server

**Tasks**:
1. Update system package cache
2. Install Nginx and Git
3. Start and enable Nginx service
4. Configure Nginx for Single Page Application (SPA) serving:
   - Listens on port 80
   - Serves from `/var/www/html`
   - Routes all requests to `index.html` (SPA routing)
   - Handles 404 errors by serving `index.html` (SPA fallback)
5. Enable the default site

**Handlers**:
- `reload nginx`: Gracefully reloads Nginx when configuration changes

#### Deployment Role (`ansible/roles/deployment/`)
**Purpose**: Clone and deploy the Mini Finance application

**Tasks**:
1. Clone Mini Finance repository from GitHub:
   - Repository: `https://github.com/pravinmishraaws/mini-finance-project`
   - Destination: `/tmp/mini_finance`
   - Uses `force: yes` for idempotency
2. Create `/var/www/html` directory with proper ownership
3. Synchronize cloned content to web root using `rsync`
4. Set ownership to `www-data:www-data` (Nginx user)
5. Flush handlers to trigger Nginx reload on changes

**Handlers**:
- `reload nginx on content changes`: Gracefully reloads Nginx when site content is deployed

#### Verification Role (`ansible/roles/verification/`)
**Purpose**: Verify the deployment is successful and accessible

**Tasks**:
1. Wait for Nginx to be ready (with 5 retries, 5-second intervals)
2. Send HTTP GET request to the deployed site
3. Assert HTTP response status is 200
4. Display verification results (URL, status code, content-type)

**Runs on**: localhost (no SSH required)

### Ansible Playbook (`ansible/site.yml`)

Single play targeting the `web` group:

```yaml
- name: Mini Finance - Install, Deploy, and Verify
  hosts: web
  become: yes
  gather_facts: yes
  
  roles:
    - role: nginx           # Install & configure
    - role: deployment      # Deploy application
    - role: verification    # Verify success (delegated to localhost)
```

**Features**:
- Single play, three roles executed sequentially
- `become: yes` for root privilege escalation
- `gather_facts: yes` for system information
- Tags for selective execution: `--tags nginx`, `--tags deployment`, `--tags verification`
- Idempotent: safe to run multiple times

### Ansible Inventory (`ansible/inventory.ini`)

Defines target hosts and SSH configuration:

```ini
[web]
<public_ip>              # EC2 instance public IP (from Terraform output)

[web:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
```

## Integration Flow

### Deployment Sequence

```
1. TERRAFORM PHASE
   ├─ Initialize: terraform init
   ├─ Plan: terraform plan
   └─ Apply: terraform apply
       ├─ Creates VPC, Subnets, IGW, NAT
       ├─ Creates Security Group
       ├─ Provisions EC2 Instance (Ubuntu 22.04)
       └─ Outputs: instance_public_ip
       
2. RETRIEVE PUBLIC IP
   └─ terraform output instance_public_ip
   
3. UPDATE ANSIBLE INVENTORY
   └─ sed -i "s/<public_ip>/$PUBLIC_IP/" ansible/inventory.ini
   
4. ANSIBLE PHASE
   └─ ansible-playbook ansible/site.yml
       ├─ Play: Mini Finance - Install, Deploy, and Verify
       ├─ Role 1 - nginx
       │  ├─ Update apt cache
       │  ├─ Install Nginx and Git
       │  ├─ Configure Nginx for SPA
       │  └─ Start and enable service
       │
       ├─ Role 2 - deployment
       │  ├─ Clone mini-finance-project repo
       │  ├─ Sync to /var/www/html
       │  ├─ Set proper ownership
       │  └─ Gracefully reload Nginx
       │
       └─ Role 3 - verification (delegated to localhost)
          ├─ Wait for Nginx readiness
          ├─ Test HTTP connectivity
          ├─ Assert status 200
          └─ Display results
```

### Data Flow

```
Terraform Outputs (outputs.tf)
└─ instance_public_ip
   └─ Ansible Inventory (inventory.ini)
      └─ SSH Connection to EC2
         └─ Ansible Playbook Execution
            ├─ Role: nginx
            ├─ Role: deployment
            └─ Role: verification
               └─ HTTP Tests from localhost
                  └─ Deployment verification complete
```

## Prerequisites

### Local System Requirements
- **Terraform**: Version 1.0 or higher
- **Ansible**: Version 2.9 or higher
- **AWS CLI**: For credential configuration
- **SSH Client**: For local SSH key generation
- **Python 3**: System Python for Ansible

### AWS Requirements
- Active AWS account with credentials configured
- Appropriate IAM permissions for creating VPC, subnets, security groups, and EC2 instances
- EC2 keypair or ability to create one

### SSH Keys
Generate SSH keypair for passwordless authentication using ED25519 (recommended):

```bash
# Generate ED25519 key (modern, secure, smaller than RSA)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Or use RSA if you prefer (traditional, widely supported)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

**Note**: Update `terraform/terraform.tfvars` with the path to your public key (see [Configuration](#configuration) section)

### Example Configuration Files

This project includes example configuration files to help you get started:

- **[terraform/terraform.tfvars.example](terraform/terraform.tfvars.example)** - Example Terraform variables file
- **[ansible/inventory.ini.example](ansible/inventory.ini.example)** - Example Ansible inventory file

To use these templates:
```bash
# Copy terraform example to actual config
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit with your values
vim terraform/terraform.tfvars

# Copy ansible example to actual inventory
cp ansible/inventory.ini.example ansible/inventory.ini
# Will be updated automatically during deployment
```

## Deployment Instructions

### Step 1: Configure AWS Credentials

```bash
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region, Output format
```

### Step 2: Deploy Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform working directory
terraform init

# Review the deployment plan
terraform plan

# Apply the configuration
terraform apply

# Retrieve the EC2 public IP
PUBLIC_IP=$(terraform output -raw instance_public_ip)
echo "EC2 Public IP: $PUBLIC_IP"
```

### Step 3: Update Ansible Inventory

```bash
cd ../ansible

# Update inventory with the EC2 public IP
sed -i "s/<public_ip>/$PUBLIC_IP/" inventory.ini

# Verify the update
cat inventory.ini
```

### Step 4: Verify SSH Connectivity

```bash
# Test Ansible connectivity to the web host
ansible web -i inventory.ini -m ping

# Expected output:
# <public_ip> | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

### Step 5: Run the Ansible Playbook

```bash
# Execute the complete playbook
ansible-playbook site.yml

# Or with verbose output for debugging
ansible-playbook site.yml -v

# Or run specific roles only
ansible-playbook site.yml --tags nginx
ansible-playbook site.yml --tags deployment
ansible-playbook site.yml --tags verification
```

### Step 6: Access the Deployed Application

```bash
# Open the application in a browser
http://<public_ip>

# Or test with curl
curl http://$PUBLIC_IP

# Expected output: Mini Finance HTML content
```

## Security & Warnings

### CRITICAL: Network Security Issues

This project is **NOT suitable for production use** without significant security modifications. The current configuration has the following limitations:

#### Issue 1: Worldwide SSH Access (0.0.0.0/0)
```hcl
# Current configuration allows SSH from anywhere
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # INSECURE: Entire internet can attempt SSH
}
```

**Risk**: Brute force attacks, unauthorized access attempts, bot scanning

**Production Fix**: Restrict to your IP or VPN CIDR block
```hcl
cidr_blocks = ["203.0.113.0/32"]  # Replace with your IP
# Or use your VPN CIDR: ["10.1.0.0/16"]
```

#### Issue 2: Worldwide HTTP Access (0.0.0.0/0)
```hcl
# Current configuration allows HTTP from anywhere
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Wide open, but application-specific
}
```

**Risk**: DDoS attacks, scrapers, competitors monitoring uptime

**Production Fix**: Use CloudFront + WAF, restrict to known IP ranges, or use HTTPS-only with rate limiting

#### Issue 3: No HTTPS/TLS
The deployment uses HTTP only (port 80). In production:
- Add SSL/TLS certificate (AWS Certificate Manager)
- Redirect HTTP → HTTPS
- Enable security headers (HSTS, CSP, etc.)

#### Issue 4: SSH Key Management
```bash
# Current: Local SSH key file
ssh_public_key_path = "~/.ssh/id_rsa.pub"
```

**Risk**: SSH private key on local machine, if compromised = EC2 compromise

**Production Fix**:
- Use AWS Systems Manager Session Manager (no SSH keys needed)
- Use IAM roles for EC2 instance authentication
- Rotate SSH keys regularly
- Store in AWS Secrets Manager, not local filesystem

#### Issue 5: No Encryption for Terraform State
```bash
# Current: Local terraform.tfstate file
terraform.tfstate  # Contains: SSH public key, AWS resource IDs, etc.
```

**Risk**: State file contains sensitive data; if laptop compromised = infrastructure compromised

**Production Fix**:
- Enable S3 remote state with encryption
- Enable DynamoDB state locking
- Use AWS KMS to encrypt state at rest
- Enable S3 versioning and MFA delete

#### Issue 6: Security Group Lifecycle
The security group rules are open during development. Always:
- Close ports when not in use
- Use `terraform destroy` when done testing
- Never leave test infrastructure running 24/7 (costs + exposure)

#### Issue 7: No Infrastructure Monitoring
No CloudWatch alarms, logging, or intrusion detection. Add:
- VPC Flow Logs for network traffic analysis
- CloudWatch alarms for failed SSH attempts
- AWS GuardDuty for threat detection
- CloudTrail for API audit logging

### Data Sensitivity Classification
| Data | Current | Production |
|------|---------|-----------|
| Terraform State | Local file | S3 + encryption + locking |
| SSH Private Key | Local ~/.ssh/ | AWS Secrets Manager or SSM Param Store |
| AWS Credentials | AWS CLI ~/.aws/ | IAM roles + STS temporary credentials |
| Application Secrets | None configured | AWS Secrets Manager |
| Logs | EC2 local | CloudWatch Logs |
| Database (if added) | N/A | Encrypted RDS, no public IP |

### Security Checklist for Deployment

Before using this project:

- [ ] Read and understand all warnings above
- [ ] This is for **learning, demos, and testing ONLY**
- [ ] Do **not** use production data with this configuration
- [ ] Use in isolated **development AWS account**
- [ ] Run only when actively testing (destroy when done)
- [ ] Monitor AWS billing (NAT Gateway costs: ~$0.045/hour)
- [ ] Understand you are creating resources **publicly accessible**
- [ ] Have AWS credentials secured and never commit them to git
- [ ] Review `terraform/README.md` for configuration details

## Important Notes for Others

### Before You Deploy

1. **This is Educational Content**
   - Designed for learning infrastructure-as-code (IaC) concepts
   - Shows practical Terraform + Ansible integration
   - Should NOT be used as a template for production systems
   - Follow the security warnings above carefully

2. **Customization for Your Environment**

   **Change AWS Region:**
   ```hcl
   # In terraform/terraform.tfvars
   aws_region = "us-east-1"  # Change to your preferred region
   ```

   **Adjust Network CIDR Blocks:**
   ```hcl
   # In terraform/terraform.tfvars
   vpc_cidr            = "10.1.0.0/16"        # Change VPC range
   public_subnet_cidr  = "10.1.1.0/24"        # Change public subnet
   private_subnet_cidr = "10.1.2.0/24"        # Change private subnet
   ```

   **Change EC2 Instance Type:**
   ```hcl
   # In terraform/terraform.tfvars
   instance_type = "t3.small"  # Or t3.medium, etc.
   ```

   **Update Git Repository:**
   ```yaml
   # In ansible/roles/deployment/tasks/main.yml
   - name: Clone Mini Finance repository
     git:
       repo: "https://github.com/YOUR_USERNAME/your-app-repo.git"  # Change this
       dest: /tmp/mini_finance
       version: main
   ```

3. **Cost Implications**
   - **EC2 t3.micro**: ~$0.0104/hour (may be free tier eligible)
   - **NAT Gateway**: ~$0.045/hour + $0.045 per GB processed (~$32/month minimum)
   - **Data Transfer**: ~$0.02/GB out + $0.01/GB inter-region
   - **Total Estimate**: $50-100/month if running continuously

   **Cost Optimization Tips**:
   ```hcl
   # Remove NAT Gateway if not needed for private subnet
   # Use t3.micro only (free tier eligible)
   # Destroy when not actively testing: terraform destroy
   # Use Spot instances for even lower cost (add to main.tf)
   ```

4. **Recommended Modifications for Production**

   **Add HTTPS Support:**
   ```bash
   # Install certbot in nginx role
   - name: Install Certbot
     apt:
       name: certbot python3-certbot-nginx
       state: present

   # Create Let's Encrypt certificate
   - name: Request SSL certificate
     shell: certbot certonly --nginx -d your-domain.com --non-interactive
   ```

   **Implement IAM Roles Instead of SSH Keys:**
   ```hcl
   # In modules/ec2/main.tf - replace SSH key auth with IAM role
   iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

   # Add this to modules/security/main.tf
   resource "aws_iam_role" "ec2_role" {
     name = "mini-finance-ec2-role"
     assume_role_policy = jsonencode({...})
   }
   ```

   **Enable S3 Backend for State:**
   ```hcl
   # Create terraform/backend.tf
   terraform {
     backend "s3" {
       bucket         = "your-terraform-state"
       key            = "mini-finance/terraform.tfstate"
       region         = "eu-west-2"
       encrypt        = true
       dynamodb_table = "terraform-locks"
     }
   }
   ```

   **Add VPC Flow Logs:**
   ```hcl
   # In modules/networking/main.tf
   resource "aws_flow_log" "main" {
     iam_role_arn    = aws_iam_role.flow_log.arn
     log_destination = aws_cloudwatch_log_group.flow_log.arn
     traffic_type    = "ALL"
     vpc_id          = aws_vpc.main.id
   }
   ```

   **Restrict Security Group by IP:**
   ```hcl
   # In modules/security/main.tf
   variable "allowed_ssh_cidr" {
     default = "0.0.0.0/0"  # Change to your IP!
   }

   # Then use: cidr_blocks = [var.allowed_ssh_cidr]
   ```

5. **Scaling Considerations**
   - **Database**: Add RDS PostgreSQL instead of file-based data
   - **Load Balancing**: Add ALB in front of EC2 for multi-instance deployments
   - **Auto Scaling**: Replace single EC2 with ASG + launch template
   - **CDN**: Use CloudFront for static assets
   - **Container Migration**: Convert to ECS for easier scaling and updates

6. **What to Look Out For**

   | Issue | Symptom | Fix |
   |-------|---------|-----|
   | Terraform state corruption | `Error reading provider config` | Revert from git history, don't edit state directly |
   | SSH key permissions | `Permissions 0644 are too open` | Run `chmod 600 ~/.ssh/id_rsa` |
   | Ansible inventory stale | Playbook connects to wrong IP | Update inventory.ini with new public IP |
   | Nginx handler not firing | Content changes don't reload | Check handler name matches task notify |
   | NAT Gateway overages | Unexpected AWS bill spike | Check data transfer, consider removing NAT |
   | Git repo doesn't exist | Clone fails in deployment | Verify repo URL, ensure public access |
   | SELinux/AppArmor restrictions | Nginx can't write files | Check file permissions (stat /var/www/html) |

7. **Teardown & Cleanup**

   Always clean up when done testing:
   ```bash
   cd terraform
   terraform destroy --auto-approve  # Destroy all AWS resources
   rm -f terraform.tfstate*           # Remove local state
   rm -f inventory.ini                # Remove generated inventory
   ```

   Never leave test infrastructure running to avoid unexpected costs.

## Verification

### Terraform Outputs

```bash
cd terraform
terraform output
```

Shows:
- VPC ID
- Public/Private Subnet IDs
- Internet Gateway ID
- NAT Gateway ID
- EC2 Instance ID and Public IP

### Ansible Playbook Output

The playbook displays:
1. **Nginx Installation**: Confirms service started and enabled
2. **Deployment**: Shows repository cloned and content synced
3. **Verification**: Confirms HTTP 200 status and site accessibility

### Manual Verification

```bash
# SSH into the instance
ssh -i ~/.ssh/id_rsa ubuntu@<public_ip>

# Check Nginx is running
sudo systemctl status nginx

# Verify site content
curl localhost
# or
ls -la /var/www/html

# Check ownership
stat /var/www/html
```

## Configuration

### Terraform Variables (`terraform/terraform.tfvars`)

```hcl
aws_region             = "eu-west-2"        # AWS region
environment            = "mini-finance"     # Environment name (used for tagging)
vpc_cidr               = "10.0.0.0/16"      # VPC CIDR block
public_subnet_cidr     = "10.0.1.0/24"      # Public subnet CIDR
private_subnet_cidr    = "10.0.2.0/24"      # Private subnet CIDR
instance_type          = "t3.micro"         # EC2 instance type
ssh_public_key_path    = "~/.ssh/id_rsa.pub" # SSH public key location
```

### Ansible Configuration (`ansible/ansible.cfg`)

```ini
[defaults]
inventory = ./inventory.ini              # Inventory file location
roles_path = ./roles                     # Roles directory
host_key_checking = False                # Skip host key verification
gathering = smart                        # Smart fact gathering
fact_caching = jsonfile                  # Cache facts for performance
fact_caching_timeout = 86400             # Cache timeout (24 hours)
```

## Resource Naming Convention

All AWS resources follow the naming convention: `mini-finance-<resource-type>`

| Resource | Name |
|----------|------|
| VPC | `mini-finance-vpc` |
| Internet Gateway | `mini-finance-igw` |
| Public Subnet | `mini-finance-public-subnet` |
| Private Subnet | `mini-finance-private-subnet` |
| NAT Gateway | `mini-finance-nat-gw` |
| NAT Gateway EIP | `mini-finance-nat-eip` |
| Public Route Table | `mini-finance-public-rt` |
| Private Route Table | `mini-finance-private-rt` |
| Security Group | `mini-finance-ec2-sg` |
| EC2 Instance | `mini-finance-instance` |

## Cleanup & Destruction

### Destroy Ansible Deployments

Ansible deployments are idempotent but can be manually cleaned:

```bash
# Remove the application from the instance
ansible web -i inventory.ini -m file -a "path=/var/www/html state=absent"

# Uninstall Nginx
ansible web -i inventory.ini -m apt -a "name=nginx state=absent purge=yes"
```

### Destroy Terraform Infrastructure

```bash
cd terraform

# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm by typing 'yes'
```

## Troubleshooting

### Terraform Issues

**EC2 instance creation fails**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM permissions
# Check region availability
terraform plan -out=tfplan
```

**VPC/Subnet creation issues**
```bash
# Verify CIDR blocks don't conflict
# Ensure region supports required availability zones
terraform validate
```

### Ansible Issues

**SSH Connection Refused**
```bash
# Verify EC2 instance is running
aws ec2 describe-instances --region eu-west-2

# Check security group allows SSH
aws ec2 describe-security-groups --group-names mini-finance-ec2-sg

# Test SSH manually
ssh -i ~/.ssh/id_rsa -vv ubuntu@<public_ip>
```

**Nginx fails to start**
```bash
# Check Nginx syntax on the instance
ansible web -i inventory.ini -m shell -a "sudo nginx -t"

# View Nginx error log
ansible web -i inventory.ini -m shell -a "sudo tail -20 /var/log/nginx/error.log"
```

**Deployment verification fails**
```bash
# Check if files exist in /var/www/html
ansible web -i inventory.ini -m shell -a "ls -la /var/www/html"

# Check file ownership
ansible web -i inventory.ini -m shell -a "stat /var/www/html"

# Test HTTP connectivity manually
curl -v http://<public_ip>
```

**Git clone fails**
```bash
# Verify git is installed
ansible web -i inventory.ini -m shell -a "git --version"

# Test network connectivity
ansible web -i inventory.ini -m shell -a "curl -I https://github.com"
```

## Best Practices Implemented

### Terraform
- ✓ Modular architecture (networking, security, ec2 modules)
- ✓ Separation of concerns
- ✓ Reusable configurations
- ✓ Variable defaults for common settings
- ✓ Resource tagging for tracking and cost allocation
- ✓ Explicit provider configuration
- ✓ Outputs for integration with other tools

### Ansible
- ✓ Idempotent tasks (safe to run multiple times)
- ✓ Role-based organization
- ✓ Handlers for graceful service reloads
- ✓ Tags for selective execution
- ✓ Fact caching for performance
- ✓ Appropriate privilege escalation (`become: yes`)
- ✓ Assertions for verification
- ✓ Comprehensive documentation

### Infrastructure as Code
- ✓ Version control friendly
- ✓ Reproducible deployments
- ✓ Automated verification
- ✓ Infrastructure and configuration in code
- ✓ Easy scaling and modification

## Security Considerations

- **Network Isolation**: Private subnet for future components
- **SSH Security**: Public key authentication only, no passwords
- **Security Groups**: Minimal required permissions
- **IAM**: Separate AWS credentials recommended for production
- **Secrets Management**: SSH keys stored locally, never in code
- **Service Hardening**: Nginx runs as non-root user (www-data)

## Performance Optimization

- **Terraform**: State caching for faster runs
- **Ansible**: Fact caching enabled (24-hour TTL)
- **EC2**: t3.micro instance type is cost-optimized
- **AWS**: eu-west-2 region selected for latency optimization

## Additional Resources

### Documentation
- [terraform/README.md](terraform/README.md) - Comprehensive Terraform module documentation
- [ansible/README.md](ansible/README.md) - Detailed Ansible playbook and role documentation
- [ansible/QUICKSTART.md](ansible/QUICKSTART.md) - Quick 5-step deployment guide
- [PROJECT_AUDIT.md](PROJECT_AUDIT.md) - Comprehensive project audit report
- [FIXES_APPLIED.md](FIXES_APPLIED.md) - Detailed fix descriptions with validation

### Example Configuration Files
- [terraform/terraform.tfvars.example](terraform/terraform.tfvars.example) - Example Terraform variables
- [ansible/inventory.ini.example](ansible/inventory.ini.example) - Example Ansible inventory

### External References
- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS Configuration Management](https://aws.amazon.com/devops/what-is-devops/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [HashiCorp Security Best Practices](https://www.hashicorp.com/resources/security-best-practices)

## Support

### Getting Help

If you encounter issues or have questions:

1. **Review Documentation**
   - [terraform/README.md](terraform/README.md) - Terraform-specific help
   - [ansible/README.md](ansible/README.md) - Ansible-specific help
   - [ansible/QUICKSTART.md](ansible/QUICKSTART.md) - Quick deployment reference

2. **Check Troubleshooting**
   - See [Troubleshooting](#troubleshooting) section for common issues
   - Check [PROJECT_AUDIT.md](PROJECT_AUDIT.md) for identified issues and fixes
   - Review [FIXES_APPLIED.md](FIXES_APPLIED.md) for detailed fix descriptions

3. **Verify Security Requirements**
   - Read [Security & Warnings](#-security--warnings) section carefully
   - Ensure you understand production implications before modifying

### Using This Project

- **Learning**: Excellent resource for learning Terraform + Ansible integration
- **Demos/PoCs**: Use as a base for proof-of-concept deployments
- **Templates**: Adapt code and structure for your own projects
- **Community**: Licensed under MIT-0, freely usable and modifiable

### GitHub Usage

This project is version-controlled with Git. To clone and use:

```bash
# Clone the repository
git clone https://github.com/your-username/mini-finance-demo.git
cd mini-finance-demo

# Create your own branch for modifications
git checkout -b my-deployment

# Make changes, commit, and push
git add .
git commit -m "Configure for my AWS account"
git push origin my-deployment
```

For reporting issues or suggesting improvements, ensure you:
1. Review security warnings first
2. Don't commit sensitive files (terraform.tfstate, SSH keys, credentials)
3. Use .gitignore (already configured)
4. Create descriptive issues with error messages and configuration details

### Contribution Guidelines

While this is primarily an educational project, contributions are welcome:

1. **Bug Reports**: Include error messages, Terraform version, Ansible version
2. **Improvements**: Security enhancements, clearer documentation, additional roles
3. **Features**: New Terraform modules, additional Ansible roles, enhanced verification
4. **Documentation**: Fixes, clarifications, examples

Please follow these practices:
- Don't commit sensitive files or credentials
- Test changes locally before submitting
- Ensure idempotency (all tasks safe to run multiple times)
- Update documentation alongside code changes

## License

This project follows the SPDX License Identifier: MIT-0
