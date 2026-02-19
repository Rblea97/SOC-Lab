# TASKS — SOC_LAB MPS Alignment + Detection Engineering Pipeline

## Global Rules
- 30–90 minutes per task
- <=150 LOC net change per task unless exception noted
- No drive-by refactors
- Verification: run listed commands

---

## TASK-001 — Remove tracked `.venv` and cached artifacts; harden `.gitignore`
**Scope**
- Ensure `.venv/` is not tracked and will not be re-added.
- Purge tracked caches/compiled artifacts (ruff/mypy/pytest caches, `__pycache__`, `*.pyc`).

**Files allowed to change**
- `.gitignore`
- remove tracked files under `.venv/**` and caches/pyc paths

**Forbidden changes**
- no changes to Python source logic
- no CI changes

**Acceptance Criteria**
- `git ls-files` contains none of: `.venv/`, `__pycache__`, `.pytest_cache`, `.ruff_cache`, `.mypy_cache`, `*.pyc`

**Test Plan**
- N/A

**DoD checklist**
- [ ] artifacts removed from git
- [ ] ignore rules prevent recurrence

**Verification commands**
- `git ls-files | rg -n '(^\.venv/|__pycache__|\.pytest_cache|\.ruff_cache|\.mypy_cache|\.pyc$)' || true`
- `git status --porcelain`

---

## TASK-002 — Create root `.claude.md` (canonical, token-minimized)
**Scope**
- Add `.claude.md` at repo root as canonical session contract.
- Convert `docs/agent/claude-code.md` into a short pointer (if it currently duplicates instructions).

**Files allowed to change**
- `.claude.md` (new)
- `docs/agent/claude-code.md` (optional pointer-only edit)

**Forbidden changes**
- no tooling/CI changes

**Acceptance Criteria**
- `.claude.md` includes: purpose, repo map, canonical commands, edit boundaries, forbidden actions, one-task workflow.

**Test Plan**
- N/A

**DoD checklist**
- [ ] <= ~80–120 lines, high signal
- [ ] no duplication with `.claude/commands/*`

**Verification commands**
- `wc -l .claude.md`

---

## TASK-003 — Introduce root `noxfile.py` as gate authority (scoped to `tools/`)
**Scope**
- Create `noxfile.py` at repo root defining sessions:
  - `fmt`: ruff format for `tools/`
  - `lint`: ruff check for `tools/`
  - `type`: pyright over `tools/`
  - `test`: pytest over `tools/tests`
  - `audit`: deterministic export + pip-audit
  - `all`: runs them in sequence

**Files allowed to change**
- `noxfile.py` (new)
- `docs/runbook.md` (optional: reference new commands)

**Forbidden changes**
- no changes to `tools/*.py` logic
- no CI changes in this task

**Acceptance Criteria**
- `uv run nox -l` lists sessions above.
- Each session runs (may fail until later tasks add deps/config).

**Test Plan**
- Run each session.

**DoD checklist**
- [ ] sessions exist
- [ ] output readable

**Verification commands**
- `uv run nox -l`
- `uv run nox -s fmt`
- `uv run nox -s lint`
- `uv run nox -s test`

---

## TASK-004 — Switch typing gate from mypy to pyright (update deps/config)
**Scope**
- Update Python dev deps so pyright is available and canonical.
- Remove mypy from DoD gates; optionally keep mypy as non-gated extra.

**Files allowed to change**
- `tools/pyproject.toml`
- `noxfile.py`
- `.pre-commit-config.yaml` (if adding pyright hook)

**Forbidden changes**
- no changes to Python source logic

**Acceptance Criteria**
- `uv run nox -s type` runs pyright successfully.
- `rg "mypy|dmypy"` shows no gating usage (unless explicitly documented).

**Test Plan**
- Run type gate.

**DoD checklist**
- [ ] pyright is canonical
- [ ] mypy not required for DoD

**Verification commands**
- `uv run nox -s type`
- `rg -n "mypy|dmypy" . || true`

---

## TASK-005 — Deterministic audit: export + pip-audit via nox
**Scope**
- Implement deterministic `requirements-audit.txt` generation and run `pip-audit` from that file.

**Files allowed to change**
- `noxfile.py`
- `requirements-audit.txt` (generated, committed if you want reproducibility)
- `docs/security/dependencies.md` (update)

**Forbidden changes**
- no changes to application logic

**Acceptance Criteria**
- `uv run nox -s audit` performs frozen export then runs `pip-audit -r requirements-audit.txt`.

**Test Plan**
- Run audit gate twice and confirm stable behavior.

**DoD checklist**
- [ ] audit is deterministic
- [ ] documentation matches commands

**Verification commands**
- `uv run nox -s audit`
- `git diff --stat`

---

## TASK-006 — Update pre-commit to mirror MPS gates (pyright + artifact guards)
**Scope**
- Extend `.pre-commit-config.yaml`:
  - add pyright check (or call `uv run nox -s type` if you prefer a single source)
  - add hooks to prevent committing `.venv`/caches/pyc artifacts

**Files allowed to change**
- `.pre-commit-config.yaml`
- `.gitignore` (if needed)

**Forbidden changes**
- no CI changes

**Acceptance Criteria**
- `pre-commit run --all-files` passes.
- A staged forbidden artifact is blocked (documented).

**Test Plan**
- Run pre-commit and simulate staging an artifact.

**DoD checklist**
- [ ] hooks fast and deterministic

**Verification commands**
- `pre-commit run --all-files`

---

## TASK-007 — Update CI to run `uv run nox -s all` (remove `make` + `.venv` activation)
**Scope**
- Replace `make bootstrap`, `make verify`, and `. .venv/bin/activate` in CI with uv+nox parity.

**Files allowed to change**
- `.github/workflows/ci.yml`

**Forbidden changes**
- no code changes

**Acceptance Criteria**
- CI runs `uv run nox -s all`.
- CI runs audit via `nox -s audit` (deterministic export path).
- Remove pip cache config that assumes pip-centric install; prefer uv cache or no caching initially.

**Test Plan**
- PR run; verify jobs green.

**DoD checklist**
- [ ] CI/local parity achieved
- [ ] no hidden “make verify” path

**Verification commands**
- `uv run nox -s all`

---

# Phase 2 — Detection Engineering Pipeline

> Prerequisite: TASK-001 through TASK-007 complete (MPS alignment done).
> See ADR-0002 for architectural rationale.

---

## TASK-008 — Create Sigma rule library (5 YAML files in `tools/sigma/`)
**Scope**
- Author one Sigma YAML rule per existing validated scenario.
- Rules must be syntactically valid and parseable by `sigma_convert.py`.

**Files allowed to change**
- `tools/sigma/01-nmap-recon.yml` (new)
- `tools/sigma/02-ssh-brute-force.yml` (new)
- `tools/sigma/03-vsftpd-exploit.yml` (new)
- `tools/sigma/04-priv-escalation.yml` (new)
- `tools/sigma/05-suspicious-file.yml` (new)

**Forbidden changes**
- no changes to `sigma_convert.py` logic
- no CI changes
- no credentials or real IPs in YAML files

**Acceptance Criteria**
- `python tools/sigma_convert.py tools/sigma/01-nmap-recon.yml` exits 0 and produces valid Wazuh XML.
- All 5 rules parse without error.
- Each rule includes a `tags` field with at least one `attack.t<NNNN>` ATT&CK technique.

**Test Plan**
- Run `sigma_convert.py` against each file; check exit code and XML validity.

**DoD checklist**
- [ ] 5 Sigma YAML files committed under `tools/sigma/`
- [ ] each passes `sigma_convert.py` validation (exit 0, valid XML)
- [ ] MITRE tags present on all rules
- [ ] no secrets/credentials/real IPs

**Verification commands**
```
for f in tools/sigma/*.yml; do
  python tools/sigma_convert.py "$f" > /dev/null && echo "OK: $f" || echo "FAIL: $f"
done
```

---

## TASK-009 — Add `--output` JSON flag and offline fixture mode to `enrich_alerts.py` / `demo_enrich.py`
**Scope**
- Add `--output <file>` CLI flag to `enrich_alerts.py` that writes enriched alerts as JSON.
- Update `demo_enrich.py` to load from `tools/fixtures/sample_enriched.json` so it runs with no env vars and no Wazuh API.
- Create `tools/fixtures/sample_enriched.json` with 3–5 synthetic alert records (one per distinct MITRE technique).

**Files allowed to change**
- `tools/enrich_alerts.py`
- `tools/demo_enrich.py`
- `tools/fixtures/sample_enriched.json` (new)

**Forbidden changes**
- no changes to `fetch_alerts()` live-API logic (do not break it)
- no real IPs or credentials in fixtures
- no CI changes

**Acceptance Criteria**
- `uv run python tools/demo_enrich.py` runs offline and prints human-readable triage report + JSON.
- `uv run nox -s test` still passes all existing tests.
- JSON output matches schema: `[{ rule_id, level, description, source_ip, mitre_id, timestamp, risk_label, mitre_description }]`.

**Test Plan**
- Add tests in `tools/tests/test_enrich.py` asserting JSON output schema against fixture data.

**Exception:** LOC limit may be slightly exceeded (~160 LOC net) due to fixture file creation; explicitly noted here.

**DoD checklist**
- [ ] `demo_enrich.py` runs offline (zero env vars)
- [ ] JSON schema matches spec
- [ ] existing tests still pass
- [ ] fixture contains no real credentials or IPs

**Verification commands**
- `uv run python tools/demo_enrich.py`
- `uv run nox -s test`

---

## TASK-010 — Add Markdown report generator (`tools/report.py`)
**Scope**
- Create `tools/report.py`: reads enriched JSON (from `--output` in TASK-009 or a fixture file),
  writes a structured Markdown IR summary to `<input-stem>.md`.
- Report sections: Summary, Alert Table (rule ID, risk, MITRE, timestamp, source IP),
  MITRE Techniques, Recommended Triage Actions.
- Triage action text is static per risk label (e.g., high → "escalate to T2; isolate host").

**Files allowed to change**
- `tools/report.py` (new)
- `tools/tests/test_report.py` (new)

**Forbidden changes**
- no changes to `enrich_alerts.py` or `sigma_convert.py`
- no CI changes

**Acceptance Criteria**
- `python tools/report.py tools/fixtures/sample_enriched.json` writes `tools/fixtures/sample_enriched.md`.
- Output file contains all 4 required sections.
- `uv run nox -s test` passes.

**Test Plan**
- `test_report.py`: assert output file exists, contains expected section headers, alert count matches fixture.

**DoD checklist**
- [ ] `report.py` exits 0 and writes Markdown
- [ ] 4 required sections present
- [ ] `nox -s test` passes

**Verification commands**
- `python tools/report.py tools/fixtures/sample_enriched.json && cat tools/fixtures/sample_enriched.md`
- `uv run nox -s test`

---

## TASK-011 — End-to-end pipeline integration test (`test_pipeline.py`)
**Scope**
- Add `tools/tests/test_pipeline.py` covering the full offline pipeline:
  1. Parse each `tools/sigma/*.yml` with `parse_sigma_rule()`.
  2. Convert to Wazuh XML with `convert_to_wazuh_xml()`.
  3. Validate XML with `validate_wazuh_rule()`.
  4. Enrich a fixture alert with `enrich_alert()`.
  5. Generate a Markdown report from fixture JSON.
- All steps use existing functions and fixtures; no live API calls.

**Files allowed to change**
- `tools/tests/test_pipeline.py` (new)

**Forbidden changes**
- no changes to application logic
- no CI changes

**Acceptance Criteria**
- `uv run nox -s test` passes including `test_pipeline.py`.
- Each of the 5 Sigma rules produces valid Wazuh XML in the pipeline test.
- Report generation step asserts output file is non-empty and contains expected headings.

**Test Plan**
- The test file IS the test plan. Run `uv run nox -s test -k pipeline`.

**DoD checklist**
- [ ] pipeline test covers all 5 scenarios
- [ ] zero live network calls (confirmed by no `requests` import in test file)
- [ ] `nox -s test` green

**Verification commands**
- `uv run nox -s test -k pipeline`
- `uv run nox -s test`

---

## TASK-012 — Rebuild `README.md` (public face, interview-ready)
**Scope**
- Rebuild `README.md` at repo root (deleted in MPS transition).
- Document the project with real, runnable output — not aspirational copy.
- Must be completable only after TASK-008 through TASK-011 are done (real output to document).

**Files allowed to change**
- `README.md` (new)

**Forbidden changes**
- no code changes
- no CI changes

**Acceptance Criteria**
- `README.md` contains all required sections (see below).
- All internal links resolve (evidence files, IR reports, docs).
- CI badge URL targets `main` branch.
- `wc -l README.md` <= 200.

**Required sections:**
1. **Overview** — 3-sentence project description.
2. **Architecture** — ASCII diagram of 4-VM lab network.
3. **Detection Scenarios** — table: Scenario | Attack | MITRE Technique | Wazuh Rule | Status.
4. **Detection Engineering Pipeline** — diagram/description of Sigma → XML → alert → IR report flow.
5. **Quick Start** — one command to run the offline demo (`uv run python tools/demo_enrich.py`).
6. **Gates** — `uv run nox -s all` and `pre-commit run --all-files`.
7. **Evidence** — links to `evidence/` result files and IR reports in `docs/`.

**Test Plan**
- Manual review: clone fresh, run Quick Start command, verify all links.

**DoD checklist**
- [ ] all 7 sections present
- [ ] <= 200 lines
- [ ] all links resolve
- [ ] CI badge correct
- [ ] Quick Start command runs offline

**Verification commands**
- `wc -l README.md`
- `uv run python tools/demo_enrich.py`
