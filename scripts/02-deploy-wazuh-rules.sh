#!/usr/bin/env bash
# Copy local_rules.xml to Wazuh VM and restart wazuh-manager.
# Requires: host can reach Wazuh VM (192.168.10.14), SSH as analyst (or WAZUH_SSH_*).
#
# NOTE (production): The sudo commands below use password-based sudo (LAB ONLY).
# In production, configure NOPASSWD sudoers for the analyst user scoped to exactly:
#   /bin/cp /tmp/local_rules.xml /var/ossec/etc/rules/local_rules.xml
#   /bin/cp /tmp/local_decoder.xml /var/ossec/etc/decoders/local_decoder.xml
#   /bin/systemctl restart wazuh-manager

set -euo pipefail

CSCY_ROOT="${CSCY_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
WAZUH_HOST="${WAZUH_HOST:-192.168.10.14}"
WAZUH_SSH_USER="${WAZUH_SSH_USER:-analyst}"
RULES_SRC="$CSCY_ROOT/wazuh-config/local_rules.xml"
RULES_DEST="/var/ossec/etc/rules/local_rules.xml"
DECODER_SRC="$CSCY_ROOT/wazuh-config/local_decoder.xml"
DECODER_DEST="/var/ossec/etc/decoders/local_decoder.xml"

if [[ ! -f "$RULES_SRC" ]]; then
  echo "Rules file not found: $RULES_SRC" >&2
  exit 1
fi

if [[ ! -f "$DECODER_SRC" ]]; then
  echo "Decoder file not found: $DECODER_SRC" >&2
  exit 1
fi

echo "=== Deploying custom rules and decoders to Wazuh at $WAZUH_HOST ==="

if [[ -n "${WAZUH_SSH_PASS:-}" ]]; then
  if ! command -v sshpass &>/dev/null; then
    echo "WAZUH_SSH_PASS set but sshpass not installed. Install sshpass or use SSH keys." >&2
    exit 1
  fi
  export SSHPASS="$WAZUH_SSH_PASS"
  sshpass -e scp -F /dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
    "$RULES_SRC" "$WAZUH_SSH_USER@$WAZUH_HOST:/tmp/local_rules.xml"
  sshpass -e scp -F /dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
    "$DECODER_SRC" "$WAZUH_SSH_USER@$WAZUH_HOST:/tmp/local_decoder.xml"
  sshpass -e ssh -F /dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
    "$WAZUH_SSH_USER@$WAZUH_HOST" \
    "echo \"$WAZUH_SSH_PASS\" | sudo -S cp /tmp/local_rules.xml $RULES_DEST && \
     echo \"$WAZUH_SSH_PASS\" | sudo -S cp /tmp/local_decoder.xml $DECODER_DEST && \
     echo \"$WAZUH_SSH_PASS\" | sudo -S systemctl restart wazuh-manager && echo OK" # LAB ONLY: password-based sudo
else
  scp -F /dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
    "$RULES_SRC" "$WAZUH_SSH_USER@$WAZUH_HOST:/tmp/local_rules.xml"
  scp -F /dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
    "$DECODER_SRC" "$WAZUH_SSH_USER@$WAZUH_HOST:/tmp/local_decoder.xml"
  ssh -F /dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
    "$WAZUH_SSH_USER@$WAZUH_HOST" \
    "sudo cp /tmp/local_rules.xml $RULES_DEST && \
     sudo cp /tmp/local_decoder.xml $DECODER_DEST && \
     sudo systemctl restart wazuh-manager && echo OK"
fi

echo "=== Rules and decoders deployed; wazuh-manager restarted ==="
