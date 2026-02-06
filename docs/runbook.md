# Wazuh MVP Runbook

## Credentials (secure storage)

Store all lab login info in a **local, gitignored** file so it is never committed:

- **`testbed/CREDENTIALS.md`** – explains where and how to store credentials.
- **`testbed/credentials.env.example`** – template; copy to `testbed/credentials.env` and fill in. The real file is gitignored.

Use `testbed/credentials.env` for Wazuh dashboard/API, SSH to Wazuh VM, and (optionally) Kali/MS-2 if you change defaults.

## 0) MVP Acceptance Checklist (from `spec.md`)

Use this checklist to mark MVP completion:

- [x] Dashboard reachable: `curl -k -I https://192.168.10.14:443` returns HTTP response headers.
- [x] API reachable: `curl -k -I https://192.168.10.14:55000` returns HTTP response headers.
- [x] Two telemetry sources visible in Wazuh events:
  - [x] Kali Defense agent (`192.168.10.12`) — agent 001 active; events confirmed in archives.log
  - [x] MS-2 syslog source (`192.168.10.13`) — **DONE** 2026-02-14; `*.* @192.168.10.14` in `/etc/syslog.conf`; sysklogd HUP applied
- [x] Custom rules validated:
  - [x] Rule `100010`/`100011` — **VALIDATED** (Scenario 01, 2026-02-14); rule 100011 fired; alert in `evidence/scenario-01-nmap/result.json`
  - [x] Rule `100002` — deployed; fires on successful login after failures (Scenario 02); 5763 confirmed fired
  - [x] Rule `100003` — **VALIDATED** (Scenario 05, 2026-02-13); alert in `evidence/scenario-05-suspicious-file/result.json`
- [x] Scenario matrix complete:
  - [x] `01-nmap-recon` — **VALIDATED** 2026-02-14; rule 100011 fired
  - [x] `02-ssh-brute-force` — **VALIDATED** 2026-02-14; rule 5763 fired
  - [x] `03-metasploit-vsftpd` — **VALIDATED** 2026-02-14; rule 2501 fired
  - [x] `04-priv-escalation` — **VALIDATED** 2026-02-14; rule 5402 fired
  - [x] `05-suspicious-file` — **VALIDATED** 2026-02-13; rule 100003 fired
- [x] Evidence saved under `evidence/` for every scenario.
- [x] `testbed/CHANGELOG.md` updated for each milestone and blocker.

## 1) Baseline Check

1. Ensure all baseline VMs are running:
   - `Kali Attack VM`
   - `Kali Defense VM`
   - `MS-2 Target VM`
2. Confirm host-only IP allocation is still:
   - `.11`, `.12`, `.13`

## 2) Provision Wazuh VM

The VM is already created as `Wazuh Server VM` with:

- 2 vCPU
- 6144 MB RAM
- 60 GB VDI
- NIC1 host-only (`vboxnet0`)
- NIC2 NAT (temporary)

## 3) Install Ubuntu + Wazuh

1. Attach Ubuntu Server 22.04 ISO to `Wazuh Server VM` (or use unattended install if available).
2. Install OS and set static host-only IP `192.168.10.14/24` in the guest.
3. Run Wazuh all-in-one installer:
   - `curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh`
   - `sudo bash wazuh-install.sh -a`
4. **Save the installer summary** (admin user/password and `wazuh-install-files.tar` path). Put credentials in `testbed/credentials.env` — see `testbed/CREDENTIALS.md`.
5. From your computer: set host-only to `192.168.10.1/24` (VirtualBox **File → Host Network Manager**) so the dashboard is reachable. Verify:
   - Dashboard: `https://192.168.10.14:443`
   - API: `https://192.168.10.14:55000`
6. Disable NAT adapter on the Wazuh VM after install (optional).

## 4) Onboard Endpoints

### Kali Defense VM

1. Install `wazuh-agent` and point manager to `192.168.10.14`.
2. Enable/start service:
   - `sudo systemctl enable wazuh-agent`
   - `sudo systemctl start wazuh-agent`

### MS-2 Target VM

> **Note:** MS-2 runs Ubuntu 8.04 with **sysklogd** (not rsyslog). `/etc/rsyslog.d/` does not exist.
> Configuration must be applied from the VirtualBox GUI console (no Guest Additions = no SSH from host).

1. At the VM console, append the forwarding directive to `/etc/syslog.conf`:
   - `echo "*.* @192.168.10.14" | sudo tee -a /etc/syslog.conf`
2. Reload sysklogd (no init script — HUP the daemon):
   - `sudo kill -HUP $(pidof syslogd)`

## 5) Deploy Wazuh Config

1. Copy `wazuh-config/local_rules.xml` to `/var/ossec/etc/rules/local_rules.xml`.
2. Apply agent config from `wazuh-config/ossec-agent.conf` via centralized config.
3. Restart manager:
   - `sudo systemctl restart wazuh-manager`

## 6) Validate Scenarios

Execute scenario documents in `docs/attack-scenarios/` from Kali Attack and confirm alerts in Wazuh.

## 7) Evidence

Store screenshots and exported logs under `evidence/` grouped by scenario.

## 8) Changelog Update Protocol (required)

Immediately update `testbed/CHANGELOG.md` after each event below:

1. Wazuh server reachability validation (PASS/FAIL).
2. Each endpoint onboarding attempt (Kali Defense, MS-2).
3. Each custom rule validation attempt (`100001-100003`).
4. Each scenario execution result (`01-05`).

Each entry should include date/time, command or action, expected outcome, actual outcome, and blocker details if failed.
