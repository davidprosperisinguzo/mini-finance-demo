#!/bin/bash
set -e

# Update system packages
apt-get update

# Upgrade packages with timeout and error handling
if ! timeout 300 apt-get upgrade -y 2>/dev/null; then
  echo "Warning: apt-get upgrade failed or timed out, continuing anyway" >> /var/log/user-data.log
fi

# Ensure .ssh directory exists
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# Check if SSH public key was provided via template
if [ -n "${ssh_public_key}" ]; then
  # Add provided SSH public key to authorized_keys
  cat >> /home/ubuntu/.ssh/authorized_keys <<EOF
${ssh_public_key}
EOF
else
  # Generate ED25519 SSH keypair on the instance
  ssh-keygen -t ed25519 -f /home/ubuntu/.ssh/id_ed25519 -N "" -C "mini-finance@$(hostname)"
  
  # Add the generated public key to authorized_keys (for local usage)
  cat /home/ubuntu/.ssh/id_ed25519.pub >> /home/ubuntu/.ssh/authorized_keys
fi

# Set proper permissions
chmod 600 /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/id_ed25519 2>/dev/null || true
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# Disable password authentication for enhanced security
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart ssh

# Log completion
echo "SSH configuration completed at $(date)" >> /var/log/user-data.log
echo "Generated SSH key available at /home/ubuntu/.ssh/id_ed25519" >> /var/log/user-data.log
