#!/usr/bin/env bash
# Scenario 04: Privilege Escalation (MITRE T1548) — focused standalone script.
# Runs sudo commands on Kali Defense (.12) directly via SSH from the host, then
# waits for rule 5402/5401/5403 (sudo) to appear in Wazuh alerts.json.
#
# Pre-condition: Kali Defense wazuh-agent must be active (ID: 001).
#   Verify: bash scripts/06-verify-telemetry-sources.sh
#
# Usage:
#   source testbed/credentials.env
#   bash scripts/11-run-scenario-04.sh

set -euo pipefail

CSCY_ROOT="${CSCY_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CREDS="$CSCY_ROOT/testbed/credentials.env"
[[ -f "$CREDS" ]] && source "$CREDS"

WAZUH_HOST="${WAZUH_HOST:-192.168.10.14}"
WAZUH_SSH_USER="${WAZUH_SSH_USER:-analyst}"
WAZUH_SSH_PASS="${WAZUH_SSH_PASS:-}"
KALI_DEFENSE_VM="${KALI_DEFENSE_VM:-Kali Defense VM}"
KALI_DEFENSE_HOST="${KALI_DEFENSE_HOST:-192.168.10.12}"
KALI_USER="${KALI_USER:-kali}"
KALI_PASS="${KALI_PASS:-kali}"
WAIT_SECS="${WAIT_SECS:-70}"
EVIDENCE_DIR="$CSCY_ROOT/evidence/scenario-04-priv-esc"

mkdir -p "$EVIDENCE_DIR"

echo "=== Scenario 04: Privilege Escalation Detection ==="

# ── Step 0: Verify Kali Defense VM is running ────────────────────────────────
echo "[0/5] Checking Kali Defense VM is running..."
if ! VBoxManage list runningvms | grep -q 'Kali Defense'; then
  echo "ERROR: Kali Defense VM is not running. Start it first." >&2
  exit 1
fi
echo "  Kali Defense VM is running."

# ── Step 1: Bootstrap SSH on Kali Defense ────────────────────────────────────
echo "[1/5] Bootstrapping SSH on Kali Defense VM..."
VBoxManage guestcontrol "$KALI_DEFENSE_VM" run \
  --exe /bin/bash \
  --username "$KALI_USER" \
  --password "$KALI_PASS" \
  -- -lc "echo 'kali' | sudo -S systemctl start ssh" 2>/dev/null || true
echo "  Waiting 15s for SSH to become available..."
sleep 15

# ── Step 2: Run privilege escalation commands on Kali Defense ────────────────
# sudo events generate auth.log entries that the Wazuh agent (ID: 001) ships
# to the manager. Rule 5402 fires on "Successful sudo to root"; 5401 on
# "Successful sudo command". Commands run directly from host via sshpass.
echo "[2/5] Running privilege escalation commands on Kali Defense (${KALI_DEFENSE_HOST})..."
start_ts=$(date +%s)
export SSHPASS="$KALI_PASS"
sshpass -e ssh -F /dev/null \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=15 \
  "${KALI_USER}@${KALI_DEFENSE_HOST}" \
  "sudo -l; echo kali | sudo -S id; echo kali | sudo -S whoami" \
  2>/dev/null || true
echo "  Privilege escalation commands complete at $(date -Iseconds)"

# ── Step 3: Wait for alert propagation ───────────────────────────────────────
echo "[3/5] Waiting ${WAIT_SECS}s for alert pipeline latency..."
sleep "$WAIT_SECS"

# ── Step 4: Check Wazuh alerts.json for matching rules ───────────────────────
# Sudo events on Kali Defense arrive from agent ID 001, location journald
# (Kali uses systemd journald; no /var/log/auth.log exists on this version).
# Rule priority: 5402 (sudo to root), 5401 (sudo allowed), 5403 (sudo failed),
# then broader auth rules 2501/2502/5301/5303, then custom 100002.
echo "[4/5] Querying Wazuh (${WAZUH_HOST}) for sudo rules from Kali Defense agent (001)..."
alert_snippet=""
rule_fired=""
found=0

if [[ -n "$WAZUH_SSH_PASS" ]] && command -v sshpass &>/dev/null; then
  export SSHPASS="$WAZUH_SSH_PASS"
  for rule_id in 5402 5401 5403 2501 2502 5301 5303 100002; do
    raw=$(sshpass -e ssh -F /dev/null \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "${WAZUH_SSH_USER}@${WAZUH_HOST}" \
      "echo '${WAZUH_SSH_PASS}' | sudo -S grep -E '\"id\":\"${rule_id}\"' \
       /var/ossec/logs/alerts/alerts.json 2>/dev/null | \
       grep '\"agent\":{\"id\":\"001\"' | \
       grep 'journald' | tail -3" 2>/dev/null) || true
    if [[ -n "$raw" ]]; then
      found=1
      rule_fired="$rule_id"
      alert_snippet="$raw"
      echo "  Found rule ${rule_id} alert from Kali Defense agent (001)."
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
  "scenario": "04-priv-escalation",
  "outcome": "${outcome}",
  "rule_fired": "${rule_fired}",
  "latency_seconds": ${latency},
  "expected_rule_ids": "5402|5401|5403|2501|2502|5301|5303|100002",
  "alert_snippet": "${safe_snippet}",
  "timestamp": "$(date -Iseconds)"
}
EOF

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Scenario 04 Result: ${outcome} (latency ${latency}s) ==="
echo "    Rule fired: ${rule_fired:-none}"
echo "    Evidence:   $EVIDENCE_DIR/result.json"
if [[ "$outcome" == "FAIL" ]]; then
  echo ""
  echo "  FAIL diagnostics:"
  echo "    # Check journald on Kali Defense for sudo entries:"
  echo "    export SSHPASS=kali"
  echo "    sshpass -e ssh -F /dev/null kali@192.168.10.12 'journalctl --since \"5 min ago\" | grep -i sudo'"
  echo "    # Check wazuh-agent is active:"
  echo "    sshpass -e ssh -F /dev/null kali@192.168.10.12 'systemctl is-active wazuh-agent'"
fi
[[ "$outcome" == "PASS" ]] && exit 0 || exit 1
