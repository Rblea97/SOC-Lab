# Security Policy

## Scope
This repository documents a **home SOC lab**. It may reference intentionally vulnerable systems (e.g., Metasploitable) as **external testbed assets**.

- Do **not** deploy vulnerable VMs on the public internet.
- Run the lab only on an isolated host-only / private network.
- Do not commit secrets (passwords, API keys, private IP ranges tied to real environments, etc.).

## Reporting
If you discover a security issue in this repository (e.g., accidentally committed secrets, unsafe defaults in scripts, or documentation that encourages insecure deployment), open a GitHub Issue with:

- A description of the issue
- File path(s)
- Suggested fix (if known)

Do **not** include real credentials in issues.
