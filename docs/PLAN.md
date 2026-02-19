# PLAN — SOC_LAB MPS Alignment + Detection Engineering Pipeline

## Tree of Thoughts (exactly 3 branches)

### Branch A — Root-level MPS Automation Wrapper (SELECTED)
**Pattern:** Keep repo layout intact; make root automation authoritative while scoping Python gates to `tools/` initially.

- Add root `noxfile.py` that runs:
  - ruff format/lint on `tools/`
  - pyright typecheck for `tools/`
  - pytest for `tools/tests`
  - pip-audit using exported `requirements-audit.txt`
- CI updated to run `uv run nox -s all` instead of `make verify` and `.venv` activation.
- Pre-commit updated to include pyright (or invoke nox session) and artifact guards.
- `.claude.md` becomes canonical session entrypoint; `.claude/commands/*` stays as optional deep commands.

**Complexity:** Medium
**Scalability:** High
**Constraint adherence:** Strong (parity + deterministic audit + pyright)

### Branch B — Full Project Consolidation (PRUNED)
**Pattern:** Move `tools/` into a canonical Python package layout at root, merge config, rewrite docs/scripts accordingly.

**Complexity:** High
**Scalability:** High
**Constraint adherence:** Strong
**Why pruned:** unnecessary churn to reach MPS parity; risk exceeds PR-sized constraints.

### Branch C — Keep Makefile as Source of Truth and Wrap It (PRUNED)
**Pattern:** Leave CI as `make bootstrap/verify`; create nox sessions that shell out to `make`.

**Complexity:** Low
**Scalability:** Medium
**Constraint adherence:** Weak (two sources of truth; parity relies on Makefile stability; deterministic audit remains fragile)
**Why pruned:** MPS wants automation-first, explicit gates; this keeps drift and wastes agent tokens.

## Selected Branch
**Branch A — Root-level MPS automation wrapper**

## Target Structure
- `.claude.md` (new, canonical)
- `.claude/commands/` (retain; referenced, not duplicated)
- `docs/` includes `SPECS.md`, `PLAN.md`, `TASKS.md`, `adr/`
- `tools/` remains the scoped Python project initially

## Public Contracts (Canonical Commands)
From repo root:
- `uv run nox -s all`
- `uv run nox -s fmt`
- `uv run nox -s lint`
- `uv run nox -s type`
- `uv run nox -s test`
- `uv run nox -s audit`

Deterministic audit export (called by nox `audit`):
- `uv export --frozen --no-dev --output-file requirements-audit.txt`

## Data / Invariants
- `.venv/` is local-only and not referenced by CI.
- Audit input is deterministic via exported requirements.
- CI and local run the same gate suite.
- `.claude.md` remains short; deeper guidance stays in `.claude/commands/*`.

## Error Handling Strategy
- Gates fail-fast with actionable error output.
- Formatting may auto-fix via ruff; lint/type/test/audit should fail without auto-mutating.

## Observability / Logging Constraints
- Never log secrets.
- CI output should avoid dumping full environments unless debugging is explicitly enabled.

## Automation Approach
- `noxfile.py` defines authoritative sessions.
- `.pre-commit-config.yaml` mirrors key checks (or calls nox sessions).
- `.github/workflows/ci.yml` runs `uv run nox -s all`.

## Definition of Done Gates (Phase 1)
- `pre-commit run --all-files`
- `uv run nox -s all`
- CI green on the same suite
- `.claude.md` updated if commands/layout changed

---

## Phase 2 — Detection Engineering Pipeline

See ADR-0002 for the full Tree of Thoughts analysis and branch pruning.

### Selected Branch: End-to-End Detection Engineering Pipeline
**Pattern:** Connect the existing, underutilized tools into a single testable pipeline.
The story: Sigma rule (input) → sigma_convert.py (convert) → Wazuh XML (deploy artifact)
→ scenario attack run → alert captured → enrich_alerts.py (enrich) → report.py (IR summary output).

**Complexity:** Medium
**Scalability:** High — each new scenario adds one Sigma YAML + one fixture; pipeline is unchanged.
**Constraint adherence:** Strong — all changes scoped to `tools/`; no new infrastructure; fully testable offline.

### Directory Structure (Phase 2 additions)
```
tools/
├── sigma/                    # NEW: Sigma rule library (YAML, one per scenario)
│   ├── 01-nmap-recon.yml
│   ├── 02-ssh-brute-force.yml
│   ├── 03-vsftpd-exploit.yml
│   ├── 04-priv-escalation.yml
│   └── 05-suspicious-file.yml
├── report.py                 # NEW: Markdown IR report generator from enriched JSON
├── fixtures/
│   └── sample_enriched.json  # NEW: Fixture for offline report generation tests
├── enrich_alerts.py          # MODIFIED: add --output flag, typed JSON schema
└── demo_enrich.py            # MODIFIED: use fixtures so it runs offline (no Wazuh needed)
README.md                     # NEW: rebuilt public face of the project
```

### Public Contracts (Phase 2 additions)
```
# Sigma → Wazuh rule conversion
python tools/sigma_convert.py tools/sigma/01-nmap-recon.yml

# Offline pipeline demo (no Wazuh API required)
uv run python tools/demo_enrich.py

# Generate IR report from enriched alert JSON
python tools/report.py tools/fixtures/sample_enriched.json
```

### Data Schemas
**Enriched alert JSON schema** (output of `enrich_alerts.py --output`):
```json
[{
  "rule_id": "string",
  "level": "int",
  "description": "string",
  "source_ip": "string | null",
  "mitre_id": "string | null",
  "timestamp": "string (ISO 8601)",
  "risk_label": "critical | high | medium | low",
  "mitre_description": "string | null"
}]
```

**Sigma YAML minimum fields** (for `sigma_convert.py` compatibility):
```yaml
title: string
id: string (uuid4)
description: string
logsource:
  product: linux | windows
detection:
  selection:
    <field>: [<values>]
  condition: selection
tags:
  - attack.t<NNNN> or attack.t<NNNN.NNN>
```

### Error Handling (Phase 2)
- `sigma_convert.py`: exits 2 with descriptive error on missing required fields; exits 1 on usage error.
- `report.py`: exits 1 on invalid/missing JSON input; exits 0 with path of written report.
- `demo_enrich.py`: reads from `tools/fixtures/sample_enriched.json`; no network call;
  prints triage report + JSON to stdout. Returns 0 always (demo tool).

### Definition of Done Gates (Phase 2)
- `uv run nox -s test` passes (all Phase 1 + Phase 2 tests)
- `uv run python tools/demo_enrich.py` runs offline and produces human-readable output
- `python tools/sigma_convert.py tools/sigma/01-nmap-recon.yml` produces valid Wazuh XML
- `README.md` exists and renders on GitHub with no broken links
- ADR-0002 status updated to Accepted
