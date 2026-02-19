# Dependency security

## CI

CI runs `pip-audit` to detect known vulnerabilities in Python dependencies.

## GitHub dependency graph (recommended)

Enable GitHub's dependency graph and **automatic dependency submission** (pip) in repository settings
to improve Dependabot alert fidelity for transitive dependencies.

- Settings → Security & analysis → **Dependency graph**
- Settings → Security & analysis → **Automatic dependency submission**

## Local usage

If you have a virtual environment created via `make bootstrap`:

```bash
. .venv/bin/activate
python -m pip install -U pip
python -m pip install pip-audit
pip-audit
```

## Remediation policy

- Prefer upgrading to a patched version.
- If a fix requires a breaking change, document the decision and mitigation in the PR.
