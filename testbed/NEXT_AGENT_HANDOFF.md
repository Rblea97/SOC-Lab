# Next Agent Handoff

Date: 2026-02-14
Project root: `<project-root>`

## Current State (Completed)

### Infrastructure

- All four VMs configured.
  - Kali Attack: `192.168.10.11`
  - Kali Defense: `192.168.10.12`
  - MS-2 Target: `192.168.10.13`
  - Wazuh Server: `192.168.10.14`
- `vboxnet0` host-only adapter at `192.168.10.1/24` (persists via `/etc/vbox/networks.conf`).
- Credentials in `testbed/credentials.env` (gitignored); SSH to Wazuh uses `analyst@192.168.10.14`.

### SIEM

- Wazuh 4.9.2 all-in-one on `192.168.10.14`; dashboard and API confirmed reachable.
- Custom rules deployed in `/var/ossec/etc/rules/local_rules.xml`:
  - `100001` (network scan / T1046 — composite on rule 5710)
  - `100002` (SSH brute force / T1110.001)
  - `100003` (suspicious /tmp files / T1505.003)
  - `100010` (SSH invalid-user from stripped syslog / T1110.001)
  - `100011` (composite: 12+ SSH invalid-user from same source in 60s / T1046)
- Custom decoder deployed in `/var/ossec/etc/decoders/local_decoder.xml`:
  - `sshd-stripped` — handles MS-2's sysklogd stripped format (no RFC 3164 header)
- **Syslog listener configured:** `<remote>` block (UDP 514, allowed `192.168.10.0/24`)
  present in `/var/ossec/etc/ossec.conf`.
- `logall yes` enabled in ossec.conf; `archives.log` populated.

### Endpoint Onboarding

- **Kali Defense (`.12`):** `wazuh-agent` 4.9.2-1 installed and running; registered to
  manager as `ID: 001, Name: kali, Active`.
  - **IMPORTANT:** `/tmp` has been added with `realtime="yes"` to the agent's
    `/var/ossec/etc/ossec.conf`. Do not overwrite without preserving.
- **MS-2 Target (`.13`):** syslog forwarding CONFIGURED — `*.* @192.168.10.14` appended
  to `/etc/syslog.conf` on MS-2 (Ubuntu 8.04 sysklogd). Works when VM is running.
  **MS-2 VM shuts down when left idle — must verify it's running before scenarios.**

### Scenario Evidence

| Scenario | Status | Script | Rule Fired | Evidence |
|----------|--------|--------|-----------|----------|
| 01 — Nmap Recon | **VALIDATED 2026-02-14** | `scripts/09-run-scenario-01.sh` | 100011 (T1046) | `evidence/scenario-01-nmap/result.json` |
| 02 — SSH Brute Force | **VALIDATED 2026-02-13** | `scripts/08-run-scenario-02.sh` | 5763 (T1110) | `evidence/scenario-02-brute-force/result.json` |
| 03 — vsftpd Exploit | **VALIDATED 2026-02-14** | `scripts/10-run-scenario-03.sh` | 2501 (T1190) | `evidence/scenario-03-vsftpd/result.json` |
| 04 — Priv Escalation | **VALIDATED 2026-02-14** | `scripts/11-run-scenario-04.sh` | 5402 (T1548.003) | `evidence/scenario-04-priv-esc/result.json` |
| 05 — Suspicious File | **VALIDATED 2026-02-13** | `scripts/07-run-scenario-05.sh` | 100003 (T1505.003) | `evidence/scenario-05-suspicious-file/result.json` |

**5/5 scenarios validated. MVP acceptance criterion met.**

### Tooling / CI

- Python tooling (`tools/`) passes `mypy`, `pytest` (26 tests), `ruff` — CI green.

---

## Known Environment Quirks

- **Wazuh SSH pattern** (password has `!` — sshpass -p breaks):
  ```bash
  source testbed/credentials.env
  export SSHPASS="$WAZUH_SSH_PASS"
  sshpass -e ssh -F /dev/null -o StrictHostKeyChecking=no analyst@192.168.10.14 'cmd'
  ```
  Always `-F /dev/null` to skip host's `20-systemd-ssh-proxy.conf`.

- **Writing files to Wazuh via SSH**: `echo pw | sudo -S tee file` with heredoc does
  NOT work (pipe swallows SSH stdin). Write to `/tmp/` first, then `sudo cp`.

- **Kali SSH bootstrap** (SSH disabled by default; must start per session):
  ```bash
  VBoxManage guestcontrol "Kali Attack VM" run --exe /bin/bash \
    --username kali --password kali -- -lc \
    "echo 'kali' | sudo -S systemctl start ssh"
  ```

- **sshpass NOT installed on Kali Attack** — do NOT use `sshpass` in commands that
  run inside Kali Attack VM.

- **Hydra v9.6 cannot connect to MS-2 SSH** — kex algorithm mismatch. Use `ssh`
  directly with legacy flags:
  ```bash
  ssh -o MACs=hmac-sha1 \
      -o KexAlgorithms=diffie-hellman-group14-sha1,diffie-hellman-group1-sha1 \
      -o HostKeyAlgorithms=ssh-rsa \
      -o StrictHostKeyChecking=no -o BatchMode=yes \
      user@192.168.10.13
  ```

- **MS-2 stripped syslog**: sysklogd sends `<pri>program[pid]: msg` (no timestamp/hostname).
  Standard Wazuh decoders don't match. Custom decoder `sshd-stripped` handles SSH events.
  For OTHER services (FTP, etc.), new decoders may be needed following the same pattern.

- **Wazuh OS_Regex quirks**: `\d` NOT supported (use `[0-9]`), `\[` in prematch causes
  parse errors, `<decoded_as>` matches PARENT decoder name not child.

- **MS-2 VM shuts down if left idle** — always `VBoxManage list runningvms | grep MS-2`
  before running MS-2 scenarios.

- **alerts.json rule id format:** `"id":"100003"` (string, not integer).

- Wazuh VM SSH can deadlock — reboot with `VBoxManage controlvm "Wazuh Server VM" acpipowerbutton`.

---

## Remaining Required Steps

1. ~~Verify host reachability~~ **DONE**
2. ~~Store credentials~~ **DONE**
3. ~~Deploy custom rules~~ **DONE (2026-02-13, updated 2026-02-14)**
4. ~~Onboard Kali Defense wazuh-agent~~ **DONE (2026-02-13)**
4b. ~~Configure Wazuh syslog listener (UDP 514)~~ **DONE (2026-02-13)**
4c. ~~Configure MS-2 syslog forwarding~~ **DONE (2026-02-14)** — via console
5. ~~Write `scripts/06-verify-telemetry-sources.sh`~~ **DONE (2026-02-13)**
6. Execute five attack scenarios (5/5 done):
   - ~~Scenario 05~~ **DONE (2026-02-13)** — `scripts/07-run-scenario-05.sh`; rule 100003
   - ~~Scenario 02~~ **DONE (2026-02-13)** — `scripts/08-run-scenario-02.sh`; rule 5763
   - ~~Scenario 01~~ **DONE (2026-02-14)** — `scripts/09-run-scenario-01.sh`; rule 100011
   - ~~Scenario 03~~ **DONE (2026-02-14)** — `scripts/10-run-scenario-03.sh`; rule 2501
   - ~~Scenario 04~~ **DONE (2026-02-14)** — `scripts/11-run-scenario-04.sh`; rule 5402
7. ~~Update `testbed/CHANGELOG.md` with `Validated` entries after each scenario.~~ **DONE**

**All 5/5 attack scenarios validated. MVP complete.**

---

## Useful Commands

```bash
# Check running VMs
VBoxManage list runningvms

# Start VMs
VBoxManage startvm "Wazuh Server VM" --type headless
VBoxManage startvm "Kali Defense VM" --type headless
VBoxManage startvm "Kali Attack VM" --type headless
VBoxManage startvm "MS-2 Target VM" --type gui

# SSH to Wazuh manager
source testbed/credentials.env
export SSHPASS="$WAZUH_SSH_PASS"
sshpass -e ssh -F /dev/null -o StrictHostKeyChecking=no analyst@192.168.10.14 'hostname'

# Check registered agents
source testbed/credentials.env && export SSHPASS="$WAZUH_SSH_PASS"
SSH="sshpass -e ssh -F /dev/null -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 analyst@192.168.10.14"
$SSH "echo '$WAZUH_SSH_PASS' | sudo -S /var/ossec/bin/agent_control -l 2>/dev/null"

# Run validated scenarios
bash scripts/09-run-scenario-01.sh   # Scenario 01
bash scripts/08-run-scenario-02.sh   # Scenario 02
bash scripts/10-run-scenario-03.sh   # Scenario 03
bash scripts/11-run-scenario-04.sh   # Scenario 04
bash scripts/07-run-scenario-05.sh   # Scenario 05
```

## Related Files

- `testbed/CHANGELOG.md` — milestone log
- `testbed/credentials.env` — SSH/API credentials (gitignored)
- `wazuh-config/` — config templates
- `scripts/` — automation scripts
- `docs/runbook.md` — full lab runbook with MVP checklist
- `docs/attack-scenarios/` — 5 scenario playbooks
- `evidence/` — per-scenario evidence folders
