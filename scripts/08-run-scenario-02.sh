#!/usr/bin/env bash
# Scenario 02: SSH Brute Force Detection — focused standalone script.
# Launches hydra from Kali Attack (.11) against Kali Defense (.12) SSH,
# then waits for rule 100002, 5763, or 5716 to appear in Wazuh alerts.json.
#
# Usage:
#   source testbed/credentials.env
#   bash scripts/08-run-scenario-02.sh

set -euo pipefail

CSCY_ROOT="${CSCY_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CREDS="$CSCY_ROOT/testbed/credentials.env"
[[ -f "$CREDS" ]] && source "$CREDS"

WAZUH_HOST="${WAZUH_HOST:-192.168.10.14}"
WAZUH_SSH_USER="${WAZUH_SSH_USER:-analyst}"
WAZUH_SSH_PASS="${WAZUH_SSH_PASS:-}"
KALI_ATTACK_VM="${KALI_ATTACK_VM:-Kali Attack VM}"
KALI_DEFENSE_VM="${KALI_DEFENSE_VM:-Kali Defense VM}"
KALI_ATTACK_HOST="${KALI_ATTACK_HOST:-192.168.10.11}"
KALI_DEFENSE_HOST="${KALI_DEFENSE_HOST:-192.168.10.12}"
KALI_USER="${KALI_USER:-kali}"
KALI_PASS="${KALI_PASS:-kali}"
WAIT_SECS="${WAIT_SECS:-70}"
EVIDENCE_DIR="$CSCY_ROOT/evidence/scenario-02-brute-force"

mkdir -p "$EVIDENCE_DIR"

echo "=== Scenario 02: SSH Brute Force Detection ==="

# ── Step 1: Start Kali Attack VM ─────────────────────────────────────────────
echo "[1/6] Starting Kali Attack VM (headless)..."
VBoxManage startvm "$KALI_ATTACK_VM" --type headless 2>/dev/null || true
echo "  Waiting 30s for VM to boot..."
sleep 30

# ── Step 2: Bootstrap SSH on Kali Attack ─────────────────────────────────────
echo "[2/6] Bootstrapping SSH on Kali Attack VM..."
VBoxManage guestcontrol "$KALI_ATTACK_VM" run \
  --exe /bin/bash \
  --username "$KALI_USER" \
  --password "$KALI_PASS" \
  -- -lc "echo 'kali' | sudo -S systemctl start ssh" 2>/dev/null || true
sleep 5

# ── Step 3: Bootstrap SSH on Kali Defense (idempotent) ───────────────────────
echo "[3/6] Bootstrapping SSH on Kali Defense VM (idempotent)..."
VBoxManage guestcontrol "$KALI_DEFENSE_VM" run \
  --exe /bin/bash \
  --username "$KALI_USER" \
  --password "$KALI_PASS" \
  -- -lc "echo 'kali' | sudo -S systemctl start ssh" 2>/dev/null || true
sleep 5

# ── Step 4: Run hydra brute force from Kali Attack against Kali Defense ──────
echo "[4/6] Running hydra from Kali Attack (${KALI_ATTACK_HOST}) against Kali Defense (${KALI_DEFENSE_HOST}) SSH..."
start_ts=$(date +%s)
export SSHPASS="$KALI_PASS"
sshpass -e ssh -F /dev/null \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=15 \
  "${KALI_USER}@${KALI_ATTACK_HOST}" \
  "timeout 45 hydra -l kali -P /usr/share/wordlists/rockyou.txt.gz \
     -t 4 ssh://${KALI_DEFENSE_HOST} 2>/dev/null; \
   hydra -l kali \
     -p w1 -p w2 -p w3 -p w4 -p w5 \
     -p w6 -p w7 -p w8 -p w9 -p w10 \
     -t 4 ssh://${KALI_DEFENSE_HOST} 2>/dev/null; true" 2>/dev/null || true
echo "  Hydra run complete at $(date -Iseconds)"

# ── Step 5: Wait for alert propagation ───────────────────────────────────────
echo "[5/6] Waiting ${WAIT_SECS}s for alert pipeline latency..."
sleep "$WAIT_SECS"

# ── Step 6: Check Wazuh alerts.json for rules 100002, 5763, 5716 ─────────────
echo "[6/6] Querying Wazuh (${WAZUH_HOST}) for rules 100002/5763/5716 from agent 001..."
alert_snippet=""
rule_fired=""
found=0

if [[ -n "$WAZUH_SSH_PASS" ]] && command -v sshpass &>/dev/null; then
  export SSHPASS="$WAZUH_SSH_PASS"
  for rule_id in 100002 5763 5716; do
    raw=$(sshpass -e ssh -F /dev/null \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "${WAZUH_SSH_USER}@${WAZUH_HOST}" \
      "echo '${WAZUH_SSH_PASS}' | sudo -S grep -E '\"id\":\"${rule_id}\"' \
       /var/ossec/logs/alerts/alerts.json 2>/dev/null | tail -3" 2>/dev/null) || true
    # Accept alert only if it came from agent 001 (Kali Defense)
    if echo "$raw" | grep -q "\"id\":\"${rule_id}\"" && \
       echo "$raw" | grep -q '"001"'; then
      found=1
      rule_fired="$rule_id"
      alert_snippet="$raw"
      echo "  Found rule ${rule_id} alert from agent 001."
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
  "scenario": "02-ssh-brute-force",
  "outcome": "${outcome}",
  "rule_fired": "${rule_fired}",
  "latency_seconds": ${latency},
  "expected_rule_ids": "5716|5763|100002",
  "alert_snippet": "${safe_snippet}",
  "timestamp": "$(date -Iseconds)"
}
EOF

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Scenario 02 Result: ${outcome} (latency ${latency}s) ==="
echo "    Rule fired: ${rule_fired:-none}"
echo "    Evidence:   $EVIDENCE_DIR/result.json"
[[ "$outcome" == "PASS" ]] && exit 0 || exit 1
