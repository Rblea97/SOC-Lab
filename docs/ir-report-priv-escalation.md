# Incident Response Report

| Field | Value |
|-------|-------|
| **Incident ID** | IR-2026-004 |
| **Date** | 2026-02-14 |
| **Analyst** | Richard Blea |
| **Classification** | Privilege Escalation / Defense Evasion — Sudo and Sudo Caching |
| **Severity** | Low (contextually significant — see analysis) |
| **Status** | Closed — Isolated lab environment |

---

## 1. Executive Summary

On 2026-02-14 at approximately 06:24 UTC, Wazuh detected repeated successful `sudo` escalations to root on Kali Defense (192.168.10.12). Built-in rule 5402 (*Successful sudo to ROOT executed.*) fired 26 times over the scenario window, each triggered by user `kali` executing `sudo /usr/bin/systemctl start ssh` from the filesystem root (`PWD=/`). Detection latency was 7 seconds — the fastest in the lab. While rule 5402 is level 3 (Low/Informational) and would not trigger automated escalation in most SOC environments, the specific command context — enabling SSH service after gaining system access — is a strong persistence indicator that warrants analyst attention through correlation.

---

## 2. Affected Systems

| System | IP | Role |
|--------|----|------|
| Kali Defense | 192.168.10.12 | Host where privilege escalation occurred (Wazuh agent 001) |
| Wazuh Server | 192.168.10.14 | SIEM — detection and alerting |

---

## 3. Timeline

All timestamps are UTC.

| Time (UTC) | Event |
|------------|-------|
| 06:23:29 | User `kali` executes `sudo /usr/bin/systemctl start ssh` from PWD=/ |
| 06:24:01 | Wazuh rule 5402 fires — first sudo-to-root alert (alert ID 1771050241.1019806) |
| 06:24:01 | Detection latency: 7 seconds (fastest in lab) |
| 06:23:29–ongoing | Rule 5402 fires 26 times total (repeated sudo executions during scenario) |

---

## 4. Technical Analysis

**Observed behavior:** User `kali` executed `sudo /usr/bin/systemctl start ssh` 26 times, escalating to root each time. The working directory (`PWD=/`) is atypical for a legitimate administrative session — administrators generally operate from a home directory or specific service path. The repeated execution pattern and filesystem-root working directory suggest scripted or attacker-controlled activity.

**Why low severity warrants attention:** Rule 5402 is level 3 (Low/Informational) by default in the Wazuh ruleset. In production environments with alert escalation thresholds set at level 7+, this would generate no page or ticket. However, the combination of factors elevates contextual risk:

- **Command choice:** `systemctl start ssh` enables the SSH daemon, creating a persistent remote access vector.
- **Working directory:** `PWD=/` indicates the session likely originated from a non-interactive or post-exploitation context.
- **Repetition:** 26 firings suggest automated or scripted execution, not interactive administration.
- **Timing context:** If correlated with preceding alerts (nmap recon IR-2026-001, brute force IR-2026-002), this could represent the post-exploitation phase of an attack chain.

**Recommendation:** Correlate rule 5402 with network connection alerts on port 22 immediately following the event. A custom composite rule triggering when 5402 fires and a subsequent SSH connection is established would escalate this to a level warranting T2 review.

**MITRE ATT&CK Mapping:**

| Tactic | Technique |
|--------|-----------|
| Privilege Escalation | T1548.003 — Abuse Elevation Control Mechanism: Sudo and Sudo Caching |
| Defense Evasion | T1548.003 — Abuse Elevation Control Mechanism: Sudo and Sudo Caching |

---

## 5. Evidence

**Artifact:** `evidence/scenario-04-priv-esc/result.json`

**Full log captured:**
```
Feb 14 06:23:29 kali sudo[5992]:     kali : PWD=/ ; USER=root ; COMMAND=/usr/bin/systemctl start ssh
```

**Key alert fields:**

| Field | Value |
|-------|-------|
| Timestamp | 2026-02-14T06:24:01.694+0000 |
| Rule ID | 5402 |
| Rule Level | 3 (Low/Informational) |
| Fired Times | 26 |
| Agent ID | 001 |
| Agent Name | kali |
| Agent IP | 192.168.10.12 |
| Source User | kali |
| Destination User | root |
| PWD | / |
| Command | /usr/bin/systemctl start ssh |
| Decoder | sudo |
| Log Source | journald |
| Detection Latency | 7 seconds |

---

## 6. Containment & Recommendations

1. **Audit sudo configuration** — Review `/etc/sudoers` on 192.168.10.12 to confirm `kali` requires password authentication for all sudo commands. Passwordless sudo (`NOPASSWD`) entries are a high-risk misconfiguration.
2. **Create correlation rule** — Author a custom Wazuh rule that fires at level 10 when rule 5402 is followed within 60 seconds by a new SSH session (rule 5715 or similar), creating an automatic escalation path.
3. **Tune rule 5402 level** — Consider raising 5402 to level 5–6 in environments where sudo-to-root is uncommon, ensuring the event at minimum creates a low-priority ticket.
4. **Check for persistence** — Inspect `~/.ssh/authorized_keys`, `/etc/cron.d/`, and recently modified files under `/etc/` on 192.168.10.12 for attacker-planted persistence mechanisms.
5. **Verify SSH listener** — Confirm that `sshd` was not already running before the sudo execution, and whether any unauthorized connections were made on port 22 after 06:24 UTC.

---

## 7. Compliance Cross-Reference

| Framework | Control | Requirement |
|-----------|---------|-------------|
| NIST 800-53 | AC-7 | Unsuccessful logon attempts |
| NIST 800-53 | AC-6 | Least privilege |
| PCI-DSS | 10.2.5 | Use of identification and authentication mechanisms |
| PCI-DSS | 10.2.2 | Actions by individuals with root or administrative privileges |
| HIPAA | 164.312.b | Audit controls |
