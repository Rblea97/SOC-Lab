# SOC Home Lab (MVP)

[![CI](https://github.com/Rblea97/SOC-Lab/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Rblea97/SOC-Lab/actions/workflows/ci.yml)

This repository documents and automates an MVP SOC homelab based on the CSCY 4743 three-VM testbed plus a dedicated Wazuh SIEM VM.

## Topology

- `192.168.10.11` - Kali Attack VM
- `192.168.10.12` - Kali Defense VM
- `192.168.10.13` - MS-2 Target VM
- `192.168.10.14` - Wazuh Server VM

## Current Status — All 5/5 Scenarios Validated (2026-02-14)

- Baseline three-VM testbed operational (Kali Attack `.11`, Kali Defense `.12`, MS-2 `.13`).
- Wazuh 4.9.2 all-in-one at `192.168.10.14`; dashboard and API confirmed reachable.
- Custom detection rules `100001`–`100003`, `100010`, `100011` deployed; custom decoder
  `sshd-stripped` active.
- Kali Defense `wazuh-agent` 4.9.2-1 registered (`ID: 001, Active`).
- MS-2 syslog forwarding configured (`*.* @192.168.10.14` in `/etc/syslog.conf`).
- **All 5 scenarios VALIDATED** — see [`evidence/README.md`](evidence/README.md) for per-scenario evidence.
- Sample deliverable: [`docs/ir-report-ssh-brute-force.md`](docs/ir-report-ssh-brute-force.md) — IR report for scenario 02 (SSH brute force), SANS format.
- Automation scripts in [`scripts/`](scripts/) (00=dep-check, 00=preflight, 01=onboard agent,
  02=deploy rules, 05–06=syslog/telemetry checks, 07–11=scenarios).
- Credentials: store in a local gitignored file — see [`testbed/CREDENTIALS.md`](testbed/CREDENTIALS.md) and
  [`testbed/credentials.env.example`](testbed/credentials.env.example).

## Demo in 5 minutes

No VMs needed — replay validated scenario alerts through the detection pipeline:

```bash
make bootstrap   # one-time: create venv + install deps
make demo        # replay 5 alerts through enrichment
make verify      # run full quality gate (lint + types + tests)
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

See [`docs/portfolio-writeup.md`](docs/portfolio-writeup.md) for the full project narrative.

## Developer workflow

- Local verification gate: `make verify` (runs Ruff format check + lint + MyPy + PyTest for `tools/`).
- Optional: enable `pre-commit` to run Ruff, ShellCheck, and Gitleaks locally.
- Claude Code guide: see [`CLAUDE.md`](CLAUDE.md) and [`docs/agent/claude-code.md`](docs/agent/claude-code.md).

## Repo Hygiene

No build artifacts are committed. If you run the `tools/` scripts locally,
regenerate caches as needed:

```bash
cd tools && pip install -e .   # regenerates egg-info
pytest                          # regenerates .pytest_cache
```

## Safety Notice

This lab contains intentionally vulnerable systems. Keep all VMs on an isolated host-only network and never expose MS-2 to bridged/public networks.
