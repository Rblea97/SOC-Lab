# Evidence Tracking

Use this directory to store scenario-level proof once Wazuh is active.

## Scenario Evidence Matrix

| Scenario | Folder | Alert Evidence Status |
|---|---|---|
| 01-nmap-recon | `scenario-01-nmap` | **VALIDATED** 2026-02-14 — rule 100011 fired (T1046); `result.json` PASS |
| 02-ssh-brute-force | `scenario-02-brute-force` | **VALIDATED** 2026-02-14 — rule 5763 fired (T1110.001); `result.json` PASS |
| 03-metasploit-vsftpd | `scenario-03-vsftpd` | **VALIDATED** 2026-02-14 — rule 2501 fired (T1190); `result.json` PASS |
| 04-priv-escalation | `scenario-04-priv-esc` | **VALIDATED** 2026-02-14 — rule 5402 fired (T1548); `result.json` PASS |
| 05-suspicious-file | `scenario-05-suspicious-file` | **VALIDATED** 2026-02-13 — rule 100003 fired (T1505.003); `result.json` PASS |

Capture at minimum:

1. Dashboard alert card (rule ID and level visible)
2. Raw event/log view
3. Command output from attack source
