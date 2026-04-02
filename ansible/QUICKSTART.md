# Quick Start Guide - Mini Finance Ansible Deployment

Complete end-to-end deployment in 5 steps:

## Step 1: Get the EC2 Public IP from Terraform

```bash
cd terraform
PUBLIC_IP=$(terraform output -raw instance_public_ip)
echo "EC2 Public IP: $PUBLIC_IP"
```

## Step 2: Update the Ansible Inventory

```bash
cd ../ansible

# Replace the placeholder with the actual public IP
sed -i "s/<public_ip>/$PUBLIC_IP/" inventory.ini

# Verify the update
cat inventory.ini
```

## Step 3: Verify SSH Access

```bash
# Test SSH connectivity using Ansible
ansible web -i inventory.ini -m ping

# Expected output:
# <public_ip> | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

## Step 4: Run the Complete Playbook

```bash
# Option A: Simple execution
ansible-playbook site.yml

# Option B: With verbose output for troubleshooting
ansible-playbook site.yml -v

# Option C: Using the deploy script
chmod +x deploy.sh
./deploy.sh
```

## Step 5: Verify the Deployment

```bash
# Check the output for HTTP 200 status on the verification play
# You should see:
# "Deployment verified successfully. Site is accessible with HTTP 200"

# Or manually test the deployed site
curl http://$PUBLIC_IP
```

## What Gets Deployed

### Nginx Configuration
- Listens on port 80
- Serves Single Page App from /var/www/html
- Automatically redirects all routes to index.html (SPA routing)

### Mini Finance Application
- Cloned from: https://github.com/pravinmishraaws/mini-finance-project
- Deployed to: /var/www/html
- Owned by: www-data (Nginx user)

## Common Issues & Solutions

### "SSH connection refused"
```bash
# Ensure EC2 instance is running
# Check security group allows port 22
# Verify inventory.ini has correct IP and credentials
ansible all -i inventory.ini -m ping -vv
```

### "Nginx fails to reload"
```bash
# Check Nginx syntax
ansible web -i inventory.ini -m shell -a "sudo nginx -t"

# Restart nginx manually
ansible web -i inventory.ini -m systemd -a "name=nginx state=restarted"
```

### "Deployment verification fails with HTTP error"
```bash
# Check if files exist in web root
ansible web -i inventory.ini -m shell -a "ls -la /var/www/html"

# Check Nginx logs
ansible web -i inventory.ini -m shell -a "sudo tail -20 /var/log/nginx/error.log"
```

### "Git clone fails"
```bash
# Verify git is installed
ansible web -i inventory.ini -m shell -a "git --version"

# Test direct clone
ansible web -i inventory.ini -m shell -a "git clone https://github.com/pravinmishraaws/mini-finance-project /tmp/test"
```

## Run Specific Components

```bash
# Just install Nginx
ansible-playbook site.yml --tags nginx

# Just deploy the application
ansible-playbook site.yml --tags deployment

# Just verify the deployment
ansible-playbook site.yml --tags verification

# Skip verification (faster)
ansible-playbook site.yml --skip-tags verification
```

## Troubleshooting

### Enable Debug Mode
```bash
# Very verbose output
ansible-playbook site.yml -vvv

# Dry run (show what would be changed)
ansible-playbook site.yml --check
```

### SSH Connection Details
Verify `inventory.ini` has:
```ini
[web]
<actual_public_ip>

[web:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
```

### Idempotent Execution
The playbook is idempotent - safe to run multiple times. Changes only made if needed.

## Access the Deployed Application

Once deployment is complete, access:
```
http://<public_ip>
```

Replace `<public_ip>` with the actual EC2 instance public IP.

## For More Information

See `README.md` for comprehensive documentation.
