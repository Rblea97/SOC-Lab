## Scenario 02: SSH Brute Force

**MITRE ATT&CK:** T1110.001 - Brute Force: Password Guessing  
**Objective:** Detect repeated SSH auth failures and possible success.

### Attack Steps

**Source:** Kali Attack (192.168.10.11)
**Target:** Kali Defense (192.168.10.12)

> **Note:** MS-2's legacy OpenSSH (Ubuntu 8.04) cannot negotiate a KEX with Hydra v9.6.
> Brute-force is demonstrated against Kali Defense, which runs a current OpenSSH and
> has a Wazuh agent (ID 001) for alert collection.

1. From Kali Attack, run a capped Hydra brute-force against Kali Defense:
   ```
   timeout 45 hydra -l kali -P /usr/share/wordlists/rockyou.txt.gz \
     -t 4 ssh://192.168.10.12
   ```

### Expected Detection

- Rule ID: `5763` (Wazuh built-in — sshd brute force)
- Rule ID: `100002` (custom — successful login after repeated failures; only fires if
  Hydra finds valid credentials)
- Expected latency: `< 60s`

### Triage Notes

- True positive: high failed auth volume from one source IP.
- False positive: mistyped credentials during maintenance.
