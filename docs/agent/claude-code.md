# Claude Code Workflow

This repo is optimized for **Claude Code** style CLI workflows via:

- `CLAUDE.md` project guide (guardrails + deterministic commands)
- `Makefile` task entrypoints (single interface for verification)
- `.claude/commands/` reusable routines

## Recommended loop

1. Create a small PR scope (1 feature or 1 fix).
2. Implement changes.
3. Run `make verify`.
4. Run `pre-commit run --all-files` (if enabled).
4. Update docs (`README.md`/`docs/`) and add verification steps.

CI runs the same verification gate (`make verify`) and will block regressions.

## Safety defaults

- Treat the VM testbed as **external**. Do not assume VM images exist.
- Any new automation must be opt-in and environment-driven.
- Never store credentials in the repo; use `testbed/credentials.env.example` as the template.
