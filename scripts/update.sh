#!/bin/bash
# Manually update Ghost on a deployed site
# Usage: bash scripts/update.sh SITE_NAME
#
# Note: Watchtower auto-updates every Monday at 4am.
# Use this script to update immediately on demand.

set -e

SITE_NAME="${1:-}"

if [ -z "$SITE_NAME" ]; then
  echo "Usage: bash scripts/update.sh SITE_NAME"
  echo ""
  echo "Available sites in inventory.yml:"
  grep "client_name:" inventory.yml | awk '{print "  " $2}'
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

echo "Updating Ghost for: $SITE_NAME"
echo ""

ansible-playbook update.yml -i inventory.yml \
  --extra-vars "client_name=$SITE_NAME" \
  --ask-vault-pass
