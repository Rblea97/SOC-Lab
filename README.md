[![CI](https://github.com/Rblea97/SOC-Lab/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Rblea97/SOC-Lab/actions/workflows/ci.yml)

# SOC Lab

> **End-to-end detection engineering lab** — 5 adversary attack chains, Wazuh SIEM, and a fully tested Python pipeline that converts Sigma rules to Wazuh XML, enriches alerts, scores triage priority, and generates IR reports. Everything runs offline via fixtures; 85 tests pass in CI with a single command: `uv run nox -s all`.

![Pipeline demo](docs/demo.gif)

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

## 1. Overview

This lab provisions a 4-VM virtual network (Kali attacker, Metasploitable 2 target, Wazuh manager, and Ubuntu analyst) to replicate realistic SOC triage workflows. Five attack scenarios are scripted end-to-end: from adversary command through Wazuh detection, alert enrichment, and IR report generation. All tooling runs offline without live credentials, making every gate reproducible in CI.

## 2. Architecture

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

## 3. Detection Scenarios

| # | Scenario | Attack | MITRE Technique | Wazuh Rule | Status |
|---|---|---|---|---|---|
| 01 | [Nmap Recon](docs/attack-scenarios/01-nmap-recon.md) | Network service scan | T1046 | 100011 | VALIDATED |
| 02 | [SSH Brute Force](docs/attack-scenarios/02-ssh-brute-force.md) | Password guessing | T1110.001 | 5763 | VALIDATED |
| 03 | [Metasploit vsftpd](docs/attack-scenarios/03-metasploit-vsftpd.md) | Exploit public-facing app | T1190 | 2501 | VALIDATED |
| 04 | [Privilege Escalation](docs/attack-scenarios/04-priv-escalation.md) | Sudo abuse | T1548.003 | 5402 | VALIDATED |
| 05 | [Suspicious File](docs/attack-scenarios/05-suspicious-file.md) | Web shell drop | T1505.003 | 100003 | VALIDATED |

## 4. Detection Engineering Pipeline

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

## 5. Gates

```bash
# Full suite (local == CI)
uv run nox -s all

# Pre-commit hooks
pre-commit run --all-files
```

Gates run in order: `fmt` (ruff) → `lint` (ruff) → `type` (pyright) → `test` (pytest) → `audit` (pip-audit).

## 6. Evidence

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
