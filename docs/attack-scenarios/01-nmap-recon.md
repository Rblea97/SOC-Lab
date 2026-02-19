## Scenario 01: Network Reconnaissance

**MITRE ATT&CK:** T1046 - Network Service Discovery
**Objective:** Detect rapid service probing against MS-2.

### Attack Steps

**Source:** Kali Attack (192.168.10.11)
**Target:** MS-2 (192.168.10.13)

1. From Kali Attack, probe MS-2 SSH with repeated invalid-user connection attempts:
   ```
   for i in $(seq 1 15); do
     ssh -o BatchMode=yes -o ConnectTimeout=2 \
       -o MACs=hmac-sha1 \
       -o KexAlgorithms=diffie-hellman-group14-sha1,diffie-hellman-group1-sha1 \
       -o HostKeyAlgorithms=ssh-rsa \
       scanuser@192.168.10.13 2>/dev/null; true
   done
   ```
   > **Note:** `nmap` and Hydra v9.6 cannot negotiate KEX with MS-2's legacy OpenSSH
   > (Ubuntu 8.04). SSH probing with invalid usernames produces the same T1046 signal.

### Expected Detection

- Rule ID: `100011` (custom composite — 12+ SSH invalid-user attempts from one IP in 60s)
- Alert level: `8`
- Decoder: `sshd-stripped` (handles MS-2 sysklogd stripped-format logs)
- Expected latency: `< 60s`

### Triage Notes

- True positive: same source scans multiple services quickly.
- False positive: scheduled vulnerability scanning windows.
