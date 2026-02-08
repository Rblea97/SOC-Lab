#!/usr/bin/env bash
# Check host dependencies and VM name configuration before running lab scripts.
# Runs one PASS/FAIL/WARN line per check; exits 1 if any required binary is missing.

set -uo pipefail

KALI_DEFENSE_VM="${KALI_DEFENSE_VM:-Kali Defense VM}"
KALI_ATTACK_VM="${KALI_ATTACK_VM:-Kali Attack VM}"

fails=0

# ── Helpers ───────────────────────────────────────────────────────────────────
pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*"; (( fails++ )) || true; }
warn() { echo "[WARN] $*"; }

# ── Section A: Required binaries ──────────────────────────────────────────────
echo "=== Section A: Required binaries ==="

check_binary() {
  local bin="$1" apt_pkg="$2" dnf_pkg="$3"
  if command -v "$bin" &>/dev/null; then
    pass "$bin found ($(command -v "$bin"))"
  else
    fail "$bin not found — install with: apt install $apt_pkg  OR  dnf install $dnf_pkg"
  fi
}

check_binary VBoxManage  virtualbox        VirtualBox
check_binary sshpass     sshpass           sshpass
check_binary ssh         openssh-client    openssh-clients
check_binary curl        curl              curl
check_binary python3     python3           python3

# ── Section B: VM name validation ─────────────────────────────────────────────
echo ""
echo "=== Section B: VM name validation ==="

if ! command -v VBoxManage &>/dev/null; then
  warn "VBoxManage not available — skipping VM name checks"
else
  vm_list="$(VBoxManage list vms 2>/dev/null)"

  if echo "$vm_list" | grep -qF "\"${KALI_DEFENSE_VM}\""; then
    pass "VM found: '${KALI_DEFENSE_VM}'"
  else
    warn "VM not found: '${KALI_DEFENSE_VM}' — if your VM has a different name, set: export KALI_DEFENSE_VM='Your VM Name'"
  fi

  if echo "$vm_list" | grep -qF "\"${KALI_ATTACK_VM}\""; then
    pass "VM found: '${KALI_ATTACK_VM}'"
  else
    warn "VM not found: '${KALI_ATTACK_VM}' — if your VM has a different name, set: export KALI_ATTACK_VM='Your VM Name'"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
if (( fails == 0 )); then
  echo "All required dependencies present. Next: bash scripts/00-require-host-network.sh"
  exit 0
else
  echo "$fails dependency/dependencies missing. Install above packages, then re-run."
  exit 1
fi
