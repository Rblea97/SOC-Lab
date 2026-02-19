# SPECS — SOC_LAB MPS Alignment + Detection Engineering Pipeline

## Problem / Context
The repo must be cleaned and standardized to align with the MPS automation model:
- single source of truth for gates (local == CI)
- deterministic dependency/audit pipeline
- minimal ambiguity for agent sessions

Current state shows drift:
- CI runs `make bootstrap` / `make verify` and separately installs `pip-audit` after activating `.venv`.
- Pre-commit enforces ruff on `tools/` only, plus shellcheck and gitleaks.
- Python tooling config (in `tools/pyproject.toml`) uses mypy, not pyright, and does not define MPS-style uv/nox gates.

## Goals
G-001. Make repo automation **MPS-canonical**:
- `uv` + `nox` become authoritative for all gates.
- CI runs the same `uv run nox -s all` suite as local.

G-002. Enforce deterministic dependency + audit workflow:
- Generate `requirements-audit.txt` via frozen export from locked deps.
- Run `pip-audit` using that exported file (not the ambient environment).

G-003. Standardize typing to MPS expectations:
- `pyright` is the canonical type gate.
- `mypy` (if retained) is optional and not in “definition of done” gates unless explicitly justified.

G-004. Repo hygiene:
- `.venv/` must not be tracked or depended on by CI.
- No tracked caches/compiled artifacts: `__pycache__/`, `.pytest_cache/`, `.ruff_cache/`, `.mypy_cache/`, `*.pyc`.

G-005. Claude Code token minimization:
- Create root `.claude.md` as the canonical session contract.
- Avoid redundant instruction duplication between `.claude/commands/*`, `docs/agent/claude-code.md`, and `.claude.md`.

## Non-Goals
NG-001. No new features.
NG-002. No major directory reshuffles (e.g. moving `tools/` into `src/`) without explicit approval via ADR.
NG-003. No behavior changes to attack scenarios, evidence formats, or Wazuh configs except compliance/security necessities.

## Functional Requirements (numbered, testable)
FR-001. Canonical gates exist and pass:
- `uv run nox -s all` succeeds from repo root on a clean checkout.
- Individual sessions exist: `fmt`, `lint`, `type`, `test`, `audit`.

FR-002. CI runs parity gates:
- GitHub Actions workflow executes `uv run nox -s all` (no separate “make verify” source of truth).

FR-003. Deterministic audit:
- `requirements-audit.txt` is generated using a frozen export path.
- `nox -s audit` runs `pip-audit -r requirements-audit.txt`.

FR-004. Type checking uses pyright:
- `nox -s type` runs pyright (canonical).
- mypy is not required for DoD unless explicitly documented.

FR-005. Hygiene enforced:
- `.venv/` is not tracked; CI does not activate `.venv`.
- `.gitignore` prevents committing caches/pyc/venv.
- pre-commit blocks common artifact additions.

FR-006. Root `.claude.md` exists and contains:
- purpose (<=10 lines)
- repo map + edit boundaries
- canonical gate commands
- forbidden changes (no drive-bys, no secrets)
- one-task workflow and stop conditions

## Non-Functional Requirements
### Security
NFR-S-001. Secrets never committed; `.env.example` remains template-only.
NFR-S-002. `pip-audit` runs deterministically from exported requirements.

### Reliability
NFR-R-001. Local == CI gates with no hidden “make” side paths.

### DX
NFR-DX-001. A new contributor or agent can run gates with one command.
NFR-DX-002. `.claude.md` eliminates repeated context rehydration.

## Constraints
C-001. PR-sized tasks (30–90 minutes).
C-002. <=150 LOC net change per task unless explicitly exempted.
C-003. Structural changes require ADR + regenerated TASKS.

## Acceptance Criteria
AC-001. `uv run nox -s all` passes locally.
AC-002. CI workflow passes and runs the same nox suite.
AC-003. `pre-commit run --all-files` passes.
AC-004. No tracked `.venv/` or cache artifacts in git.
AC-005. `.claude.md` is canonical and non-redundant.

---

# Phase 2 — Detection Engineering Pipeline (Portfolio Differentiation)

See ADR-0002 for the Tree of Thoughts branch selection that led to this phase.

## Problem / Context
The lab has 5 validated attack scenarios, custom Wazuh detection rules, and two Python tools
(`sigma_convert.py`, `enrich_alerts.py`), but these components are disconnected:
- `sigma_convert.py` has no Sigma YAML source files as input — it is a converter with nothing to convert.
- `enrich_alerts.py` requires a live Wazuh API; no offline demo or fixture-based path exists.
- `README.md` was removed during MPS transition; the project has no public face.

A recruiter or peer cloning the repo cannot run a meaningful demo in under 5 minutes.
The portfolio story — detection engineering from rule authoring to incident report — is implied but not demonstrated.

## Goals
G-P2-001. Create a Sigma rule library for existing scenarios:
- 5 Sigma YAML files in `tools/sigma/` (one per validated scenario).
- Each file is a deployable, community-standard rule.

G-P2-002. Define a typed JSON output schema for `enrich_alerts.py`:
- Output must be machine-readable and fixture-testable without a live Wazuh instance.
- `--output <file>` flag writes JSON; stdout remains the human-readable triage report.

G-P2-003. Add a Markdown report generator (`tools/report.py`):
- Consumes enriched JSON; produces a structured IR summary in Markdown.
- Offline and testable via fixtures — no network required.

G-P2-004. End-to-end pipeline integration tests:
- pytest suite covers: Sigma parse → XML convert → alert enrich → report render.
- All tests run via `uv run nox -s test` with no live dependencies.

G-P2-005. Rebuild `README.md`:
- Architecture diagram, scenario matrix, quick-start (`uv run python tools/demo_enrich.py`),
  evidence links, and CI badge.
- A hiring manager can evaluate the project in under 5 minutes.

## Non-Goals
NG-P2-001. No live/cloud threat intelligence integration (static fixtures only for unit tests).
NG-P2-002. No Wazuh dashboard UI automation (screenshots remain manual evidence).
NG-P2-003. No new attack scenarios beyond the existing 5.
NG-P2-004. No new network infrastructure or VM changes.

## Functional Requirements (Phase 2, numbered, testable)
FR-P2-001. Sigma rule library exists:
- `tools/sigma/01-nmap-recon.yml`, `02-ssh-brute-force.yml`, `03-vsftpd-exploit.yml`,
  `04-priv-escalation.yml`, `05-suspicious-file.yml`.
- Each validates against `sigma_convert.py` without error.

FR-P2-002. `sigma_convert.py` CLI accepts each rule and produces valid Wazuh XML to stdout:
- `python tools/sigma_convert.py tools/sigma/01-nmap-recon.yml` exits 0 with valid XML.

FR-P2-003. `enrich_alerts.py` supports `--output <file>` writing JSON:
- JSON schema: `[{ "rule_id", "level", "description", "source_ip", "mitre_id",
  "timestamp", "risk_label", "mitre_description" }]`
- `demo_enrich.py` uses fixture data so it runs without a live Wazuh API.

FR-P2-004. `report.py` generates a Markdown IR summary from enriched JSON:
- `python tools/report.py report.json` writes `report.md` with scenario context, MITRE mapping,
  risk labels, and recommended triage actions.

FR-P2-005. pytest covers the full pipeline using fixtures:
- `test_pipeline.py`: parse Sigma → convert to XML → validate XML → enrich fixture alert → render report.
- All assertions are deterministic (no live network calls).

FR-P2-006. `README.md` is rebuilt and complete:
- Sections: Overview, Architecture, Scenarios, Quick Start, Evidence, IR Reports, Gates.
- All internal links resolve.
- CI badge reflects `main` branch.

## Non-Functional Requirements (Phase 2)
### DX
NFR-P2-DX-001. Pipeline demo runs offline: `uv run python tools/demo_enrich.py` produces
  human-readable + JSON output with no env vars required.
NFR-P2-DX-002. README renders correctly on GitHub with no broken links or raw HTML.

### Reliability
NFR-P2-R-001. `uv run nox -s test` passes including all Phase 2 pipeline tests on CI.

### Security
NFR-P2-S-001. No credentials, IPs, or credentials in Sigma YAML files or fixtures.
NFR-P2-S-002. Fixtures use synthetic/anonymized log data only.

## Constraints
C-P2-001. PR-sized tasks (30–90 minutes).
C-P2-002. <=150 LOC net change per task unless exception noted.
C-P2-003. Each tool change must keep existing tests green.

## Acceptance Criteria (Phase 2)
AC-P2-001. `python tools/sigma_convert.py tools/sigma/01-nmap-recon.yml` exits 0 and outputs valid Wazuh XML.
AC-P2-002. `uv run python tools/demo_enrich.py` outputs triage report + JSON with no env vars.
AC-P2-003. `python tools/report.py tools/fixtures/sample_enriched.json` writes a valid Markdown file.
AC-P2-004. `uv run nox -s test` passes (all Phase 1 + Phase 2 tests).
AC-P2-005. `README.md` exists, renders on GitHub, all links resolve.
