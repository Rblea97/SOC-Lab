# ADR-0002: Detection Engineering Pipeline as Phase 2 Portfolio Differentiator

## Status
Accepted

## Context
After Phase 1 (MPS alignment, TASK-001–007), the lab has:
- 5 validated attack scenarios with custom Wazuh detection rules.
- Two Python tools: `sigma_convert.py` (Sigma YAML → Wazuh XML) and `enrich_alerts.py`
  (Wazuh API → enriched alert triage report).
- A clean MPS automation pipeline (uv + nox + pre-commit + CI).

However, the project is not yet competitive as a portfolio artifact because:
1. `sigma_convert.py` has no Sigma source files as input — it converts nothing.
2. `enrich_alerts.py` requires a live Wazuh API; no offline demo or fixture path exists.
3. `README.md` was removed during MPS transition; the project has no public face.
4. A recruiter or interviewer cannot evaluate the project's value in under 5 minutes.

The architectural question: what is the highest-impact next capability for portfolio differentiation?

## Decision
Implement a **Detection Engineering Pipeline** that connects the existing tools into a
coherent, end-to-end, testable story:

```
Sigma YAML → sigma_convert.py → Wazuh XML
     ↓
Attack scenario (existing scripts)
     ↓
Wazuh alert → enrich_alerts.py → enriched JSON
     ↓
report.py → Markdown IR summary
```

All pipeline stages run offline via fixtures, testable with pytest, and documented in a
rebuilt README.md with real command output.

## Alternatives Considered

### Branch B — Threat Intelligence Integration (PRUNED)
**Pattern:** Add a curated IoC/TI data store; enrich alerts with intel context; export
ATT&CK Navigator JSON profiles.

**Why pruned:**
- TI enrichment is additive but requires the detection pipeline output schema to be defined first.
- Adds external data dependency risk (stale IoC lists, format churn).
- Premature without a stable `enrich_alerts.py` JSON output contract.
- Can be implemented as Phase 3 after the pipeline schema is stable.

### Branch C — Portfolio Showcase Layer First (PRUNED)
**Pattern:** Rebuild README.md first; organize evidence gallery; add Jupyter notebook demo;
write case study document.

**Why pruned:**
- A showcase layer that documents capabilities before they exist produces aspirational copy,
  not demonstration.
- `demo_enrich.py` currently requires a live Wazuh API; the README's "Quick Start" would
  fail for any evaluator cloning the repo.
- The showcase layer becomes authentic only after the pipeline runs offline and produces
  real output. TASK-012 (README rebuild) is the final Phase 2 task, not the first.

## Consequences

### Positive
- Demonstrates detection engineering — the highest-demand modern SOC skill — end-to-end.
- Unifies underutilized tools into a coherent story.
- Offline demo path means any evaluator can run `uv run python tools/demo_enrich.py`
  immediately after `git clone`.
- pytest coverage of the pipeline provides concrete proof of correctness.
- README built on real output is authentic and self-consistent.
- Enables Phase 3 (TI integration) by defining a stable enriched-alert JSON schema.

### Negative
- Requires modifying `enrich_alerts.py` (adding `--output` flag) which touches an
  existing tested module — risk of regression.
- Sigma YAML authoring requires knowledge of both Sigma format and the lab's log structures.
- `report.py` is a new module with no prior test infrastructure.

## Automation Implications
- `uv run nox -s test` must cover all pipeline stages.
- `tools/sigma/` becomes part of the nox `fmt`/`lint` scope if it contains any Python
  (it won't — YAML only; no change to noxfile needed).
- `tools/fixtures/` must be excluded from `gitleaks` scanning (no real credentials;
  add explicit fixture path allowlist if needed).
- CI parity: no new CI sessions needed; pipeline tests run under existing `test` session.
