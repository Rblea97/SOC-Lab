# SKILLS — SOC_LAB Stack-Specific Patterns
# Generated from: docs/PLAN.md + docs/TASKS.md
# Stack: Python 3.11 · uv · ruff · pyright · pytest · pip-audit · nox · pre-commit · GitHub Actions

---

## 1. DEPENDENCY MAP (conservative, stable)

| Tool | Min Version | Role |
|------|-------------|------|
| uv | ≥0.6 (pinned via uv.lock) | env + install + lock |
| ruff | ≥0.9 | format + lint |
| pyright | ≥1.1.390 | static type checking (canonical gate) |
| pytest | ≥7.4 | test runner |
| pip-audit | ≥2.7 | dependency vuln scan |
| nox | ≥2024.10.9 | session automation |
| pre-commit | ≥3.x | local enforcement |

Runtime deps (pyproject.toml `[project]`):
- `requests>=2.31`
- `pyyaml>=6.0`

Dev stubs (pyproject.toml `[dependency-groups].dev`):
- `types-requests>=2.31`
- `types-PyYAML>=6.0`

---

## 2. NOX SESSIONS (authoritative gate pattern)

```python
# noxfile.py — session skeleton
nox.options.default_venv_backend = "uv"
nox.options.reuse_existing_virtualenvs = True
PYTHON = "3.11"
SRC = ["tools"]
```

**Session contract** (`uv run nox -s <name>`):

| Session | Command | Mutates? |
|---------|---------|----------|
| `fmt` | `ruff format tools/` | YES (auto-fix) |
| `lint` | `ruff check tools/` | NO |
| `type` | `pyright tools/` | NO |
| `test` | `pytest tools/tests` | NO |
| `audit` | export → `pip-audit -r requirements-audit.txt` | NO |
| `all` | notify each session in order | — |

`all` uses `session.notify()`; it does **not** call subprocess — keep this pattern.

---

## 3. DETERMINISTIC AUDIT PATTERN

```bash
# Export (called inside nox audit session or pre-commit hook):
uv export --frozen --no-dev --output-file requirements-audit.txt

# Then scan:
pip-audit -r requirements-audit.txt
```

- `requirements-audit.txt` is committed and kept in sync via `uv-export` pre-commit hook.
- Do NOT run `pip-audit` against a live env; always use the exported file.

---

## 4. PRE-COMMIT HOOK ORDER (canonical)

1. `uv-lock` — ensures `uv.lock` is up-to-date
2. `uv-export` — regenerates `requirements-audit.txt` (frozen, no-dev)
3. `ruff` (--fix) — lint with autofix, scoped to `tools/` and `noxfile.py`
4. `ruff-format` — format, same scope
5. `check-yaml`, `check-toml`, `check-merge-conflict` — pre-commit-hooks
6. `end-of-file-fixer`, `trailing-whitespace` — pre-commit-hooks
7. `gitleaks` — secret detection
8. `shellcheck` — shell script safety

**To add pyright to pre-commit** (TASK-006 option):
```yaml
- repo: local
  hooks:
    - id: pyright
      name: pyright
      language: system
      entry: uv run pyright tools
      pass_filenames: false
      types: [python]
```
Alternatively call `uv run nox -s type` as entry to keep single source of truth.

---

## 5. GITIGNORE REQUIRED ENTRIES (TASK-001)

```gitignore
# Python artifacts
.venv/
__pycache__/
*.py[cod]
*.pyo

# Tool caches
.pytest_cache/
.ruff_cache/
.mypy_cache/
.pyright/

# Distribution / build
*.egg-info/
dist/
build/
```

Verification: `git ls-files | rg '(^\.venv/|__pycache__|\.pytest_cache|\.ruff_cache|\.mypy_cache|\.pyc$)'`
should return empty.

---

## 6. PYRIGHT CONFIG (canonical, already in pyproject.toml)

```toml
[tool.pyright]
pythonVersion = "3.11"
include = ["tools"]
typeCheckingMode = "standard"
reportMissingTypeStubs = "none"
```

- `typeCheckingMode = "standard"` is the project default; do not escalate to `strict` without team sign-off.
- `reportMissingTypeStubs = "none"` suppresses noise for third-party libs lacking stubs.
- mypy is **not** a DoD gate; remove from any gating hooks if found.

---

## 7. RUFF CONFIG (canonical, already in pyproject.toml)

```toml
[tool.ruff]
src = ["tools"]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "N", "UP", "B"]

[tool.ruff.format]
quote-style = "double"
```

Rule set rationale:
- `E/W` — pycodestyle errors/warnings
- `F` — pyflakes (unused imports, undefined names)
- `I` — isort (import order)
- `N` — pep8 naming
- `UP` — pyupgrade (modernize syntax)
- `B` — flake8-bugbear (likely bugs)

---

## 8. CI PATTERN (TASK-007 target)

```yaml
# .github/workflows/ci.yml — minimal canonical form
- name: Install uv
  uses: astral-sh/setup-uv@v5

- name: Run all gates
  run: uv run nox -s all
```

- No `.venv` activation in CI — uv manages the env.
- No `make` calls — nox is the single automation source.
- No pip cache config; prefer uv's own caching or omit initially.

---

## 9. FORBIDDEN PATTERNS

| Pattern | Why Forbidden |
|---------|---------------|
| `black` / `isort` / `flake8` alongside `ruff` | redundant; ruff covers all three |
| `mypy` as a DoD gate | replaced by pyright |
| `pip install` in CI without uv | breaks determinism |
| `. .venv/bin/activate` in CI | fragile; uv handles envs |
| `make verify` or `make bootstrap` in CI | two sources of truth |
| `logging` any secret/token/key | security violation |
| bare `except:` | silent failure |
| `# type: ignore` without inline comment | unexplained suppression |
| `--no-verify` to skip pre-commit | "fix by disabling the gate" |
| `git rm -rf .venv` without checking `git ls-files` first | destructive without confirmation |

---

## 10. SAFE DEFAULTS

- All external inputs (CLI args, env vars, file reads, network responses) must be validated at boundaries.
- Use `pathlib.Path` over `os.path` for file operations.
- Prefer explicit `subprocess.run([...], check=True)` over shell-interpolated strings.
- Never construct shell commands via f-string concatenation (command injection risk).
- Tests live in `tools/tests/`; use `PYTHONPATH=tools` when running pytest outside nox.

---

## 11. DEFINITION OF DONE (per task)

```
pre-commit run --all-files   # local enforcement passes
uv run nox -s all            # all gates green
CI green on PR               # remote parity confirmed
.claude.md current           # if commands/layout changed
```
