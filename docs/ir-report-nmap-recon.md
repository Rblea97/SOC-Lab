# Incident Response Report

| Field | Value |
|-------|-------|
| **Incident ID** | IR-2026-001 |
| **Date** | 2026-02-14 |
| **Analyst** | Richard Blea |
| **Classification** | Discovery — Network Service Discovery |
| **Severity** | High |
| **Status** | Closed — No Compromise |

---

## 1. Executive Summary

On 2026-02-14 at approximately 05:52 UTC, the Wazuh SIEM detected a network reconnaissance sweep originating from internal host 192.168.10.11 targeting 192.168.10.13 (MS-2). Nmap probed multiple SSH service ports, generating 12+ invalid user probes against the `sshd` service within a 60-second window. Custom composite frequency rule 100011 fired 72 seconds after the first probe, correctly classifying the activity as a network service discovery attempt (MITRE T1046). No exploitation followed — rule 100002 (successful authentication after failures) did not fire — and the incident was closed with no evidence of access or lateral movement.

---

## 2. Affected Systems

| System | IP | Role |
|--------|----|------|
| Kali Attack | 192.168.10.11 | Attack source (Nmap scan origin) |
| MS-2 | 192.168.10.13 | Target host (SSH service) |
| Wazuh Server | 192.168.10.14 | SIEM — detection and alerting (agent 000) |

---

## 3. Timeline

All timestamps are UTC.

| Time (UTC) | Event |
|------------|-------|
| ~05:52:28 | Nmap begins probing SSH port 22 on 192.168.10.13; first invalid user `scanuser` probes recorded |
| 05:52:28–05:53:38 | 12+ invalid SSH user probes across multiple PIDs (5023–5033) within 60s window |
| 05:53:40 | Wazuh rule 100011 fires — frequency threshold reached (alert ID 1771048420.942778) |
| 05:53:40 | Detection latency: 72s from first probe |
| Post-detection | No rule 100002 fire; no exploitation observed |

---

## 4. Technical Analysis

**Attack tool:** Nmap, configured to probe SSH port 22/TCP on 192.168.10.13, using invalid username `scanuser` across multiple parallel connections (PIDs 5023, 5025, 5027, 5029, 5031, 5033).

**Detection:** Custom composite frequency rule 100011 (*Possible network scan: multiple SSH invalid user attempts from single source in 60s (T1046)*) activated after 12 invalid user probes within a 60-second window. The alert was decoded via the custom `sshd-stripped` decoder (parent decoder) rather than the standard `sshd` decoder, enabling accurate extraction of source IP and username from stripped log formats. Rule 100002 — which correlates successful authentication following a series of failures — did not fire at any point, confirming the scan did not progress to exploitation.

**Detection mechanism:** Log-based frequency correlation (syslog), not network-layer IDS. Detection requires the target host to log SSH connection attempts to the Wazuh agent.

**MITRE ATT&CK Mapping:**

| Tactic | Technique |
|--------|-----------|
| Discovery | T1046 — Network Service Discovery |

---

## 5. Evidence

**Artifact:** `evidence/scenario-01-nmap/result.json`

**Representative log lines (previous_output from alert):**
```
sshd[5033]: Invalid user scanuser from 192.168.10.11
sshd[5031]: Failed none for invalid user scanuser from 192.168.10.11 port 50464 ssh2
sshd[5029]: Invalid user scanuser from 192.168.10.11
sshd[5025]: Failed none for invalid user scanuser from 192.168.10.11 port 50434 ssh2
```

**Key alert fields:**

| Field | Value |
|-------|-------|
| Timestamp | 2026-02-14T05:53:40.068+0000 |
| Rule ID | 100011 |
| Rule Level | 8 (High) |
| Frequency Threshold | 12 probes / 60s |
| Fired Times | 1 |
| Agent ID | 000 |
| Agent Name | wazuh-server |
| Source IP | 192.168.10.11 |
| Source User | scanuser |
| Target Location | 192.168.10.13 |
| Decoder | sshd-stripped |
| Detection Latency | 72 seconds |

---

## 6. Containment & Recommendations

1. **Block scan source** — Add 192.168.10.11 to host firewall (`ufw deny from 192.168.10.11`) and review whether this host is authorized to perform network scans.
2. **Add network-layer detection** — Supplement log-based rule 100011 with a Suricata or Snort rule triggering on port-sweep patterns to reduce reliance on sshd logging being enabled on all targets.
3. **Restrict SSH exposure** — Limit SSH access to known management IPs via `sshd_config` `AllowUsers` or firewall ACLs to reduce the attack surface for future scanning.
4. **Tune rule 100011 threshold** — Evaluate whether the 12-probe / 60s threshold captures slow scans (e.g., `-T2` Nmap timing); consider a secondary low-frequency rule at 5 probes / 120s.
5. **Confirm rule 100002 absence** — Verify logs from 192.168.10.13 in the 15 minutes following detection to confirm no post-scan authentication succeeded.

---

## 7. Compliance Cross-Reference

| Framework | Control | Requirement |
|-----------|---------|-------------|
| NIST 800-53 | CA-7 | Continuous monitoring |
| NIST 800-53 | SI-4 | Information system monitoring |
| PCI-DSS | 11.4 | Intrusion detection and prevention |
| PCI-DSS | 10.6.1 | Review and analyze security event logs |
