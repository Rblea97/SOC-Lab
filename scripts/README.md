# SOC Lab Automation Scripts

These scripts automate post-install steps for the Wazuh SIEM lab.

## Credentials

Store Wazuh dashboard/API and SSH passwords in a **local, gitignored** file. See **`testbed/CREDENTIALS.md`** and copy `testbed/credentials.env.example` to `testbed/credentials.env`, then fill in. Scripts use env vars such as `WAZUH_SSH_PASS` and `WAZUH_API_PASSWORD`; you can `source testbed/credentials.env` before running scripts. Run them from the **host** (your Linux machine) with the project root as current directory or set `CSCY_ROOT` to the repo path.

## When you're needed (manual steps)

1. **Host-only network (one-time)**
   The host must be on `192.168.10.1/24` to reach the Wazuh VM. Run the probe script to
   confirm — it will PASS/FAIL each check and print the fix command if needed:
   ```bash
   bash scripts/00-require-host-network.sh
   ```
   If vboxnet0 needs reconfiguring (first-time setup):
   ```bash
   sudo mkdir -p /etc/vbox && echo "* 192.168.10.0/24" | sudo tee /etc/vbox/networks.conf
   sudo VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.10.1 --netmask 255.255.255.0
   ```

2. **MS-2 syslog**
   MS-2 runs Ubuntu 8.04 with **sysklogd** (not rsyslog). On the MS-2 VM console:
   ```bash
   echo "*.* @192.168.10.14" | sudo tee -a /etc/syslog.conf
   sudo kill -HUP $(pidof syslogd)
   ```
   Not automatable (no VirtualBox Guest Additions on MS-2).

3. **SSH to Wazuh VM (for rules deploy)**  
   Either:
   - Copy your SSH key: `ssh-copy-id analyst@192.168.10.14` (use your analyst password), or
   - Set `WAZUH_SSH_PASS` when running the deploy script (requires `sshpass`).

## Order of operations

| Step | Script | Prereqs | Status |
|------|--------|---------|--------|
| pre | `00-check-deps.sh` | none | run first on a new host |
| 0 | `00-require-host-network.sh` | vboxnet0 on 192.168.10.1/24 | DONE |
| 1 | `01-onboard-kali-defense-agent.sh` | Kali Defense VM running | DONE |
| 2 | `02-deploy-wazuh-rules.sh` | Step 0 passes, SSH to Wazuh | DONE |
| 3 | `04-update-changelog-runbook.sh` | Optional; run after 1–2 with results | — |
| 4 | `05-verify-wazuh-syslog-listener.sh` | SSH to Wazuh, `ossec.conf` writable | DONE |
| 5 | `06-verify-telemetry-sources.sh` | Steps 1+4 done, `logall yes` in ossec.conf | DONE |
| 6 | `07-run-scenario-05.sh` | Kali Defense running, wazuh-agent active | DONE |
| 7 | `08-run-scenario-02.sh` | Kali Attack VM running, Kali Defense SSH up | DONE |
| 8 | `09-run-scenario-01.sh` | MS-2 running, syslog forwarding configured | DONE |
| 9 | `10-run-scenario-03.sh` | MS-2 running, syslog forwarding configured | DONE |
| 10 | `11-run-scenario-04.sh` | Kali Defense running, wazuh-agent active | DONE |

## Quick run (MVP complete — all 5 scenarios validated)

```bash
source testbed/credentials.env
# Re-run any individual scenario:
bash scripts/09-run-scenario-01.sh   # SSH recon → MS-2, rule 100011
bash scripts/08-run-scenario-02.sh   # SSH brute force → Kali Defense, rule 5763
bash scripts/10-run-scenario-03.sh   # vsftpd exploit → MS-2, rule 2501
bash scripts/11-run-scenario-04.sh   # sudo priv-esc → Kali Defense, rule 5402
bash scripts/07-run-scenario-05.sh   # suspicious file → Kali Defense, rule 100003
```

## Environment variables

- **CSCY_ROOT** – Repo root (default: directory containing `scripts/`).
- **WAZUH_HOST** – Wazuh server IP (default: `192.168.10.14`).
- **WAZUH_API_USER** / **WAZUH_API_PASSWORD** – Dashboard/API credentials (optional; for scenario script API-based alert check).
- **WAZUH_SSH_USER** – SSH user on Wazuh VM (default: `analyst`).
- **WAZUH_SSH_PASS** – SSH password for Wazuh VM (optional; if set, scripts use `sshpass` for deploy-rules and scenario alert check).
- **KALI_DEFENSE_VM** – VM name (default: `Kali Defense VM`).
- **KALI_ATTACK_VM** – VM name (default: `Kali Attack VM`).
- **KALI_USER** / **KALI_PASS** – Kali guest login (default: `kali` / `kali`).

For **02-deploy-wazuh-rules.sh**: either set up SSH keys (`ssh-copy-id analyst@192.168.10.14`) or set **WAZUH_SSH_PASS** (your analyst password).


## VM names

Scripts use VirtualBox VM names `Kali Attack VM` (scripts 08–10) and
`Kali Defense VM` (scripts 01, 07, 08, 11) to run commands via guestcontrol.
If your VMs have different names, set these env vars **before** running scripts:

```bash
export KALI_ATTACK_VM='Your Kali Attack VM Name'
export KALI_DEFENSE_VM='Your Kali Defense VM Name'
```

`00-check-deps.sh` validates that both names appear in `VBoxManage list vms`
and prints the override hint if they don't.
