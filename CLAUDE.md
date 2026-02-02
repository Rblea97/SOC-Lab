# Claude Code Project Guide (SOC Home Lab)

This repository is designed to be **agent-friendly**: deterministic commands, clear guardrails, and reproducible verification steps.

## Non-negotiables

- **No breaking changes** unless explicitly requested.
- **Security-first**: never introduce secrets, unsafe defaults, or broaden network exposure.
- **Evidence-based**: if you claim something works, point to a script, config, or evidence file.
- **Prefer additive changes**: docs/config/tooling over refactoring core automation.

## Repo map (high level)

- `README.md` — 5-minute skim; topology + status
- `spec.md` — design doc / requirements + MVP scope
- `scripts/` — VM orchestration + scenarios (VirtualBox guestcontrol)
- `testbed/` — runbooks, baseline gates, credentials template
- `wazuh-config/` — SIEM config, rules/decoders
- `evidence/` — validation outputs per scenario
- `tools/` — Python utilities + tests (Ruff/MyPy/PyTest)
- `docs/` — diagrams and operator docs

## Default workflow (deterministic)

1. **Understand scope**
   - Read `README.md`, `spec.md`, and any referenced docs.
2. **Plan**
   - Propose the smallest PR that meets the request.
3. **Implement**
   - Keep diffs small, modular, and reviewable.
4. **Verify**
   - Run `make verify` (or the equivalent commands listed below).
5. **Document**
   - Update `README.md`/`docs/` and add verification steps.

## Commands you should use

> These are safe to run locally without needing the VM images.

### Tooling (Python)

- Bootstrap dev environment:
  - `python3 -m venv .venv`
  - `. .venv/bin/activate`
  - `pip install -U pip`
  - `pip install -e tools[dev]`

- Format + lint:
  - `cd tools && ruff format .`
  - `cd tools && ruff check .`

- Typecheck:
  - `cd tools && mypy .`

- Tests:
  - `cd tools && pytest -q`

### Repo-level verify (preferred)

- `make verify`
  - runs format check, lint, mypy, and tests for `tools/`.

## Guardrails

- **Never commit**:
  - `.env`, `credentials.env`, API keys, tokens, passwords
- **Do not**:
  - add any real exploitation content beyond what is already present for the lab
  - widen firewall rules or expose services to the public Internet
- **Prefer**:
  - placeholders (`<WAZUH_HOST>`, `<TOKEN>`) and `*.example` templates
  - `scripts/` changes to be backward compatible and opt-in via env vars

## When you touch scripts

- Keep `set -euo pipefail`.
- Avoid logging credentials.
- Parameterize via env vars; document defaults.
- Provide a **verification command** and expected output snippet.
