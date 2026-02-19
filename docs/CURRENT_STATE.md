# CURRENT_STATE — SOC_LAB (Memory Keeper Snapshot)

**Generated:** 2026-02-19
**Phase 1 status:** COMPLETE (TASK-001–007 committed)
**Phase 2 status:** COMPLETE (TASK-008–012 committed)
**Phase 3 status:** PLANNED (TASK-013–020 defined; none started)

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
| Session contract | `CLAUDE.md` (renamed from `.claude.md`; now auto-loads in Claude Code) |

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
| TASK-001 | `.gitignore` hardened; `.venv/`, caches, `*.pyc` untracked | ✅ committed |
| TASK-002 | `CLAUDE.md` (root session contract, ~55 lines) | ✅ committed |
| TASK-003 | `noxfile.py` (root, sessions: fmt/lint/type/test/audit/all) | ✅ committed |
| TASK-004 | `pyproject.toml` + nox `type` session uses pyright | ✅ committed |
| TASK-005 | `requirements-audit.txt` generated; `nox audit` deterministic | ✅ committed |
| TASK-006 | `.pre-commit-config.yaml` updated (pyright + artifact guards) | ✅ committed |
| TASK-007 | `.github/workflows/ci.yml` runs `uv run nox -s all` | ✅ committed |

### Staged deletions (expected)
`README.md` (old), `CLAUDE.md`, `Makefile`, `spec.md`, `CONTRIBUTING.md`, `LICENSE`, `SECURITY.md`
> NOTE: Old `README.md` deletion is intentional — TASK-012 rebuilt it at repo root (99 lines). New `README.md` is untracked and will replace the deleted one on commit.

### Outstanding items
- None. All Phase 1 changes committed.

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
| `report.py` | `tools/report.py` | ✅ committed (TASK-010) |
| `tools/sigma/` | `tools/sigma/` (01–05 YAMLs) | ✅ committed (TASK-008) |
| `tools/fixtures/sample_enriched.json` | `tools/fixtures/sample_enriched.json` | ✅ committed (TASK-009) |
| `tools/fixtures/sample_enriched.md` | `tools/fixtures/sample_enriched.md` | ✅ committed (TASK-010 output) |
| `tools/tests/test_pipeline.py` | `tools/tests/test_pipeline.py` | ✅ committed — 14 integration tests (TASK-011) |
| `tools/tests/test_report.py` | `tools/tests/test_report.py` | ✅ committed — 6 tests (TASK-010) |
| `README.md` | `README.md` (repo root, 99 lines) | ✅ committed (TASK-012) |

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

## Phase 3 — Portfolio Completion (TASK-013–020)

**Status: PLANNED** — None started. Execute in order listed.

### Phase 3 task inventory

| Task | Subject | Target file(s) | Status |
|---|---|---|---|
| TASK-020 | Update planning docs + CLAUDE.md rename | `CLAUDE.md`, `docs/TASKS.md`, `docs/SPECS.md`, `docs/CURRENT_STATE.md`, `docs/adr/ADR-0002-*.md` | ✅ DONE (this session) |
| TASK-013 | IR report: Nmap Recon | `docs/ir-report-nmap-recon.md` (new) | 🔲 pending |
| TASK-014 | IR report: vsftpd Exploit | `docs/ir-report-vsftpd-exploit.md` (new) | 🔲 pending |
| TASK-015 | IR report: Priv Escalation | `docs/ir-report-priv-escalation.md` (new) | 🔲 pending |
| TASK-016 | IR report: Suspicious File | `docs/ir-report-suspicious-file.md` (new) | 🔲 pending |
| TASK-017 | Update portfolio-writeup.md | `docs/portfolio-writeup.md` (modify) | 🔲 pending |
| TASK-018 | ATT&CK Navigator layer | `docs/attack-coverage.json` (new) | 🔲 pending |
| TASK-019 | End-to-end pipeline demo | `tools/pipeline_demo.py` (new), `tools/tests/test_pipeline_demo.py` (new) | 🔲 pending |

### Execution order
```
TASK-020 (done) → TASK-013, TASK-014, TASK-015, TASK-016 (any order, independent)
                → TASK-018 (independent)
                → TASK-019 (independent, longest — do when fresh)
                → TASK-017 (after 013–016 so all IR filenames can be cited)
```

### Known gaps (Phase 3 starting point)
- IR reports exist **only for scenario 02** (`docs/ir-report-ssh-brute-force.md` as IR-2026-002)
- `docs/portfolio-writeup.md`: stale `make` commands, "26 tests", "two Python utilities", `mypy`
- No `docs/attack-coverage.json` Navigator layer
- No `tools/pipeline_demo.py` (full pipeline demo)

### Phase 3 DoD gate (applies to every task)
```bash
uv run nox -s all
```
Documentation-only tasks (013–018, 020) pass trivially. TASK-019 must also pass `fmt lint type test`.

---

## Constraints (carry forward)
- C-001/C-P2-001: 30–90 min per task
- C-002/C-P2-002: <=150 LOC net per task (TASK-009 exception: ~160 LOC documented; TASK-019 exception: ~150 LOC across script + tests, documented)
- C-003: structural changes require ADR + regenerated TASKS (no ADR needed for Phase 3 — see TASK-019)
- NFR-S-001: secrets never committed; `.env.example` is template-only
