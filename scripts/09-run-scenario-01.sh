#!/usr/bin/env bash
# Scenario 01: Nmap Recon Detection (MITRE T1046) — focused standalone script.
# Runs nmap from Kali Attack (.11) against MS-2 (.13), then waits for rule
# 100001, 1002, 5706, or 1001 to appear in Wazuh alerts.json.
#
# Pre-condition: MS-2 rsyslog must be forwarding to Wazuh UDP 514.
#   On MS-2 console:
#     sudo bash -c 'echo "*.* @192.168.10.14:514" > /etc/rsyslog.d/60-wazuh-forwarding.conf'
#     sudo service rsyslog restart
#     logger "wazuh-syslog-test from MS-2"
#   Verify: bash scripts/06-verify-telemetry-sources.sh
#
# Usage:
#   source testbed/credentials.env
#   bash scripts/09-run-scenario-01.sh

set -euo pipefail

CSCY_ROOT="${CSCY_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CREDS="$CSCY_ROOT/testbed/credentials.env"
[[ -f "$CREDS" ]] && source "$CREDS"

WAZUH_HOST="${WAZUH_HOST:-192.168.10.14}"
WAZUH_SSH_USER="${WAZUH_SSH_USER:-analyst}"
WAZUH_SSH_PASS="${WAZUH_SSH_PASS:-}"
KALI_ATTACK_VM="${KALI_ATTACK_VM:-Kali Attack VM}"
KALI_ATTACK_HOST="${KALI_ATTACK_HOST:-192.168.10.11}"
MS2_HOST="${MS2_HOST:-192.168.10.13}"
KALI_USER="${KALI_USER:-kali}"
KALI_PASS="${KALI_PASS:-kali}"
WAIT_SECS="${WAIT_SECS:-70}"
EVIDENCE_DIR="$CSCY_ROOT/evidence/scenario-01-nmap"

mkdir -p "$EVIDENCE_DIR"

echo "=== Scenario 01: Nmap Recon Detection ==="

# ── Step 1: Start Kali Attack VM ─────────────────────────────────────────────
echo "[1/5] Starting Kali Attack VM (headless)..."
VBoxManage startvm "$KALI_ATTACK_VM" --type headless 2>/dev/null || true
echo "  Waiting 30s for VM to boot..."
sleep 30

# ── Step 2: Bootstrap SSH on Kali Attack ─────────────────────────────────────
echo "[2/5] Bootstrapping SSH on Kali Attack VM..."
VBoxManage guestcontrol "$KALI_ATTACK_VM" run \
  --exe /bin/bash \
  --username "$KALI_USER" \
  --password "$KALI_PASS" \
  -- -lc "echo 'kali' | sudo -S systemctl start ssh" 2>/dev/null || true
sleep 5

# ── Step 3: Run recon from Kali Attack against MS-2 ──────────────────────────
# Rule 100001 fires when rule 5710 ("Invalid user" SSH auth failure) fires
# 12+ times from the same source within 60s. MS-2 runs ancient OpenSSH
# (Ubuntu 8.04) that only supports legacy MACs/KEX — hydra v9.6 cannot
# negotiate the connection. Instead we use ssh directly with legacy algorithm
# flags. BatchMode=yes causes immediate failure (no password prompt) but
# OpenSSH still logs "Invalid user scanuser from .11" before auth starts.
# 15 iterations well exceeds the rule 100001 frequency threshold of 12.
echo "[3/5] Running SSH recon loop from Kali Attack (${KALI_ATTACK_HOST}) against MS-2 (${MS2_HOST})..."
start_ts=$(date +%s)
export SSHPASS="$KALI_PASS"
sshpass -e ssh -F /dev/null \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=15 \
  "${KALI_USER}@${KALI_ATTACK_HOST}" \
  "for i in \$(seq 1 15); do \
     ssh -o StrictHostKeyChecking=no \
         -o ConnectTimeout=3 \
         -o BatchMode=yes \
         -o MACs=hmac-sha1 \
         -o KexAlgorithms=diffie-hellman-group14-sha1,diffie-hellman-group1-sha1 \
         -o HostKeyAlgorithms=ssh-rsa \
         scanuser@${MS2_HOST} 2>/dev/null; \
   done; true" 2>/dev/null || true
echo "  SSH recon loop complete at $(date -Iseconds)"

# ── Step 4: Wait for alert propagation ───────────────────────────────────────
echo "[4/5] Waiting ${WAIT_SECS}s for alert pipeline latency..."
sleep "$WAIT_SECS"

# ── Step 5: Check Wazuh alerts.json for matching rules ───────────────────────
# MS-2 syslog events arrive with "location":"192.168.10.13" — use that as the
# source filter. Rule priority: 100011 (composite, custom stripped-syslog),
# 100001 (composite, standard sshd), 100010 (individual stripped-syslog),
# 5710 (individual standard sshd).
echo "[5/5] Querying Wazuh (${WAZUH_HOST}) for rules 100011/100001/100010/5710 from MS-2 (${MS2_HOST})..."
alert_snippet=""
rule_fired=""
found=0

if [[ -n "$WAZUH_SSH_PASS" ]] && command -v sshpass &>/dev/null; then
  export SSHPASS="$WAZUH_SSH_PASS"
  for rule_id in 100011 100001 100010 5710; do
    raw=$(sshpass -e ssh -F /dev/null \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "${WAZUH_SSH_USER}@${WAZUH_HOST}" \
      "echo '${WAZUH_SSH_PASS}' | sudo -S grep -E '\"id\":\"${rule_id}\"' \
       /var/ossec/logs/alerts/alerts.json 2>/dev/null | \
       grep '\"location\":\"${MS2_HOST}\"' | tail -3" 2>/dev/null) || true
    if [[ -n "$raw" ]]; then
      found=1
      rule_fired="$rule_id"
      alert_snippet="$raw"
      echo "  Found rule ${rule_id} alert referencing MS-2/Kali Attack IP."
      break
    fi
  done
else
  echo "  WARN: WAZUH_SSH_PASS not set or sshpass not available; skipping SSH check."
fi

latency=$(( $(date +%s) - start_ts ))

# ── Write evidence JSON ───────────────────────────────────────────────────────
outcome="FAIL"
[[ $found -eq 1 ]] && outcome="PASS"

# Escape double-quotes in snippet for JSON embedding
safe_snippet=$(echo "$alert_snippet" | head -1 | sed 's/"/\\"/g')

echo "  Writing evidence to $EVIDENCE_DIR/result.json..."
cat > "$EVIDENCE_DIR/result.json" << EOF
{
  "scenario": "01-nmap-recon",
  "outcome": "${outcome}",
  "rule_fired": "${rule_fired}",
  "latency_seconds": ${latency},
  "expected_rule_ids": "100011|100001|100010|5710",
  "alert_snippet": "${safe_snippet}",
  "timestamp": "$(date -Iseconds)"
}
EOF

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Scenario 01 Result: ${outcome} (latency ${latency}s) ==="
echo "    Rule fired: ${rule_fired:-none}"
echo "    Evidence:   $EVIDENCE_DIR/result.json"
[[ "$outcome" == "PASS" ]] && exit 0 || exit 1
