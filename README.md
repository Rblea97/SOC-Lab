[![CI](https://github.com/Rblea97/SOC-Lab/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Rblea97/SOC-Lab/actions/workflows/ci.yml)

# SOC Lab

A hands-on security operations lab that simulates five adversary attack chains against a Metasploitable 2 target, detected by Wazuh, and processed through an end-to-end detection engineering pipeline. Each scenario produces a Sigma rule, a Wazuh XML alert rule, enriched JSON output, and a Markdown IR report — all verifiable offline via fixtures.

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
tools/report.py            (generates Markdown IR summary)
        │
        ▼
docs/ir-report-*.md        (incident response report)
```

All stages are testable offline: `uv run nox -s test` runs 50 tests without a live Wazuh instance.

## 5. Quick Start

```bash
# Requires: Python 3.11+, uv (https://docs.astral.sh/uv/)
git clone git@github.com:Rblea97/SOC-Lab.git
cd SOC-Lab

# Run the enrichment demo (offline, zero env vars needed)
uv run python tools/demo_enrich.py
```

## 6. Gates

```bash
# Full suite (local == CI)
uv run nox -s all

# Pre-commit hooks
pre-commit run --all-files
```

Gates run in order: `fmt` (ruff) → `lint` (ruff) → `type` (pyright) → `test` (pytest) → `audit` (pip-audit).

## 7. Evidence

Validated alert captures are stored per scenario in `evidence/`:

| Scenario | Evidence | IR Report |
|---|---|---|
| 01 Nmap Recon | [evidence/scenario-01-nmap/result.json](evidence/scenario-01-nmap/result.json) | — |
| 02 SSH Brute Force | [evidence/scenario-02-brute-force/result.json](evidence/scenario-02-brute-force/result.json) | [docs/ir-report-ssh-brute-force.md](docs/ir-report-ssh-brute-force.md) |
| 03 Metasploit vsftpd | [evidence/scenario-03-vsftpd/result.json](evidence/scenario-03-vsftpd/result.json) | — |
| 04 Priv Escalation | [evidence/scenario-04-priv-esc/result.json](evidence/scenario-04-priv-esc/result.json) | — |
| 05 Suspicious File | [evidence/scenario-05-suspicious-file/result.json](evidence/scenario-05-suspicious-file/result.json) | — |

Enriched fixture (offline): [tools/fixtures/sample_enriched.json](tools/fixtures/sample_enriched.json)
