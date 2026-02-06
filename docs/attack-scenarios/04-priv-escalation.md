## Scenario 04: Privilege Escalation Attempt

**MITRE ATT&CK:** T1548 - Abuse Elevation Control Mechanism  
**Objective:** Detect suspicious privileged command attempts.

### Attack Steps

**Source:** Host machine (via SSH to Kali Defense; script `11-run-scenario-04.sh` runs from host using sshpass)
**Target:** Kali Defense (192.168.10.12)

1. SSH into Kali Defense and run privileged commands as `kali` user:
   ```
   ssh kali@192.168.10.12 \
     'sudo -l; echo kali | sudo -S id; echo kali | sudo -S whoami'
   ```

### Expected Detection

- Rule ID: `5402` (Wazuh built-in — successful sudo to ROOT)
- Expected latency: `< 60s`

### Triage Notes

- True positive: unexpected sudo activity from non-admin account.
- False positive: authorized system administration tasks.
