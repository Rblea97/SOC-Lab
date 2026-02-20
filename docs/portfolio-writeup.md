# SOC Home Lab — Portfolio Writeup

## Overview

This project builds a functional Security Operations Center environment from scratch using open-source tools
on consumer hardware. Starting from a three-VM cybersecurity testbed (Kali Attack, Kali Defense, Metasploitable-2),
I added a fourth VM running Wazuh 4.9.2 as the SIEM, then authored custom detection rules, ran five attack
scenarios against the target, and confirmed each one generated an alert. The result is a reproducible,
evidence-backed lab that demonstrates the core skills of a Tier 1/2 SOC analyst: log ingestion, detection
engineering, alert triage, and security automation.

---

## Architecture

```
192.168.10.11  Kali Attack     — attack source; runs nmap, Hydra, Metasploit
192.168.10.12  Kali Defense    — monitored endpoint; Wazuh agent (ID 001, Active)
192.168.10.13  MS-2 Target     — Metasploitable-2; syslog forwarded to Wazuh
192.168.10.14  Wazuh Server    — Ubuntu 22.04; Wazuh 4.9.2 all-in-one SIEM
```

All four VMs run on an isolated host-only network (`vboxnet0`). No VM has a route to the public internet
during attack simulation. The Wazuh dashboard and API are accessible only from the host at `192.168.10.14`.

Log collection uses two paths:
- **Agent-based** — Wazuh agent on Kali Defense ships syscheck events (file integrity monitoring) and
  auth logs directly to the manager over TCP 1514.
- **Syslog forwarding** — MS-2 ships all syslog events (`*.* @192.168.10.14`) over UDP 514. A custom
  decoder normalizes the stripped-header syslog format that MS-2 produces.

---

## Detection Scenarios

Five attack scenarios were executed end-to-end and validated in Wazuh:

| # | Scenario | Technique | MITRE ID | Detecting Rule |
|---|----------|-----------|----------|----------------|
| 1 | Nmap network scan | Network Service Discovery | T1046 | 100011 (custom) |
| 2 | SSH brute force | Brute Force — Password Guessing | T1110.001 | 5763 (built-in) |
| 3 | Metasploit vsftpd 2.3.4 exploit | Exploit Public-Facing Application | T1190 | 2501 (built-in) |
| 4 | Privilege escalation (sudo abuse) | Abuse Elevation Control Mechanism | T1548 | 5402 (built-in) |
| 5 | Suspicious file dropped in /tmp | Web Shell / Post-Exploitation Artifact | T1505.003 | 100003 (custom) |

Evidence for each scenario is stored under `evidence/scenario-0N-*/result.json`.

---

## Custom Detection Engineering

Five custom rules and one custom decoder were written to fill gaps in Wazuh's default ruleset:

| Rule ID | Level | What It Detects |
|---------|-------|-----------------|
| 100001 | 8 | Network scan: 12+ connection attempts from the same source IP within 60 s (T1046) |
| 100002 | 12 | Brute-force success: SSH login following multiple failures from the same IP (T1110.001) |
| 100003 | 10 | Suspicious file written to `/tmp` — matches `.php`, `.py`, `.sh`, or known shell keywords (T1505.003) |
| 100010 | 5 | SSH invalid-user attempt in MS-2's stripped syslog format (T1110.001) |
| 100011 | 8 | Aggregated: 12+ rule-100010 events from same IP in 60 s — confirms scan activity (T1046) |

The `sshd-stripped` custom decoder normalizes MS-2's non-standard syslog prefix so Wazuh can extract
the source IP and feed it into the frequency-based rules above.

All rules live in `wazuh-config/local_rules.xml`; the decoder is in `wazuh-config/local_decoder.xml`.

---

## Detection Engineering Pipeline

Five Sigma YAML rules feed a fully offline pipeline that produces enriched JSON and a Markdown IR summary:

```
tools/sigma/*.yml  →  sigma_convert.py  →  Wazuh XML
                                              ↓
                               (deployed to wazuh-config/local_rules.xml)
                                              ↓
                          Wazuh alert  →  enrich_alerts.py  →  enriched JSON
                                              ↓
                                        report.py  →  Markdown IR summary
```

All stages run with no live VMs via `tools/fixtures/sample_enriched.json`. IR reports for each
scenario live in `docs/ir-report-*.md` (IR-2026-001 through IR-2026-005). ATT&CK coverage is
documented in `docs/attack-coverage.json` (Navigator 4.x layer, ATT&CK v15).

---

## Python Tooling

Four Python utilities in `tools/` support analyst workflows without requiring the VMs to be running:

**`sigma_convert.py`** — Converts a Sigma detection rule (YAML) into a Wazuh-compatible XML rule
fragment. Lets analysts write detections in the portable Sigma format and deploy them without
hand-crafting Wazuh XML.

**`enrich_alerts.py`** — Takes a Wazuh JSON alert, maps the rule ID to its MITRE ATT&CK technique,
computes a risk tier (`critical` / `high` / `medium` / `low`), and returns a structured triage report.
Supports `--output <file>` to write enriched JSON for downstream processing.

**`demo_enrich.py`** — Offline demo: loads `tools/fixtures/sample_enriched.json` and prints a
human-readable triage report with no env vars or network calls.

**`report.py`** — Reads enriched JSON and writes a structured Markdown IR summary with Summary,
Alert Table, MITRE Techniques, and Recommended Triage Actions sections.

All four utilities are fully typed, lint-clean, and covered by 50 pytest tests. Run the enrichment
pipeline against five sample alerts with no VMs:

```bash
uv run python tools/demo_enrich.py
```

---

## Code Quality

The `tools/` module is held to a consistent quality bar enforced by `uv run nox -s all`:

- **Ruff** — format check + lint (PEP 8, import order, common anti-patterns)
- **Pyright** — strict static type checking
- **PyTest** — 50 unit + integration tests; all passing

CI runs the same gate automatically on every push and pull request via GitHub Actions
(`.github/workflows/ci.yml`): `uv run nox -s all`. The pipeline also runs ShellCheck on all
shell scripts and Gitleaks to prevent accidental credential commits.

---

## Skills Demonstrated

- **SIEM deployment** — planned and provisioned a Wazuh all-in-one instance from scratch; configured
  multi-source log ingestion (agent + syslog forwarding)
- **Detection engineering** — authored 5 custom rules and 1 custom decoder; tuned frequency thresholds
  to minimize false positives
- **ATT&CK mapping** — aligned every detection to a MITRE technique; documented in rules and evidence
- **Alert triage** — validated 5/5 scenarios end-to-end; captured raw event, rule match, and risk context
- **Security automation** — built 4-tool detection engineering pipeline (Sigma→XML→enrich→report);
  fully offline and testable with no VMs
- **Incident reporting** — produced 5 structured IR reports (IR-2026-001 through IR-2026-005)
  covering every scenario; each includes timeline, MITRE mapping, evidence table, and compliance refs
- **ATT&CK coverage** — documented all 5 detected techniques in a Navigator 4.x layer
  (`docs/attack-coverage.json`, ATT&CK v15)
- **Code quality** — Ruff, Pyright, PyTest (50 tests), GitHub Actions CI; zero lint/type errors
- **Documentation** — runbook, credentials template, per-scenario evidence matrix, operator guide

---

## Future Work

- **Suricata NIDS** — add network-layer visibility; correlate IDS alerts with SIEM events
- **Threat intelligence** — integrate MISP feeds; enrich alerts with IOC matches
- **IR workflow** — build a TheHive case template for the five existing scenarios
- **MS-2 automation** — full guestcontrol scripting once VirtualBox Guest Additions are available
- **Extended ATT&CK coverage** — lateral movement (T1021), data exfiltration (T1048), persistence (T1053)
