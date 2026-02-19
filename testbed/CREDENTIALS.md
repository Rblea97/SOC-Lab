# Lab credentials (secure storage)

**Do not put real passwords in the repo.** Use a local file that is gitignored.

## Where to store your login info

1. **Copy the example file** (no real values):
   ```bash
   cp testbed/credentials.env.example testbed/credentials.env
   ```

2. **Edit `testbed/credentials.env`** on your machine and fill in your real values.
   This file is listed in `.gitignore` and will **not** be committed.

3. **Optional:** Use a password manager and store the same info there; keep `credentials.env` only for scripts that need to read it (e.g. `source testbed/credentials.env` before running automation scripts).

## What goes where

| Purpose | Variable / location | Used by |
|--------|---------------------|--------|
| Wazuh dashboard (browser) | Store in password manager or in `credentials.env` as `WAZUH_DASHBOARD_USER` / `WAZUH_DASHBOARD_PASS` | You (manual login) |
| Wazuh API (scripts) | `WAZUH_API_USER` / `WAZUH_API_PASSWORD` in `credentials.env` | `tools/enrich_alerts.py` |
| SSH to Wazuh VM | `WAZUH_SSH_PASS` in `credentials.env` (or use SSH keys) | `scripts/02-deploy-wazuh-rules.sh` |
| Wazuh VM console (analyst) | Store in password manager or in `credentials.env` as `WAZUH_VM_USER` / `WAZUH_VM_PASS` | You (console/SSH login) |
| Kali VMs | Defaults in docs; store in password manager if you change them | You, `scripts/01-...` |
| MS-2 | Defaults in docs; store in password manager if you change them | You, `scripts/10-run-scenario-03.sh` |

## Loading credentials in scripts

If you use `credentials.env`:

```bash
# In the repo root, before running scripts that need Wazuh SSH or API:
set -a
source testbed/credentials.env
set +a
./scripts/02-deploy-wazuh-rules.sh
```

Or export individual variables:

```bash
export WAZUH_SSH_PASS='your_analyst_password'
./scripts/02-deploy-wazuh-rules.sh
```

## Files

- **`testbed/credentials.env.example`** – Template with variable names only (safe to commit).
- **`testbed/credentials.env`** – Your real values; **gitignored**; create from the example and never commit.
