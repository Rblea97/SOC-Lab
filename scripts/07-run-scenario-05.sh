#!/usr/bin/env bash
# Scenario 05: Suspicious File Creation — focused standalone script.
# Creates /tmp/reverse_shell.php on Kali Defense (.12) where the Wazuh agent
# runs syscheck realtime on /tmp, then waits for rule 100003 (or fallback 554)
# to appear in Wazuh alerts.json.
#
# Usage:
#   source testbed/credentials.env
#   bash scripts/07-run-scenario-05.sh

set -euo pipefail

CSCY_ROOT="${CSCY_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CREDS="$CSCY_ROOT/testbed/credentials.env"
[[ -f "$CREDS" ]] && source "$CREDS"

WAZUH_HOST="${WAZUH_HOST:-192.168.10.14}"
WAZUH_SSH_USER="${WAZUH_SSH_USER:-analyst}"
WAZUH_SSH_PASS="${WAZUH_SSH_PASS:-}"
KALI_DEFENSE_VM="${KALI_DEFENSE_VM:-Kali Defense VM}"
KALI_HOST="${KALI_HOST:-192.168.10.12}"
KALI_USER="${KALI_USER:-kali}"
KALI_PASS="${KALI_PASS:-kali}"
WAIT_SECS="${WAIT_SECS:-70}"
EVIDENCE_DIR="$CSCY_ROOT/evidence/scenario-05-suspicious-file"

mkdir -p "$EVIDENCE_DIR"

echo "=== Scenario 05: Suspicious File Creation ==="

# ── Step 1: Bootstrap SSH on Kali Defense ────────────────────────────────────
echo "[1/5] Bootstrapping SSH on Kali Defense VM..."
VBoxManage guestcontrol "$KALI_DEFENSE_VM" run \
  --exe /bin/bash \
  --username "$KALI_USER" \
  --password "$KALI_PASS" \
  -- -lc "echo 'kali' | sudo -S systemctl start ssh" 2>/dev/null || true
sleep 3

# ── Step 2: Create the suspicious file on Kali Defense ───────────────────────
echo "[2/5] Creating /tmp/reverse_shell.php on Kali Defense (${KALI_HOST})..."
start_ts=$(date +%s)
export SSHPASS="$KALI_PASS"
sshpass -e ssh -F /dev/null \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=15 \
  "${KALI_USER}@${KALI_HOST}" \
  'touch /tmp/reverse_shell.php && printf "<?php system(\$_GET[\"cmd\"]); ?>\n" > /tmp/reverse_shell.php'
echo "  File created at $(date -Iseconds)"

# ── Step 3: Wait for syscheck realtime propagation ───────────────────────────
echo "[3/5] Waiting ${WAIT_SECS}s for syscheck realtime event to reach Wazuh..."
sleep "$WAIT_SECS"

# ── Step 4: Check Wazuh alerts.json for rule 100003 or 554 ───────────────────
echo "[4/5] Querying Wazuh (${WAZUH_HOST}) for rule 100003/554..."
alert_snippet=""
found_rule_id=""
found=0

if [[ -n "$WAZUH_SSH_PASS" ]] && command -v sshpass &>/dev/null; then
  export SSHPASS="$WAZUH_SSH_PASS"
  for rule_id in 100003 554; do
    raw=$(sshpass -e ssh -F /dev/null \
      -o StrictHostKeyChecking=no \
      -o ConnectTimeout=15 \
      "${WAZUH_SSH_USER}@${WAZUH_HOST}" \
      "echo '${WAZUH_SSH_PASS}' | sudo -S grep -E '\"id\":\"${rule_id}\"' \
       /var/ossec/logs/alerts/alerts.json 2>/dev/null | tail -3" 2>/dev/null) || true
    if echo "$raw" | grep -q "\"id\":\"${rule_id}\""; then
      found=1
      alert_snippet="$raw"
      found_rule_id="$rule_id"
      echo "  Found rule ${rule_id} alert."
      break
    fi
  done
else
  echo "  WARN: WAZUH_SSH_PASS not set or sshpass not available; skipping SSH check."
fi

latency=$(( $(date +%s) - start_ts ))

# ── Step 5: Write evidence JSON ───────────────────────────────────────────────
outcome="FAIL"
[[ $found -eq 1 ]] && outcome="PASS"

# Escape double-quotes in snippet for JSON embedding
safe_snippet=$(echo "$alert_snippet" | head -1 | sed 's/"/\\"/g')

echo "[5/5] Writing evidence to $EVIDENCE_DIR/result.json..."
cat > "$EVIDENCE_DIR/result.json" << EOF
{
  "scenario": "05-suspicious-file",
  "outcome": "${outcome}",
  "rule_fired": "${found_rule_id:-n/a}",
  "latency_seconds": ${latency},
  "expected_rule_ids": "554|100003",
  "alert_snippet": "${safe_snippet}",
  "timestamp": "$(date -Iseconds)"
}
EOF

# ── Cleanup: remove test file from Kali Defense ──────────────────────────────
echo "[cleanup] Removing /tmp/reverse_shell.php from Kali Defense..."
export SSHPASS="$KALI_PASS"
sshpass -e ssh -F /dev/null \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=15 \
  "${KALI_USER}@${KALI_HOST}" \
  'rm -f /tmp/reverse_shell.php' 2>/dev/null || true

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Scenario 05 Result: ${outcome} (latency ${latency}s) ==="
echo "    Evidence: $EVIDENCE_DIR/result.json"
[[ "$outcome" == "PASS" ]] && exit 0 || exit 1
