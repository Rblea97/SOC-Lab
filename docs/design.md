# Design Document — SOC Homelab MVP

## 1. Problem / Context

University cybersecurity courses provide a three-VM attack/defense testbed (Kali Attack,
Kali Defense, Metasploitable-2 Target) but no centralized SIEM for detection engineering
practice. Students learn to run attacks but have no structured way to detect them, tune
rules, or capture evidence aligned to the MITRE ATT&CK framework.

This project extends the baseline three-VM range with a dedicated Wazuh all-in-one SIEM
VM, custom detection rules, and automated scenario scripts — producing a reproducible MVP
SOC for five ATT&CK-mapped attack scenarios.

---

## 2. Goals / Non-goals

### In scope (MVP)

- Deploy Wazuh 4.9.2 SIEM on an isolated host-only network alongside the existing testbed.
- Onboard two telemetry sources: Wazuh agent (Kali Defense) and syslog forwarding (MS-2).
- Author and validate custom detection rules covering five ATT&CK techniques.
- Execute five scripted attack scenarios and capture JSON alert evidence for each.
- Provide automation scripts (`scripts/`) covering agent onboarding, rule deployment, and
  scenario execution.
- Provide Python tooling (`tools/`) for alert enrichment and Sigma rule conversion.

### Out of scope

- Production hardening (TLS mutual auth, encrypted agent comms, access control).
- High availability or distributed Wazuh architecture.
- Network-layer NIDS (e.g., Suricata integration).
- Automated MS-2 guest configuration (no VirtualBox Guest Additions on MS-2).
- Coverage beyond the five MVP scenarios.

---

## 3. Architecture Overview

```
Host Machine (VirtualBox, vboxnet0: 192.168.10.1/24)
│
├── Kali Attack VM       192.168.10.11  — offensive tools (Nmap, Metasploit, Hydra)
├── Kali Defense VM      192.168.10.12  — Wazuh agent; telemetry source #1
├── MS-2 Target VM       192.168.10.13  — Metasploitable-2; sysklogd forwarding; telemetry source #2
└── Wazuh Server VM      192.168.10.14  — Wazuh 4.9.2 all-in-one (manager + indexer + dashboard)
```

All VMs share a VirtualBox host-only network (`vboxnet0`). Kali VMs have an additional
NAT adapter for package installation; MS-2 has only the host-only adapter (isolated).

---

## 4. Data Flow

```
Attack VM (.11)
    │  SSH login attempts / Nmap scans / Metasploit exploits / sudo commands
    ▼
Target VMs (.12, .13)
    │
    ├── Kali Defense (.12): Wazuh agent → encrypted agent channel → Wazuh Manager (.14)
    │
    └── MS-2 (.13): sysklogd UDP syslog → port 514 → Wazuh syslog listener (.14)
            │
            │  Note: MS-2 sysklogd sends stripped format (no RFC 3164 timestamp/hostname).
            │  Custom decoder `sshd-stripped` handles this before standard rules apply.
            ▼
Wazuh Manager (.14)
    │  Decodes → correlates → fires rules → writes alerts.json
    ▼
Evidence capture (host): grep alert JSON → save to evidence/scenario-*/result.json
```

---

## 5. Threat Model — ATT&CK Scenarios

| # | Scenario | ATT&CK Technique | Source VM | Target | Rule Fired |
|---|----------|-----------------|-----------|--------|-----------|
| 01 | Nmap / SSH recon | T1046 Network Service Discovery | `.11` | MS-2 `.13` | 100011 (custom composite) |
| 02 | SSH brute force | T1110.001 Password Guessing | `.11` | Kali Defense `.12` | 5763 (built-in) |
| 03 | vsftpd 2.3.4 backdoor exploit | T1190 Exploit Public-Facing App | `.11` | MS-2 `.13` | 2501 (built-in) |
| 04 | Privilege escalation via sudo | T1548.003 Sudo/Sudo Caching | `.11`→`.12` | Kali Defense `.12` | 5402 (built-in) |
| 05 | Suspicious file creation in /tmp | T1505.003 Web Shell | `.11`→`.12` | Kali Defense `.12` | 100003 (custom) |

Custom rules `100001`–`100003` and `100010`/`100011` are in `wazuh-config/local_rules.xml`.
Custom decoder `sshd-stripped` is in `wazuh-config/local_decoder.xml`.

---

## 6. Repro Steps and Environment Assumptions

### Prerequisites

- VirtualBox 7.x installed on the host with hardware virtualization enabled.
- Host-only network `vboxnet0` at `192.168.10.1/24` with DHCP pool `192.168.10.11`–`192.168.10.254`.
- Four VMs imported/created and named exactly: `Kali Attack VM`, `Kali Defense VM`,
  `MS-2 Target VM`, `Wazuh Server VM`.
- VM storage location configured in VirtualBox (default: `~/VirtualBox VMs/`).
- Credentials stored in `testbed/credentials.env` (gitignored); copy from
  `testbed/credentials.env.example` and fill in. See `testbed/CREDENTIALS.md`.

### Script execution order

Follow `scripts/README.md` for the canonical order. Summary:

```bash
bash scripts/00-require-host-network.sh   # preflight: verify network + Wazuh reachability
bash scripts/02-deploy-wazuh-rules.sh     # deploy custom rules + decoder to Wazuh VM
bash scripts/01-onboard-kali-defense-agent.sh     # install + register wazuh-agent on Kali Defense
bash scripts/05-verify-wazuh-syslog-listener.sh  # configure Wazuh UDP-514 syslog listener
# MS-2 syslog forwarding requires manual console step (no Guest Additions):
#   echo "*.* @192.168.10.14" | sudo tee -a /etc/syslog.conf
#   sudo kill -HUP $(pidof syslogd)
bash scripts/06-verify-telemetry-sources.sh      # confirm both sources delivering events

# Run scenarios (start MS-2 in GUI mode first):
bash scripts/09-run-scenario-01.sh   # Nmap/SSH recon → MS-2
bash scripts/08-run-scenario-02.sh   # SSH brute force → Kali Defense
bash scripts/10-run-scenario-03.sh   # vsftpd exploit → MS-2
bash scripts/11-run-scenario-04.sh   # priv escalation → Kali Defense
bash scripts/07-run-scenario-05.sh   # suspicious file → Kali Defense
```

Evidence JSON files are saved to `evidence/scenario-*/result.json`.
See `evidence/README.md` for per-scenario pass/fail details.
