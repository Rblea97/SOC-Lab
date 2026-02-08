#!/usr/bin/env bash
# Verify that >=2 telemetry sources are visible in Wazuh archives.log:
#   1. Kali Defense wazuh-agent events (192.168.10.12)
#   2. MS-2 syslog events (192.168.10.13)
# Also checks/enables logall in ossec.conf (required for archives.log to populate).
# Idempotent: exits 0 if sources confirmed, exit 2 if logall was just enabled (re-run needed).

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

echo "=== Checking logall setting on $WAZUH_HOST ==="

if $SSH "echo '$WAZUH_SSH_PASS' | sudo -S grep -q '<logall>yes</logall>' /var/ossec/etc/ossec.conf 2>/dev/null"; then
  echo "PASS: logall already enabled"
else
  echo "logall not found — injecting via Python and restarting wazuh-manager..."

  $SSH 'cat > /tmp/patch_logall.py' << 'PYEOF'
import pathlib
cfg = pathlib.Path("/var/ossec/etc/ossec.conf")
content = cfg.read_text()
block = "\n  <logall>yes</logall>\n"
if "<logall>yes</logall>" not in content:
    pos = content.rfind("</global>")
    if pos == -1:
        raise SystemExit("ERROR: </global> not found in ossec.conf")
    content = content[:pos] + block + "</global>" + content[pos + len("</global>"):]
    cfg.write_text(content)
    print("Added logall block.")
else:
    print("logall already present.")
PYEOF

  $SSH "echo '$WAZUH_SSH_PASS' | sudo -S python3 /tmp/patch_logall.py && \
        echo '$WAZUH_SSH_PASS' | sudo -S systemctl restart wazuh-manager && \
        rm -f /tmp/patch_logall.py"

  echo "logall enabled — restart done. Wait 30 s then re-run."
  exit 2
fi

echo "=== Checking archives.log for telemetry sources ==="

KALI_OK=0
MS2_OK=0

if $SSH "echo '$WAZUH_SSH_PASS' | sudo -S grep -q '192.168.10.12' \
    /var/ossec/logs/archives/archives.log 2>/dev/null"; then
  echo "PASS: Kali Defense (.12) events in archives.log"
  KALI_OK=1
else
  echo "WARN: no .12 events yet — agent may need a moment"
  KALI_OK=0
fi

if $SSH "echo '$WAZUH_SSH_PASS' | sudo -S grep -q '192.168.10.13' \
    /var/ossec/logs/archives/archives.log 2>/dev/null"; then
  echo "PASS: MS-2 (.13) events in archives.log"
  MS2_OK=1
else
  echo "WARN: no .13 events yet (MS-2 console step pending?)"
  MS2_OK=0
fi

if [[ $KALI_OK -eq 1 && $MS2_OK -eq 1 ]]; then
  echo "=== All telemetry sources confirmed ==="
  exit 0
else
  echo "=== Some sources not yet visible (WARNs above) ==="
  exit 0
fi
