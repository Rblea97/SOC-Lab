# SOC Home Lab

[![CI](https://github.com/Rblea97/SOC-Lab/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Rblea97/SOC-Lab/actions/workflows/ci.yml)

At 01:11 UTC, Wazuh fired rule 5763 — *brute force trying to get access to the system* — 36 times in 45 seconds, all originating from 192.168.10.11. I triaged the alert by examining the correlated events: 4 parallel Hydra sessions targeting user `kali` over SSH, each appearing in `journald` within milliseconds of each other, consistent with automated tooling. I confirmed no compromise: **rule 100002 did not fire** — the custom correlation rule that detects a successful login following a series of failures never triggered, meaning no credential was obtained. I ruled out a false positive by measuring the inter-event cadence (sub-second gaps between failures across 4 PIDs) against what a human typo would produce. I captured the full event sequence, documented the timeline from first failure (01:11:42) to attack termination (~01:12:27), and issued containment recommendations: block the source IP, enforce key-based auth, and deploy fail2ban. The incident was closed with classification *Credential Access — No Compromise*. Full report: [`docs/ir-report-ssh-brute-force.md`](docs/ir-report-ssh-brute-force.md) (IR-2026-002).

---

## What This Lab Demonstrates

- **Alert → triage → investigation → containment** — end-to-end analyst workflow, not just rule deployment
- **Detection engineering decisions** — why thresholds were tuned, how a custom decoder solved a real normalization gap, when a rule *correctly* does not fire
- **Validated evidence** — 5 attack scenarios with machine-readable JSON alert snapshots, hashes, timestamps, and detection latencies
- **Analyst tooling** — Python enrichment pipeline (risk scoring + MITRE context) and Sigma converter, tested and CI-gated

---

## Detection Engineering

### The MS-2 Syslog Normalization Problem

MS-2's `sysklogd` strips RFC 3164 headers before forwarding — no timestamp, no hostname prefix — just `sshd[pid]: message`. Wazuh's standard `sshd` decoder expects the full header and silently fails to extract the source IP from these events. Without a source IP, frequency-based rules cannot correlate events by attacker. I recognized this gap, **authored a custom `sshd-stripped` decoder** ([`wazuh-config/local_decoder.xml`](wazuh-config/local_decoder.xml)) that matches on the raw `sshd[...]` prefix and extracts `srcip` and `srcuser`, then chained rules 100010 and 100011 on top of it. This recovered full detection coverage for roughly 20% of the telemetry that would otherwise have been undecodeable.

### Threshold Tuning

Two frequency thresholds were tuned for distinct attack patterns:

| Rule | Threshold | Window | Rationale |
|------|-----------|--------|-----------|
| 100001 / 100011 | 12 events | 60 s | Distinguishes automated scan cadence from human SSH probing; 12/min is above any plausible human rate |
| 100002 | 8 failures | 120 s | Flags brute-force *success* — only fires if login succeeds after repeated failures from the same IP, minimizing false positives to near-zero |

### Correlation Rule 100002 — Success After Failure

Rule 100002 (level 12) correlates `if_matched_sid 5716` (successful auth) following 8+ failures within 120 seconds from the same source IP. In the SSH brute force scenario, this rule **correctly did not fire**: Hydra obtained no valid credentials. This is not a detection gap — it is the rule behaving as designed. Recognizing when a rule's silence is informative is as operationally significant as recognizing when it fires.

### MITRE ATT&CK Mapping

Every custom rule maps to a named technique ([`wazuh-config/local_rules.xml`](wazuh-config/local_rules.xml)):

| Rule ID | Level | Technique | MITRE ID |
|---------|-------|-----------|----------|
| 100001 | 8 | Network Service Discovery | T1046 |
| 100002 | 12 | Brute Force: Password Guessing | T1110.001 |
| 100003 | 10 | Web Shell / Post-Exploitation Artifact | T1505.003 |
| 100010 | 5 | SSH Invalid User (MS-2 stripped format) | T1110.001 |
| 100011 | 8 | Aggregated scan: 12+ invalid user events / 60 s | T1046 |

---

## Attack Scenarios & Validation

Five attack techniques were executed end-to-end, alerts were captured, and detection latency was measured from attack start to first alert.

| # | Scenario | MITRE | Rule Fired | Ingestion Path | Latency | Outcome |
|---|----------|-------|-----------|----------------|---------|---------|
| 01 | Nmap network scan | T1046 | 100011 (custom) | Syslog / MS-2 | **72 s** | PASS |
| 02 | SSH brute force (Hydra) | T1110.001 | 5763 (built-in) | Agent / journald | **126 s** | PASS |
| 03 | Metasploit vsftpd 2.3.4 exploit | T1190 | 2501 (built-in) | Syslog / MS-2 | **192 s** | PASS |
| 04 | Privilege escalation (sudo) | T1548 | 5402 (built-in) | Agent / journald | **7 s** | PASS |
| 05 | Suspicious file dropped in /tmp | T1505.003 | 100003 (custom) | Agent / syscheck | **71 s** | PASS |

Evidence for each scenario: [`evidence/README.md`](evidence/README.md) — per-scenario `result.json` files with alert JSON, rule IDs, and SHA-256 hashes.

**Detection latency gap:** Agent-based ingestion (scenario 04) achieved **7-second** detection. Syslog-forwarded events (scenarios 01, 03) measured **72–192 seconds** — a 10–25× gap explained by UDP 514 batch delivery and sysklogd's forwarding interval. This trade-off is documented; for production environments requiring sub-minute detection on legacy hosts, an agent or rsyslog TCP forwarding would be warranted.

---

## Investigation & Response (IR-2026-002)

**Scenario:** SSH brute force against Kali Defense (192.168.10.12)
**Full report:** [`docs/ir-report-ssh-brute-force.md`](docs/ir-report-ssh-brute-force.md)

**Investigation flow:**

1. **Alert triaged** — Rule 5763 fired; examined `firedtimes: 36` and `frequency: 8` fields to assess severity
2. **Timeline reconstructed** — First failure at 01:11:42; 8 failures across 4 PIDs by 01:11:49; brute-force threshold crossed at 01:11:52; attack terminated at ~01:12:27
3. **Compromise ruled out** — Rule 100002 never fired; no `sshd: Accepted password` events in the correlated window; no post-exploitation artifacts detected by syscheck
4. **Attack tool attributed** — 4 parallel PIDs (4167, 4175, 4183, 4190) with sub-second inter-event gaps confirmed Hydra `-t 4` thread signature
5. **Containment recommendations issued** — block source IP via `ufw`, disable password auth in `sshd_config`, deploy fail2ban (5 failures / 10 min), audit `~/.ssh/authorized_keys` and recent cron modifications as precaution

**Compliance cross-reference:** NIST 800-53 (AC-7, SI-4, AU-14), PCI-DSS (10.2.4, 10.2.5, 11.4) — documented in full report.

---

## Analyst Tooling

Two Python utilities support analyst workflows without requiring live VMs ([`tools/`](tools/)):

**Alert enrichment pipeline** (`enrich_alerts.py`) — Takes a raw Wazuh JSON alert, maps the rule ID to its MITRE ATT&CK technique and tactic, and computes a risk tier (`critical` / `high` / `medium` / `low`). Designed as a building block for SOAR playbooks or triage notebooks.

**Sigma rule converter** (`sigma_convert.py`) — Converts a Sigma detection rule (YAML) into a Wazuh-compatible XML rule fragment. Detections can be authored in the portable Sigma format and converted for deployment — cross-platform portability without hand-crafting Wazuh XML.

Both utilities are fully typed (MyPy strict), lint-clean (Ruff), and covered by **26 pytest tests**. CI runs the same gate on every push via GitHub Actions, with ShellCheck on shell scripts and Gitleaks for secret scanning.

**Run the enrichment pipeline against 5 sample alerts — no VMs required:**

```bash
make bootstrap   # one-time: create venv + install deps
make demo        # replay 5 alerts through enrichment pipeline
make verify      # full quality gate: lint + types + tests
```

`make demo` output (deterministic):
```
SOC Triage Report
=================
1. Rule 100011 level=8 risk=high
   MITRE: T1046 (Network Service Discovery)
   ...
5. Rule 100003 level=7 risk=medium
   MITRE: T1505.003 (Web Shell)
   ...
```

---

## Competencies Demonstrated

| Competency | Evidence |
|-----------|---------|
| **Detection lifecycle** | Authored 5 custom rules and 1 custom decoder; tuned thresholds against real attack traffic; validated against live scenarios |
| **Analyst triage** | Triaged 5 distinct alert types; enrichment pipeline adds risk scoring and MITRE context to raw rule IDs |
| **Investigation methodology** | Reconstructed SSH brute force timeline; correlated 36 events across 4 parallel sessions; confirmed no compromise via negative rule evidence |
| **Containment & remediation** | Issued 5 specific containment actions with commands in IR-2026-002; mapped recommendations to compliance controls |
| **False positive reasoning** | Tuned frequency thresholds to separate automated scan cadence from human behavior; documented why 100002 not firing is meaningful |
| **Detection telemetry** | Measured agent vs. syslog detection latency (7 s vs. 192 s); documented the architectural cause and operational implication |
| **Cross-platform detection** | Sigma converter translates portable rule format to Wazuh XML; detection logic is not vendor-locked |
| **Reproducibility** | All scenarios produce deterministic `result.json`; `make demo` replays enrichment without live VMs; 26 tests enforce correctness |

---

## Lab Architecture

```
192.168.10.11  Kali Attack     — attack source (nmap, Hydra, Metasploit)
192.168.10.12  Kali Defense    — monitored endpoint; Wazuh agent ID 001 (Active)
192.168.10.13  MS-2 Target     — Metasploitable-2; syslog → UDP 514 → Wazuh
192.168.10.14  Wazuh Server    — Ubuntu 22.04; Wazuh 4.9.2 all-in-one SIEM
```

All VMs run on an isolated host-only network (`vboxnet0`). No VM has a route to the public internet during attack simulation.

**Log ingestion paths:**
- **Agent-based** (Kali Defense) — Wazuh agent ships journald auth logs and syscheck file integrity events over TCP 1514. Detection latency: 7–126 s.
- **Syslog forwarding** (MS-2) — `*.* @192.168.10.14` over UDP 514. The `sshd-stripped` custom decoder normalizes the stripped-header format. Detection latency: 71–192 s.

---

## Quick Start / Reproducibility

No VMs required to validate the detection pipeline:

```bash
make bootstrap   # create venv + install tools/
make demo        # replay 5 validated alerts through enrichment
make verify      # lint (Ruff) + types (MyPy) + tests (pytest)
```

For scenario runbooks: [`docs/attack-scenarios/`](docs/attack-scenarios/)
For per-scenario alert evidence: [`evidence/`](evidence/)
For full project narrative: [`docs/portfolio-writeup.md`](docs/portfolio-writeup.md)

---

## Not Yet Demonstrated

- **Network-layer detection** — no Suricata or IDS; network traffic is not inspected, only host logs
- **Threat intelligence** — no MISP or IOC feed integration; alerts are not enriched with known-bad indicators
- **Automated containment** — containment recommendations are documented but not automated; no SOAR playbooks execute on alert
- **Lateral movement / exfiltration scenarios** — ATT&CK coverage is recon → initial access → privilege escalation → persistence; T1021 and T1048 are not validated

---

*Safety: All VMs run on an isolated host-only network. Never bridge MS-2 to a public or corporate network.*
