# Claude Code — SOC_LAB Contract (MPS Parity)

## Purpose (read once)
This repo must be kept MPS-compliant: one source of truth for gates, deterministic security checks, and minimal noise.
Operate task-by-task. No drive-by refactors. Stop after completing the current task.

## Repo map (top-level)
- `.claude/commands/` — extended command library (optional deep dives)
- `docs/` — runbooks, architecture, scenarios, reports
- `evidence/` — scenario outputs (keep structure stable)
- `scripts/` — bash automation
- `tools/` — Python tooling + tests (primary Python scope)
- `testbed/` — environment/setup notes + templates
- `wazuh-config/` — Wazuh configs
- `.github/workflows/` — CI

## Non-negotiable rules
- Never add secrets. `.env` is local-only; `.env.example` is safe template.
- Never commit `.venv/` or caches (`__pycache__`, `.pytest_cache`, `.ruff_cache`, `.mypy_cache`, `*.pyc`).
- Keep diffs small (<=150 LOC net per task unless explicitly allowed).
- No structural changes without an ADR + regenerated TASKS.

## Canonical quality gates (source of truth; run from repo root)
Run everything:
- `uv run nox -s all`

Individual:
- `uv run nox -s fmt`
- `uv run nox -s lint`
- `uv run nox -s type`
- `uv run nox -s test`
- `uv run nox -s audit`

Deterministic audit export (invoked by `audit`):
- `uv export --frozen --no-dev --output-file requirements-audit.txt`

Pre-commit:
- `pre-commit run --all-files`

## Edit boundaries
- Prefer: root automation files (`noxfile.py`), `.pre-commit-config.yaml`, `.github/workflows/*`, docs.
- Only edit `tools/*.py` if a task explicitly requires it.
- Avoid changing `scripts/` and `wazuh-config/` unless compliance/security requires it.

## Working protocol
1. Read `docs/TASKS.md` and select exactly one TASK.
2. Obey that task’s allowed/forbidden file boundaries.
3. Make minimal edits to satisfy acceptance criteria.
4. Provide verification commands and STOP.

## Where to look for deeper workflows
- `.claude/commands/repo-map.md`
- `.claude/commands/verify.md`
- `.claude/commands/security-scan.md`
- `.claude/commands/review-pr.md`
