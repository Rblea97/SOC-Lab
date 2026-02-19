# IR Summary Report

## Summary

- **Alert count:** 5
- **Date range:** 2026-02-14T00:00:00Z — 2026-02-14T00:20:00Z
- **Risk label breakdown:**
  - critical: 1
  - high: 2
  - medium: 1
  - low: 1

## Alert Table

| Rule ID | Risk | MITRE | Timestamp | Source IP |
|---|---|---|---|---|
| 100011 | medium | T1046 | 2026-02-14T00:00:00Z | 192.0.2.10 |
| 5763 | critical | T1110.001 | 2026-02-14T00:05:00Z | 192.0.2.10 |
| 2501 | high | T1190 | 2026-02-14T00:10:00Z | 192.0.2.20 |
| 5402 | low | T1548 | 2026-02-14T00:15:00Z | n/a |
| 100003 | high | T1505.003 | 2026-02-14T00:20:00Z | n/a |

## MITRE Techniques

- **T1046** — Network Service Discovery
- **T1110.001** — Password Guessing
- **T1190** — Exploit Public-Facing Application
- **T1548** — Abuse Elevation Control Mechanism
- **T1505.003** — Web Shell

## Recommended Triage Actions

- **critical:** Escalate to T2 immediately; isolate affected host
- **high:** Escalate to T2; isolate host if confirmed
- **medium:** Investigate during shift; document findings
- **low:** Log and monitor; no immediate action required
