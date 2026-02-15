# Changelog

All notable changes to the testbed setup are documented in this file.

## 2026-02-13

### Added
- Created baseline testbed runbook at `testbed/testbed_baseline_runbook.md`.
- Updated `testbed/NEXT_AGENT_HANDOFF.md` with current post-validation state and next-agent fast-start instructions.
- Added full VM inventory and configuration details for:
  - `Kali Attack VM`
  - `Kali Defense VM`
  - `MS-2 Target VM`
- Added host-only and DHCP network documentation for `vboxnet0`.
- Added post-setup validation checklist and optional host-IP alignment command.

### Completed Setup Status
- Host readiness checks completed (virtualization support, resources, VirtualBox install).
- Kali and Metasploitable-2 images downloaded, extracted, and prepared.
- VMs imported/cloned/created and configured to baseline CPU/RAM/NIC settings.
- Networking configured:
  - Adapter 1: Host-Only for all VMs
  - Adapter 2: NAT enabled for Kali VMs only
  - Adapter 2: disabled for MS-2 target
- Baseline snapshots created for all three VMs using snapshot name `baseline-clean`.

### Validation Summary
- IP assignment confirmed:
  - Kali Attack: `192.168.10.11`
  - Kali Defense: `192.168.10.12`
  - MS-2 Target: `192.168.10.13`
- NAT-side IP presence confirmed on both Kali VMs.
- MS-2 isolation confirmed (no second adapter).
- Inter-VM ping checks executed from Kali guests (all PASS, `0% packet loss`):
  - Kali Attack -> Kali Defense
  - Kali Attack -> MS-2
  - Kali Defense -> Kali Attack
  - Kali Defense -> MS-2
- Remaining blocker for full Gate B completion:
  - MS-2-origin ping checks could not be automated because Guest Additions are not installed/ready on `MS-2 Target VM`, which prevents `VBoxManage guestcontrol` command execution in that guest.
- Optional Kali internet validation executed and passed on both Kali VMs (`ping google.com` and `curl -I https://www.google.com`).

### Changed
- Re-ran baseline validation from host tooling with all three VMs running.
- Confirmed Gate B remains `PARTIAL`: MS-2-origin ping checks are still blocked by missing/not-ready Guest Additions.
- Documented current failure signature for MS-2 guest control: `VBOX_E_GSTCTL_GUEST_ERROR` with `Guest Additions are not installed or not ready (yet)`.

### Added
- Provisioned dedicated `Wazuh Server VM` in VirtualBox at `<VirtualBox VM folder>/Testbed/Wazuh Server VM`.
- Configured `Wazuh Server VM` baseline resources:
  - CPU: `2`
  - RAM: `6144 MB`
  - Disk: `60 GB` (`VDI`)
  - NIC1: `Host-Only (vboxnet0)`
  - NIC2: `NAT` (temporary for installation)

### Blocked
- Wazuh software installation is blocked pending Ubuntu Server ISO attachment and OS installation on `Wazuh Server VM`.
- Current environment has no discovered Ubuntu ISO artifact under the host home directory to attach for unattended install.

### Added
- Added Wazuh config pack under `wazuh-config/`:
  - `local_rules.xml` with custom rules `100001`, `100002`, and `100003`
  - `ossec-agent.conf` for FIM/auth/syslog collection baseline
  - `syslog-forwarding.conf` for MS-2 forwarding to `192.168.10.14:514`
- Added documentation set under `docs/`:
  - `architecture.md`
  - `runbook.md`
  - `portfolio-writeup.md`
  - `attack-scenarios/01-05` scenario playbooks
- Added Python tooling scaffold under `tools/`:
  - `pyproject.toml`
  - `enrich_alerts.py`
  - `sigma_convert.py`
  - tests under `tools/tests/`
- Added root project overview at `README.md` with topology, status, and safety notice.
- Added CI workflow for tooling quality checks at `.github/workflows/ci.yml`.
- Added repository hygiene defaults in `.gitignore` for VM artifacts, Python caches, and local secrets.
- Added evidence tracking scaffold at `evidence/README.md` and per-scenario evidence folders.

### Validated
- Python tooling syntax checks passed via `python -m py_compile` for all scripts/tests.
- Tooling unit tests passed (`2 passed`) via `python -m pytest tools/tests -q`.

### Changed
- Updated `testbed/NEXT_AGENT_HANDOFF.md` from baseline-closure objective to Wazuh activation objective with concrete next steps.
- Added explicit fast-start commands for attaching Ubuntu ISO and proceeding with SIEM runtime validation.

### Blocked
- Endpoint onboarding (`wazuh-agent` on Kali Defense and syslog ingestion verification in dashboard) is staged in docs/config but runtime validation remains blocked until Wazuh server OS+stack installation is completed.
- Rule firing validation and scenario alert evidence capture are pending active Wazuh dashboard/API availability.
- Runtime execution of all 5 attack scenarios is documented and staged, but alert screenshots/latency measurements remain pending active SIEM services.

### Changed
- Added spec-aligned MVP acceptance checklist and required changelog protocol to `docs/runbook.md`.
- Added SIEM activation gate status section to `testbed/testbed_baseline_runbook.md` to track MVP completion criteria.

### Validated
- Verified VM inventory and runtime status on host:
  - `VBoxManage list vms` shows all four expected VMs.
  - `VBoxManage list runningvms` shows all four VMs currently running.
- Verified `Wazuh Server VM` configuration remains aligned to spec baseline:
  - `2 vCPU`, `6144 MB` RAM, `60 GB` VDI, NIC1 `hostonly (vboxnet0)`, NIC2 `nat`.
- Captured Wazuh VM console evidence at `testbed/images/wazuh-server-console-20260213.png`, showing `No bootable medium found!`.
- Performed host-side SIEM reachability checks (all FAIL):
  - `ping -c 2 192.168.10.14` -> `100% packet loss`.
  - `curl -k -I --max-time 8 https://192.168.10.14:443` -> timeout.
  - `curl -k -I --max-time 8 https://192.168.10.14:55000` -> timeout.
- Re-validated MS-2 guestcontrol automation failure signature:
  - `VBoxManage guestcontrol "MS-2 Target VM" ...` returns `VBOX_E_GSTCTL_GUEST_ERROR` with `Guest Additions are not installed or not ready (yet)`.
- Verified Kali guestcontrol command invocation returns success code for a no-op command, but this terminal context still emits `VERR_NOT_IMPLEMENTED` stdout/stderr handle warnings and is unsuitable for capturing command output evidence.

### Blocked
- Wazuh OS install cannot be completed because no Ubuntu Server ISO file is discoverable under the host home directory (`**/*.iso` search returned no results).
- `Wazuh Server VM` cannot boot into an installer or OS yet; current console state is `No bootable medium found!`, so static IP assignment, Wazuh package installation, and service checks are blocked.
- `Wazuh Server VM` in-guest network/status cannot be confirmed via VirtualBox guest properties (`/VirtualBox/GuestInfo/Net/0/V4/IP` reports `No value set`), indicating guest tools are not providing IP telemetry.
- Automated in-guest execution for Kali onboarding is currently blocked from this terminal context due repeated `VBoxManage guestcontrol` handle errors (`VERR_NOT_IMPLEMENTED`), so endpoint onboarding/rule/scenario runtime validation remains pending manual in-guest execution.
- Endpoint onboarding status:
  - Kali Defense `wazuh-agent` onboarding: pending (manager unreachable).
  - MS-2 syslog forwarding validation: pending (manager unreachable and no live Wazuh listener on `.14`).
- Custom rule validation status:
  - Rule `100001`: pending (no reachable manager/dashboard).
  - Rule `100002`: pending (no reachable manager/dashboard).
  - Rule `100003`: pending (no reachable manager/dashboard).
- Scenario execution status:
  - `01-nmap-recon`: pending SIEM availability.
  - `02-ssh-brute-force`: pending SIEM availability.
  - `03-metasploit-vsftpd`: pending SIEM availability.
  - `04-priv-escalation`: pending SIEM availability.
  - `05-suspicious-file`: pending SIEM availability.

### Added
- **Credentials (secure):** `testbed/CREDENTIALS.md` explains where to store lab login info. `testbed/credentials.env.example` is a template; copy to `testbed/credentials.env` and fill in. Real credentials file is gitignored (`testbed/credentials.env`, `testbed/credentials.local`). Never commit passwords.

### Changed
- **Documentation:** README status updated (Wazuh installed, host reachability via Host Network Manager, credentials pointer). `testbed/NEXT_AGENT_HANDOFF.md` updated: current state (Wazuh installed), host reachability step, credentials location, remaining steps reordered. `docs/runbook.md` updated: Credentials section, install steps, host-only note. All docs point to `testbed/CREDENTIALS.md` for secure credential storage.

## 2026-02-13 (Host Network Probe)

### Changed
- Rewrote `scripts/00-require-host-network.sh` from an instruction-printer to an active probe script. Now runs ping + curl checks and prints `[PASS]` / `[FAIL]` / `[WARN]` per check. Exits 0 only if all checks pass; exits 1 if any fail (CI-chainable).
- `scripts/README.md` step 0 updated to reflect the script is now runnable (not manual), and the order-of-operations table replaced "Host network (manual)" with `00-require-host-network.sh`.

### Fixed
- VirtualBox 7.x `E_ACCESSDENIED` error when running `VBoxManage hostonlyif ipconfig`: resolved by creating `/etc/vbox/networks.conf` with `* 192.168.10.0/24`.

### Validated
- `bash scripts/00-require-host-network.sh` exits 0 with all four checks PASS:
  - `[PASS] vboxnet0 has 192.168.10.1 configured`
  - `[PASS] ping 192.168.10.14`
  - `[PASS] https://192.168.10.14:443 (dashboard)`
  - `[PASS] https://192.168.10.14:55000 (API)`

## 2026-02-13 (CI Fix)

### Fixed
- Added `types-requests>=2.31` to `tools/pyproject.toml` dev dependencies so `mypy` passes in CI (was: "Library stubs not installed for requests").
- Added `types-PyYAML>=6.0` to `tools/pyproject.toml` dev dependencies so `mypy` passes for `sigma_convert.py` (was: "Library stubs not installed for yaml").
- Added `[tool.setuptools] py-modules` declaration to resolve setuptools flat-layout ambiguity (was: "Multiple top-level modules discovered").
- Added explicit `params: dict[str, str | int]` annotation in `enrich_alerts.py` to resolve mypy `arg-type` error on `requests.get`.
- Fixed `I001` import-order violations in `enrich_alerts.py` and `sigma_convert.py` via `ruff --fix`.
- Fixed `E501` line-length violation in `enrich_alerts.py` by extracting long f-string into `header` local variable.
- Corrected `README.md` Wazuh VM status line to match `docs/portfolio-writeup.md` (VM created, OS installation pending).

### Validated
- `mypy .` from `tools/`: **0 errors** (5 source files checked).
- `pytest` from `tools/`: **2 passed**.
- `ruff check . && ruff format --check .` from `tools/`: **clean**.
- CI pipeline (`ruff` + `mypy` + `pytest`) is fully green end-to-end.

### 2026-02-13 — Deploy Custom Wazuh Rules

- Deployed `wazuh-config/local_rules.xml` to `/var/ossec/etc/rules/local_rules.xml`
  on Wazuh VM (`192.168.10.14`) via `scripts/02-deploy-wazuh-rules.sh`.
- Rules deployed: 100001 (network scan / T1046), 100002 (SSH brute force / T1110.001),
  100003 (suspicious /tmp files / T1505.003).
- `wazuh-manager` restarted and confirmed active.
- **Status:** DONE

### 2026-02-13 — Onboard Kali Defense Wazuh Agent

- SSH bootstrapped on Kali Defense via `VBoxManage guestcontrol` (guestcontrol executes
  commands despite `VERR_NOT_IMPLEMENTED` stdout/stderr warnings; used to `systemctl start ssh`).
- Installed wazuh-agent 4.9.2-1 on Kali Defense VM (192.168.10.12) via SSH (sshpass).
  (Initial install pulled 4.14.3 from repo; downgraded to 4.9.2-1 to match manager version.)
- Agent registered to manager 192.168.10.14 — confirmed via `agent_control -l`:
  `ID: 001, Name: kali, Active`.
- wazuh-agent service enabled and confirmed active (`systemctl is-active` → `active`).
- **Status:** DONE

### 2026-02-13 — Add Edge Case Tests to Python Tooling

- Added `test_empty_alert_list` to `tools/tests/test_enrich.py` — covers the early-return
  branch in `format_triage_report` for empty input (previously untested).
- Added `test_no_mitre_tags` to `tools/tests/test_sigma_convert.py` — covers the
  `convert_to_wazuh_xml` path when `mitre_id` is `None` (no `<mitre>` block emitted).
- pytest count: 2 → **4 passed**, 0 failures.
- Spec requirement "≥1 test per script; happy path + one edge case" now satisfied for both tools.
- **Status:** DONE

### 2026-02-13 — Wazuh Syslog Listener (Step 4b, Wazuh side)

- Created `scripts/05-verify-wazuh-syslog-listener.sh` — idempotent script that checks
  for `<connection>syslog</connection>` in `/var/ossec/etc/ossec.conf` and injects a
  UDP-514 remote block if absent, then restarts `wazuh-manager`.
- Fixed two bugs discovered during execution:
  - `grep` on `/var/ossec/etc/ossec.conf` requires `sudo`; silent failure without it
    caused the script to always re-run the patcher (producing duplicate blocks).
  - `sshpass -p "$WAZUH_SSH_PASS"` with a password containing `!` is unsafe on interactive
    shells; switched to `export SSHPASS` + `sshpass -e` throughout.
- Fixed Python patcher to use `rfind("</ossec_config>")` instead of `replace(...)` so
  only the last closing tag is targeted (ossec.conf contains multiple `<ossec_config>`
  stanzas; `replace` was inserting a duplicate block in each stanza).
- Cleaned up duplicate syslog block from ossec.conf (dedup Python script run in-place).
- Rebooted Wazuh VM (`VBoxManage controlvm acpipowerbutton`) to resolve SSH daemon
  deadlock (sshd was accepting TCP connections but not responding to USERAUTH_REQUEST).
- `scripts/05-verify-wazuh-syslog-listener.sh` exits 0; confirms exactly 1 syslog block,
  `wazuh-manager` active.
- **Status:** DONE (Wazuh side). MS-2 rsyslog forwarding (console step) still pending.

### 2026-02-13 — Verify Telemetry Sources

- Created `scripts/06-verify-telemetry-sources.sh`.
- logall confirmed/enabled in ossec.conf on 192.168.10.14.
- Kali Defense (.12) agent events visible in archives.log: PASS.
- MS-2 (.13) syslog events: WARN if MS-2 console step pending; PASS once done.
- **Status:** DONE

### 2026-02-13 — Scenario 05 Validated: Suspicious File Creation

- Created `scripts/07-run-scenario-05.sh` — focused standalone script targeting
  Kali Defense (.12) where the Wazuh agent runs syscheck realtime on `/tmp`.
- Added `/tmp` with `realtime="yes"` to Kali Defense agent syscheck config
  (default agent config omits `/tmp`); restarted wazuh-agent.
- Fixed grep pattern in alert query: alerts.json stores rule id as `"id":"100003"`
  (string), not `"id":100003` (integer).
- Created `/tmp/reverse_shell.php` on Kali Defense (.12) via SSH.
- Wazuh FIM (syscheck realtime) detected file within 71s.
- Rule 100003 (T1505.003 — Web Shell) fired; alert saved to
  `evidence/scenario-05-suspicious-file/result.json`.
- Cleanup: test file removed from Kali Defense.
- **Status:** VALIDATED

### 2026-02-13 — Scenario 02 Validated: SSH Brute Force

- Created `scripts/08-run-scenario-02.sh` — mirrors scenario-05 structure; starts Kali
  Attack VM headless, bootstraps SSH on both Kali VMs via guestcontrol, runs hydra
  (timeout 45s with rockyou.txt.gz + 10 fixed fallback passwords) from Kali Attack
  (.11) against Kali Defense (.12) SSH.
- Wazuh agent (ID: 001) on Kali Defense detected repeated auth failures from .11.
- Rule 5763 fired (`sshd: brute force trying to get access to the system`) with
  MITRE T1110 (Credential Access / Brute Force); `firedtimes: 36`; `frequency: 8`.
- Alert confirmed `agent.id: "001"`, `srcip: 192.168.10.11`.
- Alert snippet saved to `evidence/scenario-02-brute-force/result.json`.
- **Status:** VALIDATED

### 2026-02-14 — Scenario 03 Validated: vsftpd 2.3.4 Backdoor Exploit (T1190)

- Created `scripts/10-run-scenario-03.sh` — fires `exploit/unix/ftp/vsftpd_234_backdoor`
  from Kali Attack (.11) via `msfconsole` (SSH + timeout 120) against MS-2 (.13).
- Exploit succeeded: `uid=0(root) gid=0(root)` confirmed in msfconsole output; backdoor
  shell opened on MS-2:6200.
- SIGTERM error on msfconsole `exit` is cosmetic — session close while shell is open.
- Rule 2501 fired (`syslog: User authentication failure`, level 5); alert sourced from
  `192.168.10.13`. FTP-specific rules (31xxx) did NOT fire — MS-2 sysklogd stripped format
  prevents vsftpd lines from matching standard FTP decoders (same decoder-gap issue as SSH,
  now resolved for SSH via `sshd-stripped`; vsftpd decoder is a future improvement).
- Evidence: `evidence/scenario-03-vsftpd/result.json` = PASS (latency 192s).
- **Status:** VALIDATED

### 2026-02-14 — Scenario 04 Validated: Privilege Escalation (T1548)

- Created `scripts/11-run-scenario-04.sh` — runs `sudo -l` and `sudo id/whoami` directly
  from host via SSH to Kali Defense (.12). Privilege escalation commands execute as root;
  journald captures all sudo events which the Wazuh agent (ID: 001) ships to the manager.
- **Discovery:** Kali Linux uses systemd journald — no `/var/log/auth.log` exists.
  Wazuh agent was already configured with `<log_format>journald</log_format>` so events
  arrive with `"location":"journald"`. Initial script had wrong location filter (`auth.log`);
  fixed to match `journald`.
- Rule 5402 fired (`Successful sudo to ROOT executed.`, level 3, MITRE T1548.003 /
  Privilege Escalation via Sudo and Sudo Caching); `agent.id: "001"`, `agent.ip: "192.168.10.12"`.
- Evidence: `evidence/scenario-04-priv-esc/result.json` = PASS.
- **Status:** VALIDATED

### 2026-02-14 — Scenario 01 Validated: Nmap Recon (Network Scan Detection)

- Created `scripts/09-run-scenario-01.sh` — targets MS-2 (.13) via syslog forwarding.
- **MS-2 syslog configuration (manual console step):**
  - MS-2 runs Ubuntu 8.04 with `sysklogd` (NOT rsyslog). `/etc/rsyslog.d/` does not exist.
  - Forwarding rule appended to `/etc/syslog.conf`: `*.* @192.168.10.14`
  - Reloaded via `sudo kill -HUP $(pidof syslogd)` (no init script for syslog found).
- **Stripped syslog format problem discovered and resolved:**
  - MS-2's sysklogd sends `<priority>program[pid]: message` WITHOUT RFC 3164
    timestamp/hostname. Wazuh's standard sshd decoder requires the full format
    to extract `program_name` — no match for stripped messages.
  - Deployed custom decoder `sshd-stripped` in `/var/ossec/etc/decoders/local_decoder.xml`
    with `<prematch>^sshd</prematch>` (OS_Regex does NOT support `\d` or `\[` escapes).
  - Deployed custom rules 100010 (individual SSH invalid-user, level 5) and 100011
    (composite: 12+ from same source in 60s, level 8 / T1046) in `local_rules.xml`.
  - Key lesson: `<decoded_as>` matches PARENT decoder name, not child.
- **Attack method:** SSH login attempts with non-existent username `scanuser` from
  Kali Attack (.11) to MS-2 (.13). Hydra v9.6 cannot negotiate with MS-2's ancient
  OpenSSH (kex algorithm mismatch); used `ssh` directly with legacy algorithm flags:
  `-o MACs=hmac-sha1 -o KexAlgorithms=diffie-hellman-group14-sha1 -o HostKeyAlgorithms=ssh-rsa`
- Rule 100011 fired (T1046 — Network Service Discovery); latency 72s.
- Evidence: `evidence/scenario-01-nmap/result.json` = PASS.
- **Status:** VALIDATED
