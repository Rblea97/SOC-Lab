[![CI](https://github.com/Rblea97/SOC-Lab/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Rblea97/SOC-Lab/actions/workflows/ci.yml)

# SOC Lab

At 01:11 UTC, Wazuh fired rule 5763 — *brute force trying to get access to the system* — 36 times in 45 seconds. I triaged by correlating 4 parallel Hydra sessions across distinct PIDs, confirmed no credential was obtained by verifying that **rule 100002 did not fire**, and closed the incident as *No Compromise*. That workflow — alert, correlation, containment decision — is what this lab is built to practice and document.

![Pipeline demo](docs/demo.gif)

## What This Lab Demonstrates

- **Alert → triage → investigation → containment** — end-to-end analyst workflow, not just rule deployment
- **Detection engineering decisions** — why thresholds were tuned, how a custom decoder solved a real normalization gap, when a rule *correctly* does not fire
- **Validated evidence** — 5 attack scenarios with machine-readable JSON alert snapshots, hashes, timestamps, and detection latencies
- **Analyst tooling** — Python enrichment pipeline (risk scoring + MITRE context) and Sigma converter, tested and CI-gated

## Skills at a Glance

| Domain | Tools / Techniques |
|---|---|
| Threat detection | Wazuh SIEM, Sigma rules, ATT&CK Navigator |
| Detection engineering | Sigma→Wazuh XML conversion, alert enrichment, triage scoring, coverage metrics |
| Adversary simulation | Nmap, Hydra, Metasploit (vsftpd CVE-2011-2523), sudo abuse, web-shell FIM |
| Quality gates | ruff, pyright, pytest, pip-audit, nox, pre-commit, GitHub Actions CI |
| Incident response | IR reports (5 scenarios), ATT&CK layer, detection-coverage.md |

## Quick Demo

```bash
# Requires: Python 3.11+, uv (https://docs.astral.sh/uv/)
git clone git@github.com:Rblea97/SOC-Lab.git
cd SOC-Lab

# Run the full detection pipeline (Sigma → XML → enrichment → IR report → triage)
uv run python tools/pipeline_demo.py

# Run the quality gate suite (fmt, lint, type, test, audit) — matches CI exactly
uv run nox -s all
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Host (VirtualBox)                   │
│                                                      │
│  ┌──────────┐   ┌──────────────┐   ┌─────────────┐ │
│  │  Kali    │   │ Metasploitable│   │   Wazuh     │ │
│  │ Attacker │──▶│   2 Target   │──▶│  Manager    │ │
│  │10.0.2.15 │   │  10.0.2.5    │   │  10.0.2.10  │ │
│  └──────────┘   └──────────────┘   └──────┬──────┘ │
│                                            │        │
│                                    ┌───────▼──────┐ │
│                                    │   Ubuntu     │ │
│                                    │  Analyst     │ │
│                                    │  10.0.2.20   │ │
│                                    └──────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Detection Scenarios

| # | Scenario | MITRE | Rule | Ingestion | Latency | Status |
|---|---|---|---|---|---|---|
| 01 | [Nmap Recon](docs/attack-scenarios/01-nmap-recon.md) | T1046 | 100011 (custom) | Syslog / MS-2 | 72 s | VALIDATED |
| 02 | [SSH Brute Force](docs/attack-scenarios/02-ssh-brute-force.md) | T1110.001 | 5763 (built-in) | Agent / journald | 126 s | VALIDATED |
| 03 | [Metasploit vsftpd](docs/attack-scenarios/03-metasploit-vsftpd.md) | T1190 | 2501 (built-in) | Syslog / MS-2 | 192 s | VALIDATED |
| 04 | [Privilege Escalation](docs/attack-scenarios/04-priv-escalation.md) | T1548.003 | 5402 (built-in) | Agent / journald | **7 s** | VALIDATED |
| 05 | [Suspicious File](docs/attack-scenarios/05-suspicious-file.md) | T1505.003 | 100003 (custom) | Agent / syscheck | 71 s | VALIDATED |

Agent-based ingestion (scenario 04) achieved **7-second** detection. Syslog-forwarded events (scenarios 01, 03) measured 72–192 seconds — a 10–27× gap that reflects a real production tradeoff between legacy host coverage and detection speed.

For triage logic applied to each rule — what I check next, malicious vs. benign reasoning, and when to escalate — see [docs/triage-methodology.md](docs/triage-methodology.md).

## Detection Engineering Pipeline

```
tools/sigma/*.yml          (Sigma detection rules, one per scenario)
        │
        ▼
tools/sigma_convert.py     (converts Sigma YAML → Wazuh XML rule)
        │
        ▼
Wazuh alert (live) or tools/fixtures/sample_enriched.json (offline)
        │
        ▼
tools/enrich_alerts.py     (adds risk_label + mitre_description)
        │
        ▼
tools/triage.py            (scores triage priority P1–P4)
        │
        ▼
tools/report.py            (generates Markdown IR summary)
        │
        ▼
docs/ir-report-*.md        (incident response report)
```

Detection coverage is tracked via `tools/detect_metrics.py` against the ATT&CK Navigator layer in `docs/attack-coverage.json`.

All stages are testable offline: `uv run nox -s test` runs 85 tests without a live Wazuh instance.

## Gates

```bash
# Full suite (local == CI)
uv run nox -s all

# Pre-commit hooks
pre-commit run --all-files
```

Gates run in order: `fmt` (ruff) → `lint` (ruff) → `type` (pyright) → `test` (pytest) → `audit` (pip-audit).

## Evidence

Validated alert captures are stored per scenario in `evidence/`:

| Scenario | Evidence | IR Report |
|---|---|---|
| 01 Nmap Recon | [evidence/scenario-01-nmap/result.json](evidence/scenario-01-nmap/result.json) | [docs/ir-report-nmap-recon.md](docs/ir-report-nmap-recon.md) |
| 02 SSH Brute Force | [evidence/scenario-02-brute-force/result.json](evidence/scenario-02-brute-force/result.json) | [docs/ir-report-ssh-brute-force.md](docs/ir-report-ssh-brute-force.md) |
| 03 Metasploit vsftpd | [evidence/scenario-03-vsftpd/result.json](evidence/scenario-03-vsftpd/result.json) | [docs/ir-report-vsftpd-exploit.md](docs/ir-report-vsftpd-exploit.md) |
| 04 Priv Escalation | [evidence/scenario-04-priv-esc/result.json](evidence/scenario-04-priv-esc/result.json) | [docs/ir-report-priv-escalation.md](docs/ir-report-priv-escalation.md) |
| 05 Suspicious File | [evidence/scenario-05-suspicious-file/result.json](evidence/scenario-05-suspicious-file/result.json) | [docs/ir-report-suspicious-file.md](docs/ir-report-suspicious-file.md) |

Enriched fixture (offline): [tools/fixtures/sample_enriched.json](tools/fixtures/sample_enriched.json)
Detection coverage: [docs/detection-coverage.md](docs/detection-coverage.md)
