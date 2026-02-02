# Contributing

## Local checks
### Python tooling
```bash
make bootstrap
make verify
```

### pre-commit (recommended)

```bash
python -m pip install pre-commit
pre-commit install
pre-commit run --all-files
```

### Shell scripts
If you have `shellcheck` installed:
```bash
shellcheck scripts/*.sh scripts/**/*.sh
```

## Pull requests
- Prefer small PRs with a single purpose.
- No secrets in commits (use `testbed/credentials.env.example` templates).
- Avoid behavior-changing refactors unless clearly documented with rollback steps.
