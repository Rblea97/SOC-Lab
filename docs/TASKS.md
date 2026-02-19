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

---

# Phase 3 — Portfolio Completion

> Prerequisite: TASK-001 through TASK-012 complete (Phases 1 and 2 done, all tests green).
> No new scenarios, no live API integration. See SPECS.md Phase 3 for goals and ACs.

---

## TASK-020 — Update planning docs + rename CLAUDE.md (do first)

**Scope**
- `git mv .claude.md CLAUDE.md` — fixes Claude Code auto-loading (hidden lowercase file was not being loaded).
- Append Phase 3 section to `docs/TASKS.md` (this file).
- Append Phase 3 section to `docs/SPECS.md`.
- Update `docs/CURRENT_STATE.md`: Phase 2 status → committed; add Phase 3 section with status PLANNED.
- Fix `docs/adr/ADR-0002-*.md` status line: `Proposed` → `Accepted` (inconsistency with CURRENT_STATE.md).

**Files allowed to change**
- `CLAUDE.md` (renamed from `.claude.md`)
- `docs/TASKS.md`
- `docs/SPECS.md`
- `docs/CURRENT_STATE.md`
- `docs/adr/ADR-0002-detection-engineering-pipeline-phase-2.md`

**Forbidden changes**
- No Python source changes
- No CI changes

**Acceptance Criteria**
- `ls CLAUDE.md` exits 0; `ls .claude.md` fails
- `grep "Phase 3" docs/TASKS.md` → match
- `grep "Phase 3" docs/SPECS.md` → match
- `grep "PLANNED" docs/CURRENT_STATE.md` → match
- `grep "^Accepted" docs/adr/ADR-0002-*.md` → match

**DoD checklist**
- [ ] `.claude.md` renamed to `CLAUDE.md`
- [ ] Phase 3 section in TASKS.md
- [ ] Phase 3 section in SPECS.md
- [ ] Phase 3 section in CURRENT_STATE.md with status PLANNED
- [ ] ADR-0002 status reads Accepted
- [ ] `uv run nox -s all` green (no Python touched)

**Verification commands**
- `ls CLAUDE.md && echo "OK: renamed" || echo "FAIL: CLAUDE.md missing"`
- `grep "Phase 3" docs/TASKS.md docs/SPECS.md docs/CURRENT_STATE.md`
- `uv run nox -s all`

---

## TASK-013 — Write IR report for scenario 01 (Nmap Recon) as IR-2026-001

**Scope**
- Create `docs/ir-report-nmap-recon.md` following the 7-section template from `docs/ir-report-ssh-brute-force.md`.

**Template reference:** `docs/ir-report-ssh-brute-force.md` (IR-2026-002) — match sections exactly:
metadata header, Executive Summary, Affected Systems, UTC Timeline, Technical Analysis,
MITRE Mapping, Evidence Table, Containment + Compliance.

**Key data (from `evidence/scenario-01-nmap/result.json`):**
- Incident ID: IR-2026-001
- Rule 100011 (custom composite frequency), level 8 (High)
- MITRE: T1046 — Network Service Discovery (tactic: Discovery)
- Source: 192.168.10.11 → target MS-2 (192.168.10.13), agent 000/wazuh-server
- Trigger: 12+ invalid SSH user probes in 60s window, decoded via `sshd-stripped` (custom decoder)
- Detection timestamp: 2026-02-14T05:53:40Z, latency: 72s
- Outcome: reconnaissance only — no exploitation (rule 100002 never fired)
- Compliance refs: NIST 800-53 CA-7, SI-4 / PCI-DSS 11.4, 10.6.1

**Files allowed to change**
- `docs/ir-report-nmap-recon.md` (new)

**Forbidden changes**
- No Python changes; no CI changes; no IPs outside 192.168.10.x range

**Acceptance Criteria**
- File exists with all 7 sections
- Incident ID is IR-2026-001
- All evidence references point to `evidence/scenario-01-nmap/result.json`
- MITRE table contains T1046
- `uv run nox -s all` stays green

**DoD checklist**
- [ ] `docs/ir-report-nmap-recon.md` exists
- [ ] IR-2026-001 present
- [ ] T1046 present
- [ ] Rule 100011 referenced
- [ ] `evidence/scenario-01-nmap` referenced
- [ ] `uv run nox -s all` green

**Verification commands**
- `grep "IR-2026-001\|T1046\|100011\|scenario-01-nmap" docs/ir-report-nmap-recon.md`
- `uv run nox -s all`

---

## TASK-014 — Write IR report for scenario 03 (vsftpd Exploit) as IR-2026-003

**Scope**
- Create `docs/ir-report-vsftpd-exploit.md` following the 7-section template.

**Key data (from `evidence/scenario-03-vsftpd/result.json`):**
- Incident ID: IR-2026-003
- Rule 2501 (built-in syslog auth failure), level 5 (Medium)
- MITRE: T1190 — Exploit Public-Facing Application (tactic: Initial Access)
- Target: MS-2, agent 000/wazuh-server, timestamp: 2026-02-14T05:43:59Z, latency: 192s (longest)
- Alert log: `pam_unix(login:auth): authentication failure` — indirect detection of CVE-2011-2523 (vsftpd 2.3.4 backdoor)
- Compliance: PCI-DSS 10.2.4/10.2.5, NIST AU.14/AC.7, HIPAA 164.312.b, GDPR IV_35.7.d

**Analysis note:** Detection was indirect (PAM auth failure from backdoor shell's local login attempt on port 6200).
Report must explain this detection gap and recommend a dedicated network-layer rule for port 6200/TCP activity.
Built-in rule 2501 at level 5 may not trigger escalation automatically — document this.

**Files allowed to change**
- `docs/ir-report-vsftpd-exploit.md` (new)

**Forbidden changes**
- No Python changes; no CI changes

**Acceptance Criteria**
- File exists with all 7 sections; IR-2026-003; T1190; evidence path referenced
- `uv run nox -s all` stays green

**DoD checklist**
- [ ] `docs/ir-report-vsftpd-exploit.md` exists
- [ ] IR-2026-003 present
- [ ] T1190 present
- [ ] Rule 2501 referenced
- [ ] 192s latency and detection gap analysis included
- [ ] `uv run nox -s all` green

**Verification commands**
- `grep "IR-2026-003\|T1190\|2501\|scenario-03-vsftpd" docs/ir-report-vsftpd-exploit.md`
- `uv run nox -s all`

---

## TASK-015 — Write IR report for scenario 04 (Privilege Escalation) as IR-2026-004

**Scope**
- Create `docs/ir-report-priv-escalation.md` following the 7-section template.

**Key data (from `evidence/scenario-04-priv-esc/result.json`):**
- Incident ID: IR-2026-004
- Rule 5402 (built-in "Successful sudo to ROOT"), level 3 (Low)
- MITRE: T1548.003 — Sudo and Sudo Caching (tactics: Privilege Escalation, Defense Evasion)
- Agent: 001/kali/192.168.10.12, timestamp: 2026-02-14T06:24:01Z, latency: 7s (fastest)
- firedtimes: 26 (repeated sudo executions during scenario)
- Command: `sudo /usr/bin/systemctl start ssh` by user `kali` from PWD `/`
- Compliance: NIST AC.7/AC.6, PCI-DSS 10.2.5/10.2.2, HIPAA 164.312.b

**Analysis note:** Level 3 may be treated as informational in production. Report must explain contextual
significance: enabling SSH after gaining access is a persistence indicator. Recommend correlation rule
or level-tuning.

**Files allowed to change**
- `docs/ir-report-priv-escalation.md` (new)

**Forbidden changes**
- No Python changes; no CI changes

**Acceptance Criteria**
- File exists with all 7 sections; IR-2026-004; T1548.003; evidence path referenced
- Analysis explains why low-severity warrants attention
- `uv run nox -s all` stays green

**DoD checklist**
- [ ] `docs/ir-report-priv-escalation.md` exists
- [ ] IR-2026-004 present
- [ ] T1548 present
- [ ] Rule 5402 referenced
- [ ] Low-severity context analysis included
- [ ] `uv run nox -s all` green

**Verification commands**
- `grep "IR-2026-004\|T1548\|5402\|scenario-04-priv-esc" docs/ir-report-priv-escalation.md`
- `uv run nox -s all`

---

## TASK-016 — Write IR report for scenario 05 (Suspicious File) as IR-2026-005

**Scope**
- Create `docs/ir-report-suspicious-file.md` following the 7-section template.

**Key data (from `evidence/scenario-05-suspicious-file/result.json`):**
- Incident ID: IR-2026-005
- Rule 100003 (custom syscheck FIM rule), level 10 (High)
- MITRE: T1505.003 — Web Shell (tactic: Persistence)
- Agent: 001/kali/192.168.10.12, file: `/tmp/reverse_shell.php`, timestamp: 2026-02-14T00:50:44Z, latency: 71s
- File metadata: 31 bytes, permissions 664, uid/gid 1000/1000, inode 25
- **SHA256:** `ac5b099b97c6536012276c5e61c50d4f4fe6fd606bd861c5c15f769153452e68`
- **SHA1:** `f16d1122d450c92e85174c1984c70c2d6e4bdeb3`
- **MD5:** `fc023fcacb27a7ad72d605c4e300b389`
- Detection mechanism: syscheck realtime FIM (NOT log-based — distinguish clearly in report)

**Analysis note:** Include a dedicated artifact hash table (MD5/SHA1/SHA256) — standard IR practice.
Containment: collect before deletion, submit hashes to VirusTotal, check cron + `authorized_keys`,
check for network connections on 80/443.

**Files allowed to change**
- `docs/ir-report-suspicious-file.md` (new)

**Forbidden changes**
- No Python changes; no CI changes

**Acceptance Criteria**
- File exists with all 7 sections; IR-2026-005; T1505.003; SHA256 hash present; evidence path referenced
- `uv run nox -s all` stays green

**DoD checklist**
- [ ] `docs/ir-report-suspicious-file.md` exists
- [ ] IR-2026-005 present
- [ ] T1505.003 present
- [ ] Rule 100003 referenced
- [ ] SHA256 `ac5b099b` present in evidence table
- [ ] `uv run nox -s all` green

**Verification commands**
- `grep "IR-2026-005\|T1505.003\|100003\|ac5b099b" docs/ir-report-suspicious-file.md`
- `uv run nox -s all`

---

## TASK-017 — Update `docs/portfolio-writeup.md` (fix stale tooling references)

**Scope**
- Remove all references to `make bootstrap`, `make demo`, `make verify` — these commands no longer exist.
- Update test count from 26 → 50 (or current count at time of implementation).
- Update type checker reference from `mypy`/`MyPy` → `pyright`.
- List all 4 committed Python tools (sigma_convert, enrich_alerts, demo_enrich, report); add pipeline_demo.py if TASK-019 is done.
- Add "Detection Engineering Pipeline" section showing the Sigma→convert→enrich→report flow.
- Reference the IR report suite (IR-2026-001 through IR-2026-005) in Skills Demonstrated.
- Reference `docs/attack-coverage.json` (ATT&CK Navigator layer) if TASK-018 is done.

**Files allowed to change**
- `docs/portfolio-writeup.md`

**Forbidden changes**
- No Python changes; no CI changes; do not remove Future Work section

**Acceptance Criteria**
- Zero occurrences of: `make bootstrap`, `make demo`, `make verify`
- `uv run nox -s all` appears as the canonical gate command
- `pyright` named as type checker
- Test count updated
- Pipeline section exists
- `uv run nox -s all` stays green

**DoD checklist**
- [ ] `grep -c "make bootstrap\|make demo\|make verify" docs/portfolio-writeup.md` returns 0
- [ ] `grep "uv run nox" docs/portfolio-writeup.md` → match
- [ ] `grep "pyright\|Pyright" docs/portfolio-writeup.md` → match
- [ ] Test count accurate
- [ ] Pipeline section present
- [ ] `uv run nox -s all` green

**Verification commands**
- `grep -c "make bootstrap\|make demo\|make verify" docs/portfolio-writeup.md`
- `grep "uv run nox\|pyright" docs/portfolio-writeup.md`
- `uv run nox -s all`

---

## TASK-018 — Create `docs/attack-coverage.json` (MITRE ATT&CK Navigator layer)

**Scope**
- Create a Navigator 4.x layer file covering all 5 detected techniques.
- This is a pure JSON artifact — no Python source changes, no new nox session.

**Format:** ATT&CK Navigator 4.x, domain `enterprise-attack`, ATT&CK version 15, Navigator version 4.9.

**Techniques to include:**

| techniqueID | tactic | color | comment |
|---|---|---|---|
| T1046 | discovery | #ff6666 | Scenario 01: Nmap SSH probe → rule 100011 (custom, 72s latency) |
| T1110.001 | credential-access | #ff6666 | Scenario 02: Hydra brute force → rules 5763/100002 (built-in, 126s) |
| T1190 | initial-access | #ff6666 | Scenario 03: vsftpd CVE-2011-2523 → rule 2501 (built-in, 192s) |
| T1548.003 | privilege-escalation | #ff9900 | Scenario 04: sudo abuse → rule 5402 (built-in, level 3, 7s) |
| T1505.003 | persistence | #ff6666 | Scenario 05: PHP web shell in /tmp → rule 100003 (custom FIM, 71s) |

T1548.003 uses #ff9900 (orange) to reflect its lower rule level (3 vs 10 for others) — honest visual representation.

**Files allowed to change**
- `docs/attack-coverage.json` (new)

**Forbidden changes**
- No Python changes; no nox config changes; no CI changes

**Acceptance Criteria**
- `python -m json.tool docs/attack-coverage.json` exits 0 (valid JSON)
- All 5 technique IDs present; comment fields reference scenario numbers
- `uv run nox -s all` stays green (no Python touched)

**DoD checklist**
- [ ] `docs/attack-coverage.json` exists
- [ ] `python -m json.tool docs/attack-coverage.json` exits 0
- [ ] `grep -c '"techniqueID"' docs/attack-coverage.json` returns 5
- [ ] All 5 MITRE IDs present
- [ ] `uv run nox -s all` green

**Verification commands**
- `python -m json.tool docs/attack-coverage.json`
- `grep -c '"techniqueID"' docs/attack-coverage.json`
- `uv run nox -s all`

---

## TASK-019 — Create `tools/pipeline_demo.py` (end-to-end pipeline demonstration)

**Scope**
- Create `tools/pipeline_demo.py`: a single runnable command that chains all 3 pipeline stages with no env vars.
- Create `tools/tests/test_pipeline_demo.py` with 3 tests (50 → 53 total).

**Design:**
Command: `uv run python tools/pipeline_demo.py`
Zero env vars, zero network calls. Imports only from existing modules: `sigma_convert`, `enrich_alerts`, `report`, stdlib.

**Three stages (print a clear header before each):**

1. **Stage 1 — Sigma → Wazuh XML:** `parse_sigma_rule()` on `tools/sigma/01-nmap-recon.yml` (path relative
   to `Path(__file__).parent`), then `convert_to_wazuh_xml(base_id=100011)`, then `validate_wazuh_rule()`.
   Print rule title, MITRE ID extracted, first 3 lines of XML.

2. **Stage 2 — Alert enrichment:** Load `tools/fixtures/sample_enriched.json`. Construct one `Alert`
   from the first record (T1046 entry). Call `enrich_alert()`. Print risk label and MITRE description.

3. **Stage 3 — Report generation:** Call `generate_report()` with all fixture records.
   Print first 15 lines of generated Markdown.

**End summary block:**
```
Pipeline demo complete.
Stage 1: Sigma → Wazuh XML  [PASS]
Stage 2: Alert enrichment    [PASS]
Stage 3: Report generation   [PASS]
```

**Inline comment required at top of file:**
`# Offline-only by design — see ADR-0002. No new architecture.`
(ADR-0003 is NOT needed — pipeline_demo.py wraps existing APIs; offline constraint is from ADR-0002.)

**Tests in `tools/tests/test_pipeline_demo.py`:**
1. `test_pipeline_demo_runs` — calls `main()`, asserts exit code 0
2. `test_pipeline_demo_stage1_produces_xml` — stage 1 logic, asserts XML contains `<rule>`
3. `test_pipeline_demo_stage3_contains_summary` — stage 3 output contains `## Summary`

**Files allowed to change**
- `tools/pipeline_demo.py` (new, ~90–110 LOC)
- `tools/tests/test_pipeline_demo.py` (new, ~40–55 LOC)

**Exception:** ~150 net LOC across both files (slightly over C-002 guideline). Exception documented here;
splitting would create an untested-script PR. Mirrors TASK-009 exception precedent.

**Forbidden changes**
- No changes to `sigma_convert.py`, `enrich_alerts.py`, or `report.py`
- No `import requests`, no `os.environ` reads, no network calls
- No new dependencies to `pyproject.toml`

**Acceptance Criteria**
- `uv run python tools/pipeline_demo.py` exits 0 with no env vars, prints 3 `[PASS]` lines
- `uv run nox -s test` passes (53 tests green)
- `uv run nox -s fmt lint type` passes (ruff + pyright clean)

**DoD checklist**
- [ ] `tools/pipeline_demo.py` exists
- [ ] `tools/tests/test_pipeline_demo.py` exists with 3 tests
- [ ] `uv run python tools/pipeline_demo.py` → exits 0, 3 [PASS] lines
- [ ] `uv run nox -s test` → 53 tests green
- [ ] `uv run nox -s fmt lint type` → clean
- [ ] No env vars, no network calls, no new deps

**Verification commands**
- `uv run python tools/pipeline_demo.py`
- `uv run python tools/pipeline_demo.py | grep "\[PASS\]" | wc -l`
- `uv run nox -s test`
- `uv run nox -s fmt lint type`
