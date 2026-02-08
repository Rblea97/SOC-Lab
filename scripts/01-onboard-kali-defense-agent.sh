#!/usr/bin/env bash
# Install and start Wazuh agent on Kali Defense VM via VBoxManage guestcontrol.
# Requires: Kali Defense VM running, guest additions, kali/kali (or KALI_USER/KALI_PASS).

set -euo pipefail

CSCY_ROOT="${CSCY_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
WAZUH_HOST="${WAZUH_HOST:-192.168.10.14}"
KALI_DEFENSE_VM="${KALI_DEFENSE_VM:-Kali Defense VM}"
KALI_USER="${KALI_USER:-kali}"
KALI_PASS="${KALI_PASS:-kali}"
GUESTCONTROL_TIMEOUT="${GUESTCONTROL_TIMEOUT:-600000}"

run_guest() {
  VBoxManage guestcontrol "$KALI_DEFENSE_VM" run \
    --exe /bin/bash \
    --username "$KALI_USER" \
    --password "$KALI_PASS" \
    --timeout "$GUESTCONTROL_TIMEOUT" \
    -- -lc "$*"
}

echo "=== Onboarding Wazuh agent on $KALI_DEFENSE_VM (manager $WAZUH_HOST) ==="

# 1) Create keyring with permissions so gpgv can read it
run_guest "echo '$KALI_PASS' | sudo -S bash -lc \"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /etc/apt/keyrings/wazuh.gpg
  chmod 644 /etc/apt/keyrings/wazuh.gpg
\""

# 2) Add Wazuh repo
run_guest "echo '$KALI_PASS' | sudo -S bash -lc \"
  echo 'deb [signed-by=/etc/apt/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main' > /etc/apt/sources.list.d/wazuh.list
\""

# 3) Update and install agent (WAZUH_MANAGER set so agent registers to .14)
run_guest "echo '$KALI_PASS' | sudo -S bash -lc \"
  apt-get update
  WAZUH_MANAGER=$WAZUH_HOST apt-get install -y wazuh-agent
  systemctl daemon-reload
  systemctl enable wazuh-agent
  systemctl start wazuh-agent
\""

echo "=== Wazuh agent installed and started on $KALI_DEFENSE_VM ==="
echo "Confirm in Wazuh dashboard: Management -> Agents (expect 192.168.10.12)."
