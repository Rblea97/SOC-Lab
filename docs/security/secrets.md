# Secrets handling

This repository is intended to be **public**. Treat anything committed here as disclosed.

## Rules

- **Never commit secrets**: passwords, API keys, private keys, tokens, `.pfx` certs, kubeconfigs, etc.
- Use environment variables and local-only files.
- Prefer **example** configuration files committed to the repo (e.g., `.env.example`, `config.example.yml`) and keep real values out-of-tree.

## Local development pattern

- Put local secrets in `.env` (ignored by git).
- Keep a `.env.example` with safe placeholders.

Example:

```bash
cp .env.example .env
# edit .env locally
```

## Automated checks

- CI runs **gitleaks** on every push/PR.
- Local development uses **pre-commit** (recommended):

```bash
python -m pip install pre-commit
pre-commit install
pre-commit run --all-files
```