# Incident Response Report

| Field | Value |
|-------|-------|
| **Incident ID** | IR-2026-002 |
| **Date** | 2026-02-14 |
| **Analyst** | Richard Blea |
| **Classification** | Credential Access — Brute Force |
| **Severity** | High |
| **Status** | Closed — No Compromise |

---

## 1. Executive Summary

On 2026-02-14 at approximately 01:11 UTC, the Wazuh SIEM detected an automated SSH brute force attack originating from internal host 192.168.10.11 targeting 192.168.10.12. The attack tool (Hydra v9.6) launched 4 parallel authentication threads using the rockyou.txt wordlist against the local `kali` account, generating 36 rule 5763 alerts over a 45-second window. No valid credentials were obtained — rule 100002 (successful authentication following failures) did not fire — and the attack terminated without achieving access. The incident was detected, analyzed, and closed with no evidence of post-exploitation activity.

---

## 2. Affected Systems

| System | IP | Role |
|--------|----|------|
| Kali Defense | 192.168.10.12 | Target host (SSH service, Wazuh agent 001) |
| Kali Attack | 192.168.10.11 | Attack source |
| Wazuh Server | 192.168.10.14 | SIEM — detection and alerting |

---

## 3. Timeline

All timestamps are UTC.

| Time (UTC) | Event |
|------------|-------|
| 01:11:42 | First failed SSH authentication attempts from 192.168.10.11 (PIDs 4175, 4190) |
| 01:11:42–49 | 8+ authentication failures across 4 parallel sessions (PIDs 4167, 4175, 4183, 4190) |
| 01:11:52 | Wazuh rule 5763 fires — brute force threshold reached (alert ID 1771031512.480793) |
| 01:11:52–ongoing | Rule 5763 fires 36 times total throughout attack duration |
| ~01:12:27 | Attack tool terminates following 45-second timeout; no successful authentication |

---

## 4. Technical Analysis

**Attack tool:** Hydra v9.6, configured with 4 threads (`-t 4`) and the rockyou.txt wordlist, targeting user `kali` on port 22/TCP.

**Detection:** Wazuh rule 5763 (*sshd: brute force trying to get access to the system. Authentication failed.*) activated after 8 failures within the rule's frequency window, subsequently firing 36 times over the course of the attack. Rule 100002 — a custom correlation rule that triggers on successful authentication following a series of failures — did not fire at any point, confirming no credentials were compromised.

**MITRE ATT&CK Mapping:**

| Tactic | Technique |
|--------|-----------|
| Credential Access | T1110.001 — Brute Force: Password Guessing |

---

## 5. Evidence

**Artifact:** `evidence/scenario-02-brute-force/result.json`

**Representative log line:**
```
Feb 14 01:11:49 kali sshd-session[4190]: Failed password for kali from 192.168.10.11 port 35268 ssh2
```

**Key alert fields:**

| Field | Value |
|-------|-------|
| Timestamp | 2026-02-14T01:11:52.526+0000 |
| Rule ID | 5763 |
| Rule Level | 10 (High) |
| Fired Times | 36 |
| Agent ID | 001 |
| Agent Name | kali |
| Source IP | 192.168.10.11 |
| Source Port | 35268 |
| Destination User | kali |
| Decoder | sshd |
| Log Source | journald |

---

## 6. Containment & Recommendations

The following actions were taken or are recommended:

1. **Block source IP** — Add 192.168.10.11 to the host firewall (`ufw deny from 192.168.10.11`) pending investigation of the source machine.
2. **Enforce key-based SSH authentication** — Disable password authentication in `/etc/ssh/sshd_config` (`PasswordAuthentication no`) on all hosts.
3. **Deploy fail2ban** — Configure automatic banning after 5 failed attempts within 10 minutes to reduce alert volume and attacker dwell time.
4. **Review authentication logs** — Audit `/var/log/auth.log` and journald on 192.168.10.12 for any successful sessions in the 30 minutes following the attack window.
5. **Check for persistence** — Inspect `~/.ssh/authorized_keys`, cron jobs, and recently modified user accounts on 192.168.10.12 as a precautionary measure.

---

## 7. Compliance Cross-Reference

| Framework | Control | Requirement |
|-----------|---------|-------------|
| NIST 800-53 | AC-7 | Unsuccessful logon attempts |
| NIST 800-53 | SI-4 | Information system monitoring |
| NIST 800-53 | AU-14 | Session audit |
| PCI-DSS | 10.2.4 | Invalid logical access attempts |
| PCI-DSS | 10.2.5 | Use of identification and authentication mechanisms |
| PCI-DSS | 11.4 | Intrusion detection and prevention |
