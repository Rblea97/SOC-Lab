# ADR-0001: Canonicalize Gates with uv+nox; Replace make/.venv CI Path; Deterministic pip-audit

## Status
Accepted

## Context
Current CI runs `make bootstrap` / `make verify` and separately activates `.venv` to run `pip-audit`. This introduces:
- two sources of truth (Makefile vs tool configs)
- reliance on a repo-local `.venv`
- non-deterministic audit behavior (audit depends on ambient installed packages)

MPS requires automation-first gates with local/CI parity and deterministic security scanning.

## Decision
- Adopt root-level `uv + nox` as the single authoritative gate interface:
  - `uv run nox -s all` is the canonical entrypoint
  - individual sessions: fmt/lint/type/test/audit
- Switch typing gate to `pyright` as canonical; treat mypy as optional.
- Implement deterministic audit input:
  - generate `requirements-audit.txt` via frozen export
  - run `pip-audit -r requirements-audit.txt`
- Update CI to run the same `uv run nox -s all` suite (no Makefile, no `.venv` activation).

## Alternatives Considered
- Keep Makefile and wrap it with nox: rejected due to drift risk and ambiguity.
- Full project consolidation refactor: rejected due to churn exceeding PR-sized constraints.

## Consequences
### Positive
- One source of truth for gates; fewer “works locally but not in CI” failures.
- Deterministic, reproducible audit.
- Cleaner agent sessions (fewer moving parts to rediscover).

### Negative
- Requires introducing `noxfile.py` and possibly adjusting dependency/tool installation approach.
- Requires updating docs and pre-commit to match parity model.

## Automation Implications
- CI must invoke `uv run nox -s all`.
- Pre-commit mirrors key gates and blocks artifact commits.
- Any change to gate commands requires updating `.claude.md` and docs.
