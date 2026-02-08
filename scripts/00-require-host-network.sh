#!/usr/bin/env bash
# Probe host network connectivity to the Wazuh VM.
# Runs ping + curl checks and prints PASS/FAIL per check.

set -uo pipefail

WAZUH_HOST="${WAZUH_HOST:-192.168.10.14}"
VBOXNET_IP="192.168.10.1"

fails=0

# ── Helper ────────────────────────────────────────────────────────────────────
pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*"; (( fails++ )) || true; }
warn() { echo "[WARN] $*"; }

# ── Check 1: vboxnet0 IP ──────────────────────────────────────────────────────
if ip addr show vboxnet0 2>/dev/null | grep -q "$VBOXNET_IP"; then
  pass "vboxnet0 has $VBOXNET_IP configured"
else
  warn "vboxnet0: $VBOXNET_IP not found — run: sudo VBoxManage hostonlyif ipconfig vboxnet0 --ip $VBOXNET_IP --netmask 255.255.255.0"
fi

# ── Check 2: ping ─────────────────────────────────────────────────────────────
if ping -c 2 -W 2 "$WAZUH_HOST" &>/dev/null; then
  pass "ping $WAZUH_HOST"
else
  fail "ping $WAZUH_HOST"
fi

# ── Check 3: dashboard (443) ──────────────────────────────────────────────────
if curl -k -I --max-time 8 "https://$WAZUH_HOST:443" 2>/dev/null | grep -q "HTTP/"; then
  pass "https://$WAZUH_HOST:443 (dashboard)"
else
  fail "https://$WAZUH_HOST:443 (dashboard)"
fi

# ── Check 4: API (55000) ──────────────────────────────────────────────────────
if curl -k -I --max-time 8 "https://$WAZUH_HOST:55000" 2>/dev/null | grep -q "HTTP/"; then
  pass "https://$WAZUH_HOST:55000 (API)"
else
  fail "https://$WAZUH_HOST:55000 (API)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
if (( fails == 0 )); then
  echo "All checks passed. Next: ./scripts/02-deploy-wazuh-rules.sh"
  exit 0
else
  echo "$fails check(s) failed."
  exit 1
fi
