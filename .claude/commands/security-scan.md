# /security-scan

Perform a repo security hygiene scan (no network actions).

Checklist:
- Search for secrets (tokens, passwords, private keys)
- Check `.gitignore` coverage for env files and artifacts
- Identify scripts that echo passwords or disable host key checking
- Recommend minimal-risk hardening (documentation or opt-in flags)

Output should be grouped by severity (P0/P1/P2) with evidence paths.
