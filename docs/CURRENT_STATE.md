# CURRENT_STATE — SOC_LAB (Memory Keeper Snapshot)

**Generated:** 2026-02-19
**Phase 1 status:** COMPLETE (TASK-001–007 implemented; staged, NOT yet committed)
**Phase 2 status:** COMPLETE (TASK-008–012 implemented; untracked, pending commit)

---

## Reference Map

| Artifact | Location |
|---|---|
| Specs | `docs/SPECS.md` |
| Plan (ToT branch) | `docs/PLAN.md` |
| Task list | `docs/TASKS.md` |
| ADR-0001 (uv+nox parity) | `docs/adr/ADR-0001-root-nox-uv-parity-and-deterministic-audit.md` |
| ADR-0002 (detection pipeline) | `docs/adr/ADR-0002-detection-engineering-pipeline-phase-2.md` ✅ ACCEPTED |
| README.md | `README.md` (root, 99 lines, 7 sections, CI badge) ⚠️ UNTRACKED |
| Session contract | `.claude.md` |

---

## Phase 1 — MPS Alignment (TASK-001–007)

### Decisions (ADR-0001, Accepted)
- **Gate authority:** `uv + nox` is canonical; `make`/`.venv` paths are eliminated.
- **Canonical command:** `uv run nox -s all` (local == CI).
- **Sessions:** `fmt` (ruff), `lint` (ruff), `type` (pyright), `test` (pytest), `audit` (pip-audit).
- **Type checker:** `pyright` is DoD gate; mypy is non-gating.
- **Deterministic audit:** `uv export --frozen --no-dev --output-file requirements-audit.txt` then `pip-audit -r requirements-audit.txt`.
- **No `.venv` in CI;** no Makefile source of truth.

### What was implemented (staged, uncommitted)
| Task | File(s) | Status |
|---|---|---|
| TASK-001 | `.gitignore` hardened; `.venv/`, caches, `*.pyc` untracked | ✅ staged |
| TASK-002 | `.claude.md` (root session contract, ~55 lines) | ✅ staged |
| TASK-003 | `noxfile.py` (root, sessions: fmt/lint/type/test/audit/all) | ✅ staged |
| TASK-004 | `pyproject.toml` + nox `type` session uses pyright | ✅ staged |
| TASK-005 | `requirements-audit.txt` generated; `nox audit` deterministic | ✅ staged |
| TASK-006 | `.pre-commit-config.yaml` updated (pyright + artifact guards) | ✅ staged |
| TASK-007 | `.github/workflows/ci.yml` runs `uv run nox -s all` | ✅ staged |

### Staged deletions (expected)
`README.md` (old), `CLAUDE.md`, `Makefile`, `spec.md`, `CONTRIBUTING.md`, `LICENSE`, `SECURITY.md`
> NOTE: Old `README.md` deletion is intentional — TASK-012 rebuilt it at repo root (99 lines). New `README.md` is untracked and will replace the deleted one on commit.

### Outstanding items (pending commit)
1. **Commit Phase 1 staged changes** (all of the above + ADR-0002 untracked file).
2. `docs/TASKS.md`, `docs/SPECS.md`, `docs/PLAN.md` have working-tree modifications (AM status) — stage and commit those too.
3. **Commit Phase 2 untracked files:** `README.md`, `tools/report.py`, `tools/sigma/` (01–05), `tools/fixtures/sample_enriched.json`, `tools/fixtures/sample_enriched.md`, `tools/tests/test_pipeline.py`, `tools/tests/test_report.py`.

### Known gaps
- IR reports exist **only for scenario 02** (`docs/ir-report-ssh-brute-force.md`). Scenarios 01, 03, 04, 05 have no IR report yet.

---

## Phase 2 — Detection Engineering Pipeline (TASK-008–012)

### Decision (ADR-0002, **Accepted** — all DoD gates green)
**Selected branch:** End-to-End Detection Engineering Pipeline.
```
Sigma YAML → sigma_convert.py → Wazuh XML
     ↓
Attack scenario (existing)
     ↓
Wazuh alert → enrich_alerts.py --output → enriched JSON
     ↓
report.py → Markdown IR summary
```
All stages run **offline via fixtures**; testable via `uv run nox -s test`.

### Current tool inventory
| Tool | Location | Phase 2 status |
|---|---|---|
| `sigma_convert.py` | `tools/sigma_convert.py` | ✅ EXISTS — 5 Sigma YAMLs in `tools/sigma/` (TASK-008) |
| `enrich_alerts.py` | `tools/enrich_alerts.py` | ✅ EXISTS — `--output` JSON flag added (TASK-009) |
| `demo_enrich.py` | `tools/demo_enrich.py` | ✅ EXISTS — offline fixture mode implemented (TASK-009) |
| `report.py` | `tools/report.py` | ✅ EXISTS — `generate_report` + main (TASK-010) ⚠️ UNTRACKED |
| `tools/sigma/` | `tools/sigma/` (01–05 YAMLs) | ✅ EXISTS (TASK-008) ⚠️ UNTRACKED |
| `tools/fixtures/sample_enriched.json` | `tools/fixtures/sample_enriched.json` | ✅ EXISTS (TASK-009) ⚠️ UNTRACKED |
| `tools/fixtures/sample_enriched.md` | `tools/fixtures/sample_enriched.md` | ✅ EXISTS (TASK-010 output) ⚠️ UNTRACKED |
| `tools/tests/test_pipeline.py` | `tools/tests/test_pipeline.py` | ✅ EXISTS — 14 integration tests (TASK-011) ⚠️ UNTRACKED |
| `tools/tests/test_report.py` | `tools/tests/test_report.py` | ✅ EXISTS — 6 tests (TASK-010) ⚠️ UNTRACKED |
| `README.md` | `README.md` (repo root, 99 lines) | ✅ EXISTS (TASK-012) ⚠️ UNTRACKED |

**Full suite:** `uv run nox -s fmt lint type test` → green, **50 tests passing**.

Note: `tools/fixtures/sample_alerts.json` EXISTS (pre-existing fixture, different schema from Phase 2 enriched JSON).

### Task order (hard dependency chain)
```
TASK-008 (sigma YAMLs) ──┐
TASK-009 (--output flag) ─┤
                          ├─→ TASK-011 (pipeline integration test)
TASK-010 (report.py) ─────┘       │
                                   └─→ TASK-012 (README — final)
```

### Enriched alert JSON schema (LOCK — do not change without ADR)
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

### Sigma YAML minimum fields (for sigma_convert.py compatibility)
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

### Phase 2 DoD gates (ALL GREEN ✅)
- `python tools/sigma_convert.py tools/sigma/01-nmap-recon.yml` exits 0, valid Wazuh XML ✅
- `uv run python tools/demo_enrich.py` runs offline (zero env vars), prints triage + JSON ✅
- `python tools/report.py tools/fixtures/sample_enriched.json` writes valid Markdown ✅
- `uv run nox -s test` passes (all Phase 1 + Phase 2 tests, 50 total) ✅
- `README.md` exists, renders on GitHub, all links resolve ✅
- ADR-0002 status updated to Accepted ✅

### Security constraints (Phase 2)
- No credentials, real IPs, or secrets in `tools/sigma/*.yml` or `tools/fixtures/*.json`
- Fixtures use synthetic/anonymized data only
- `tools/fixtures/` may need gitleaks allowlist if gitleaks false-positives on fixture data

---

## Canonical Gate Commands (copy-paste ready)
```bash
# Full suite (local == CI)
uv run nox -s all

# Individual gates
uv run nox -s fmt
uv run nox -s lint
uv run nox -s type
uv run nox -s test
uv run nox -s audit

# Pre-commit
pre-commit run --all-files

# Deterministic audit export (called by nox audit session)
uv export --frozen --no-dev --output-file requirements-audit.txt
```

---

## Constraints (carry forward)
- C-001/C-P2-001: 30–90 min per task
- C-002/C-P2-002: <=150 LOC net per task (TASK-009 exception: ~160 LOC documented)
- C-003: structural changes require ADR + regenerated TASKS
- NFR-S-001: secrets never committed; `.env.example` is template-only
