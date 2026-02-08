#!/usr/bin/env bash
# Verify (and if needed, configure) the Wazuh manager syslog listener on port 514/udp.
# Idempotent: exits 0 if already configured, or after successfully adding the block.
#
# Requires: host can reach Wazuh VM (192.168.10.14), sshpass installed.

set -euo pipefail

CSCY_ROOT="${CSCY_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
WAZUH_HOST="${WAZUH_HOST:-192.168.10.14}"
WAZUH_SSH_USER="${WAZUH_SSH_USER:-analyst}"
CREDS="$CSCY_ROOT/testbed/credentials.env"

if [[ ! -f "$CREDS" ]]; then
  echo "Credentials file not found: $CREDS" >&2
  exit 1
fi

# shellcheck source=testbed/credentials.env
source "$CREDS"

if [[ -z "${WAZUH_SSH_PASS:-}" ]]; then
  echo "WAZUH_SSH_PASS not set in $CREDS" >&2
  exit 1
fi

if ! command -v sshpass &>/dev/null; then
  echo "sshpass not installed. Run: sudo apt-get install -y sshpass" >&2
  exit 1
fi

export SSHPASS="$WAZUH_SSH_PASS"
SSH="sshpass -e ssh -F /dev/null -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 $WAZUH_SSH_USER@$WAZUH_HOST"

echo "=== Checking Wazuh syslog listener at $WAZUH_HOST ==="

if $SSH "echo '$WAZUH_SSH_PASS' | sudo -S grep -q '<connection>syslog</connection>' /var/ossec/etc/ossec.conf 2>/dev/null"; then
  echo "PASS: syslog remote block already present in ossec.conf"
  exit 0
fi

echo "Syslog remote block not found — injecting via Python and restarting wazuh-manager..."

# Write the Python patcher to a temp file on the remote host, then execute it with sudo.
$SSH 'cat > /tmp/patch_ossec.py' << 'PYEOF'
import pathlib
cfg = pathlib.Path("/var/ossec/etc/ossec.conf")
content = cfg.read_text()
block = "\n  <remote>\n    <connection>syslog</connection>\n    <port>514</port>\n    <protocol>udp</protocol>\n    <allowed-ips>192.168.10.0/24</allowed-ips>\n  </remote>\n"
if "<connection>syslog</connection>" not in content:
    pos = content.rfind("</ossec_config>")
    if pos == -1:
        raise SystemExit("ERROR: </ossec_config> not found in ossec.conf")
    content = content[:pos] + block + "</ossec_config>" + content[pos + len("</ossec_config>"):]
    cfg.write_text(content)
    print("Added syslog remote block.")
else:
    print("Syslog remote block already present.")
PYEOF

$SSH "echo '$WAZUH_SSH_PASS' | sudo -S python3 /tmp/patch_ossec.py && \
      echo '$WAZUH_SSH_PASS' | sudo -S systemctl restart wazuh-manager && \
      echo '$WAZUH_SSH_PASS' | sudo -S systemctl is-active wazuh-manager && \
      rm -f /tmp/patch_ossec.py"

echo "=== Confirming syslog block is present after restart ==="
if $SSH "echo '$WAZUH_SSH_PASS' | sudo -S grep -q '<connection>syslog</connection>' /var/ossec/etc/ossec.conf 2>/dev/null"; then
  echo "PASS: syslog listener configured and wazuh-manager is active"
  exit 0
else
  echo "FAIL: syslog block still not found in ossec.conf after patching" >&2
  exit 1
fi
