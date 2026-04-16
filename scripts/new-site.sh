#!/bin/bash
# Interactive setup for a new Ghost site
# Run: bash scripts/new-site.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

echo ""
echo "ghost-selfhost — New Site Setup"
echo "==================================="
echo ""

# Collect inputs
read -p "Site slug (lowercase, no spaces, e.g. myblog): " CLIENT_NAME
read -p "Domain (e.g. blog.yourdomain.com): " DOMAIN
read -p "VPS IP address: " VPS_IP
read -p "Your email (for SSL cert notifications): " ADMIN_EMAIL
read -p "Ghost port (default 2368, increment for multiple sites): " GHOST_PORT
GHOST_PORT=${GHOST_PORT:-2368}
read -p "Timezone (default America/New_York): " TIMEZONE
TIMEZONE=${TIMEZONE:-America/New_York}

echo ""
echo "SMTP settings:"
read -p "  SMTP host (e.g. email-smtp.us-east-1.amazonaws.com): " SMTP_HOST
read -p "  SMTP port (default 587): " SMTP_PORT
SMTP_PORT=${SMTP_PORT:-587}
read -p "  SMTP username: " SMTP_USER
read -s -p "  SMTP password: " SMTP_PASSWORD
echo ""
read -p "  Mail from address (e.g. noreply@yourdomain.com): " MAIL_FROM

echo ""
echo "Database passwords (will be encrypted):"
read -s -p "  MySQL root password: " MYSQL_ROOT
echo ""
read -s -p "  MySQL user password: " MYSQL_PASS
echo ""

# Validate slug
if [[ ! "$CLIENT_NAME" =~ ^[a-z0-9_-]+$ ]]; then
  echo "ERROR: client_name must be lowercase letters, numbers, hyphens or underscores only."
  exit 1
fi

# Check for existing vars file
VARS_FILE="vars/${CLIENT_NAME}.yml"
if [ -f "$VARS_FILE" ]; then
  echo "ERROR: vars/${CLIENT_NAME}.yml already exists. Choose a different slug or edit that file directly."
  exit 1
fi

# Create vars file
cat > "$VARS_FILE" << EOF
# vars/${CLIENT_NAME}.yml
# Generated: $(date)
# Encrypted with ansible-vault

client_name: ${CLIENT_NAME}
domain: ${DOMAIN}
ghost_port: ${GHOST_PORT}
timezone: ${TIMEZONE}
admin_email: ${ADMIN_EMAIL}
mail_from: ${MAIL_FROM}

smtp_host: ${SMTP_HOST}
smtp_port: ${SMTP_PORT}
smtp_user: ${SMTP_USER}
smtp_password: ${SMTP_PASSWORD}

mysql_root_password: ${MYSQL_ROOT}
mysql_password: ${MYSQL_PASS}
EOF

# Append to inventory
cat >> inventory.yml << EOF

    ${CLIENT_NAME}:
      ansible_host: ${VPS_IP}
      ansible_user: root
      ansible_ssh_private_key_file: ~/.ssh/id_ed25519
      client_name: ${CLIENT_NAME}
EOF

echo ""
echo "Created vars/${CLIENT_NAME}.yml"
echo "Updated inventory.yml"
echo ""
echo "Encrypting vars file..."
ansible-vault encrypt "$VARS_FILE"

echo ""
echo "Done. Before deploying:"
echo ""
echo "  Make sure an A record for ${DOMAIN} points to ${VPS_IP}"
echo "  Verify with: dig ${DOMAIN} +short"
echo ""
echo "To deploy:"
echo ""
echo "  ansible-playbook deploy.yml -i inventory.yml \\"
echo "    --extra-vars \"client_name=${CLIENT_NAME}\" \\"
echo "    --ask-vault-pass"
echo ""
