# Ansible Multi-Playbook: Install → Deploy → Verify

This Ansible configuration provisions and deploys the Mini Finance application to an EC2 instance using a multi-play approach with three distinct roles.

## Playbook Structure

```
ansible/
├── inventory.ini                 # Inventory with web hosts
├── site.yml                      # Main playbook with 3 plays
├── ansible.cfg                   # Ansible configuration
└── roles/
    ├── nginx/                    # Role: Install and configure Nginx
    │   ├── tasks/main.yml
    │   ├── handlers/main.yml
    │   └── ...
    ├── deployment/               # Role: Clone and deploy Mini Finance
    │   ├── tasks/main.yml
    │   └── ...
    └── verification/             # Role: Verify deployment
        ├── tasks/main.yml
        └── ...
```

## Prerequisites

1. **SSH Access**: Configure SSH key before running playbooks
2. **Python 3**: Required on target machines
3. **Ansible**: Version 2.9 or higher

## Configuration

### Update inventory.ini

Replace the placeholder `<public_ip>` with the actual EC2 instance public IP from your Terraform deployment:

```bash
# Get the public IP from Terraform
cd ../terraform
public_ip=$(terraform output -raw instance_public_ip)

# Update the inventory
cd ../ansible
sed -i "s/<public_ip>/$public_ip/" inventory.ini
```

### Verify ansible.cfg

The `ansible.cfg` file is configured with:
- Inventory path pointing to `inventory.ini`
- Host key checking disabled (safe for ephemeral infrastructure)
- Roles path pointing to `./roles`
- Fact caching enabled for performance
- Privilege escalation configured for `become: yes` tasks

## Playbook Plays

### Play 1: Install and Configure Nginx
**Target**: `web` group  
**Privilege**: Root (become: yes)

Tasks:
1. Update apt package cache
2. Install Nginx and Git
3. Start and enable Nginx service
4. Configure Nginx to serve the Single Page Application
5. Enable the default site with symbolic link

**Handlers**:
- `reload nginx`: Gracefully reloads Nginx on configuration changes

### Play 2: Clone and Deploy Mini Finance Site
**Target**: `web` group  
**Privilege**: Root (become: yes)

Tasks:
1. Clone the Mini Finance repository from GitHub
2. Ensure `/var/www/html` directory exists with proper permissions
3. Synchronize cloned content to web root using rsync
4. Set ownership to `www-data:www-data` (Nginx user)
5. Flush handlers to trigger Nginx reload if content changed

**Key Features**:
- Uses `git` module with `force: yes` for idempotency
- Uses `synchronize` module for efficient file transfer
- Automatic Nginx reload when deployment changes occur

### Play 3: Verify Deployment
**Target**: `localhost`  
**Privilege**: Regular user (no privilege escalation)

Tasks:
1. Wait for Nginx to be ready with retries (5 attempts, 5-second intervals)
2. Send HTTP GET request to the deployed site
3. Assert HTTP response status is 200
4. Display verification results including URL and Content-Type

**Key Features**:
- Retries with backoff for reliability
- Status assertion with clear failure messages
- Detailed output logging for troubleshooting

## Running the Playbook

### 1. Update Inventory with Public IP

```bash
# Option A: Manual update
vim inventory.ini
# Replace <public_ip> with the actual EC2 public IP
# Replace <admin_user> with environment variable or keep 'ubuntu'

# Option B: Automated update
sed -i 's/<public_ip>/YOUR_ACTUAL_IP/' inventory.ini
```

### 2. Verify SSH Connectivity

```bash
# Test SSH access to the web host
ansible web -i inventory.ini -m ping
```

### 3. Run the Complete Playbook

```bash
# Run all plays
ansible-playbook site.yml

# Or run with verbose output
ansible-playbook site.yml -v

# Or run with extra verbosity
ansible-playbook site.yml -vv
```

### 4. Run Specific Tags

```bash
# Run only Nginx installation and configuration
ansible-playbook site.yml --tags nginx

# Run only deployment
ansible-playbook site.yml --tags deployment

# Run only verification
ansible-playbook site.yml --tags verification

# Skip verification (useful for quicker deployments)
ansible-playbook site.yml --skip-tags verification
```

### 5. Run Specific Play

```bash
# Run only the Nginx play
ansible-playbook site.yml --start-at-task "Play 1 - Install and Configure Nginx"

# Run from Play 2 onwards
ansible-playbook site.yml --start-at-task "Play 2 - Clone and Deploy Mini Finance Site"
```

## Inventory Variables

The `inventory.ini` file includes:

```ini
[web]
<public_ip>

[web:vars]
ansible_user=ubuntu                           # SSH user
ansible_ssh_private_key_file=~/.ssh/id_rsa   # SSH key path
ansible_python_interpreter=/usr/bin/python3  # Python interpreter
```

### Variable Descriptions

- `ansible_user`: SSH user name (ubuntu for Amazon Linux/Ubuntu images)
- `ansible_ssh_private_key_file`: Path to private SSH key
- `ansible_python_interpreter`: Path to Python 3 on target system

## Nginx Configuration

The Nginx configuration deployed serves a Single Page Application:

```nginx
server {
  listen 80;
  server_name _;
  root /var/www/html;
  index index.html;
  
  location / {
    try_files $uri /index.html;
  }
  
  error_page 404 /index.html;
}
```

This configuration:
- Listens on port 80
- Serves files from `/var/www/html`
- Redirects all requests to `index.html` (SPA routing)
- Handles 404 errors by serving `index.html` (SPA fallback)

## Git Repository

**Repository**: https://github.com/pravinmishraaws/mini-finance-project  
**Clone Destination**: `/tmp/mini_finance`  
**Web Root**: `/var/www/html`

Content is synced from the cloned repository to the web root with ownership set to `www-data:www-data`.

## Best Practices Implemented

1. **Idempotency**: All tasks are idempotent and safe to run multiple times
2. **Error Handling**: Assertions and retries ensure reliability
3. **Privilege Escalation**: Uses `become: yes` appropriately with `sudo` method
4. **Handlers**: Nginx reload triggered only when configuration changes
5. **Tags**: Tasks tagged for selective execution
6. **Fact Caching**: Improves performance on repeated runs
7. **Host Key Checking**: Disabled for compatibility with ephemeral infrastructure
8. **Logging**: Detailed debug output available with `-v` flags

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connectivity
ssh -i ~/.ssh/id_rsa ubuntu@<public_ip>

# Test with Ansible
ansible web -i inventory.ini -m ping -vv
```

### Nginx Not Starting

```bash
# Check Nginx status on the host
ansible web -i inventory.ini -m systemd -a "name=nginx state=started"

# View Nginx logs
ansible web -i inventory.ini -m shell -a "sudo tail -20 /var/log/nginx/error.log"
```

### Deployment Verification Fails

```bash
# Manually check the URL
ansible web -i inventory.ini -m uri -a "url=http://{{ inventory_hostname }}"

# Check if files are in web root
ansible web -i inventory.ini -m shell -a "ls -la /var/www/html"

# Check file ownership
ansible web -i inventory.ini -m shell -a "stat /var/www/html"
```

### Repository Clone Fails

```bash
# Check git installation
ansible web -i inventory.ini -m shell -a "git --version"

# Test git repository access
ansible web -i inventory.ini -m shell -a "git clone https://github.com/pravinmishraaws/mini-finance-project /tmp/test"
```

## Integration with Terraform

To automate the complete process with Terraform-provisioned infrastructure:

```bash
# From terraform directory
cd ../terraform

# Get the public IP and update inventory
public_ip=$(terraform output -raw instance_public_ip)
sed -i "s/<public_ip>/$public_ip/" ../ansible/inventory.ini

# Run Ansible playbook
cd ../ansible
ansible-playbook site.yml
```

## Security Considerations

- SSH key-based authentication (no password authentication)
- Nginx runs as `www-data` user (least privilege)
- Security group limits access to ports 22 and 80
- All tasks executed with necessary privilege escalation
- No sensitive data hardcoded in playbooks

## Performance Optimization

- Fact caching enabled (`jsonfile` backend) to reduce gather_facts overhead
- Smart gathering for efficient fact collection
- YAML callback plugin for readable output
- Tasks use appropriate modules (git, synchronize) for optimal performance

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Git Module Documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/git_module.html)
