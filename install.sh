#!/bin/bash
# ghost-selfhost bootstrap
# One-line install:
# bash <(curl -fsSL https://raw.githubusercontent.com/zwatchmaker/ghost-selfhost/main/install.sh)

set -e

REPO="https://github.com/zwatchmaker/ghost-selfhost"
INSTALL_DIR="$HOME/ghost-selfhost"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         ghost-selfhost             ║"
echo "║   Self-hosted Ghost via Ansible      ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Check and install dependencies
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    echo "  Installing $1..."
    if command -v brew &>/dev/null; then
      brew install "$1" -q
    elif command -v apt &>/dev/null; then
      sudo apt install "$1" -y -q
    else
      echo "ERROR: Please install $1 manually then re-run."
      exit 1
    fi
  else
    echo "  ✓ $1"
  fi
}

echo "Checking dependencies..."
check_dep ansible
check_dep git

# Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "Updating existing install..."
  git -C "$INSTALL_DIR" pull --quiet
else
  echo "Downloading ghost-selfhost..."
  git clone "$REPO" "$INSTALL_DIR" --quiet
fi

cd "$INSTALL_DIR"

echo ""
echo "Done. Next steps:"
echo ""
echo "  1. Spin up a Hetzner VPS (Ubuntu 24.04)"
echo "  2. Add your VPS IP to inventory.yml"
echo "  3. Copy and fill in your vars file:"
echo "     cp vars/example.yml vars/mysite.yml"
echo "     nano vars/mysite.yml"
echo "  4. Encrypt your secrets:"
echo "     ansible-vault encrypt vars/mysite.yml"
echo "  5. Deploy:"
echo "     ansible-playbook deploy.yml -i inventory.yml \\"
echo "       --extra-vars \"client_name=mysite\" \\"
echo "       --ask-vault-pass"
echo ""
echo "Or use the interactive setup:"
echo "  bash scripts/new-site.sh"
echo ""
echo "Full docs: $INSTALL_DIR/README.md"
echo ""
