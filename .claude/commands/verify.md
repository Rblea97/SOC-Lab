# /verify

Run the deterministic verification gate.

Steps:
1. If `.venv/` exists: run `make verify`.
2. Else: run `make bootstrap` then `make verify`.

Report:
- commands run
- pass/fail
- if fail: minimal fix suggestions
