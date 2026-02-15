# Testbed Baseline Runbook

Date: 2026-02-13
Host: Linux (Nobara), VirtualBox 7.2.6

## Lab Assets

- Kali source image extracted at `testbed/images/kali-vbox/kali-linux-2025.4-virtualbox-amd64`
- Metasploitable source image extracted at `testbed/images/metasploitable/Metasploitable2-Linux`
- Working VM location: `<VirtualBox VM folder>/Testbed`

## Registered VMs

- `Kali Attack VM`
  - RAM: 4096 MB
  - CPU: 2
  - NIC1: Host-Only (`vboxnet0`)
  - NIC2: NAT
  - MAC1: `08:00:27:63:b0:05`
  - MAC2: `08:00:27:ca:2c:33`
- `Kali Defense VM`
  - RAM: 4096 MB
  - CPU: 2
  - NIC1: Host-Only (`vboxnet0`)
  - NIC2: NAT
  - MAC1: `08:00:27:ab:7f:1e`
  - MAC2: `08:00:27:02:bb:52`
- `MS-2 Target VM`
  - RAM: 1024 MB
  - CPU: 1
  - VRAM: 16 MB
  - NIC1: Host-Only (`vboxnet0`)
  - NIC2: Disabled
  - MAC1: `08:00:27:7d:f1:03`
  - Disk: `<VirtualBox VM folder>/Testbed/MS2/Metasploitable.vmdk`

## Host-Only Network

- Interface: `vboxnet0`
- Host IP (current): `192.168.56.1/24`
- DHCP network: `HostInterfaceNetworking-vboxnet0`
  - DHCP server IP: `192.168.10.100`
  - Pool: `192.168.10.11` - `192.168.10.254`

## Validation Results

- Gate A (IP correctness): PASS
  - Kali Attack guest properties show:
    - NIC1: `192.168.10.11`
    - NIC2: `10.0.3.15`
  - Kali Defense guest properties show:
    - NIC1: `192.168.10.12`
    - NIC2: `10.0.3.15`
  - MS-2 DHCP lease confirms `192.168.10.13`
- Gate B (inter-VM ping): PARTIAL
  - Executed on 2026-02-13T01:44:17-07:00 from Kali guests:
    - Kali Attack -> `192.168.10.12`: PASS (`rc=0`, `0% packet loss`)
    - Kali Attack -> `192.168.10.13`: PASS (`rc=0`, `0% packet loss`)
    - Kali Defense -> `192.168.10.11`: PASS (`rc=0`, `0% packet loss`)
    - Kali Defense -> `192.168.10.13`: PASS (`rc=0`, `0% packet loss`)
  - Remaining blocker:
    - MS-2-origin checks (`MS-2 -> 192.168.10.11` and `MS-2 -> 192.168.10.12`) could not be automated because VirtualBox Guest Additions are not installed/ready on MS-2, so `VBoxManage guestcontrol` cannot execute in-guest commands for that VM.
  - Re-validation attempt on 2026-02-13:
    - `VBoxManage guestcontrol "MS-2 Target VM" run --exe /bin/ping ...` still fails with `VBOX_E_GSTCTL_GUEST_ERROR` and message `Guest Additions are not installed or not ready (yet)`.
- Gate C (optional internet for Kali): PASS (validated)
  - Kali Attack and Kali Defense both passed:
    - `ping -c 2 google.com` (`rc=0`)
    - `curl -I https://www.google.com` (`rc=0`, HTTP 200)
- Gate D (MS-2 isolation): PASS
  - MS-2 has NIC2 disabled; only host-only NIC is attached.

## Snapshots

- `Kali Attack VM`: `baseline-clean`
- `Kali Defense VM`: `baseline-clean`
- `MS-2 Target VM`: `baseline-clean`

## Remaining Manual Checks (inside VMs)

Run after starting all VMs:

1. On MS-2:
   - `ping 192.168.10.11`
   - `ping 192.168.10.12`

## SIEM Activation Gate (Spec-Aligned)

This gate supersedes baseline-only completion for MVP SOC acceptance.

- Gate S1 (Wazuh host reachability): PASS
  - 2026-02-13: `ping -c 2 192.168.10.14` -> 0% packet loss; `scripts/00-require-host-network.sh` exits 0.
- Gate S2 (Wazuh dashboard/API reachability): PASS
  - 2026-02-13: `curl -k -I --max-time 8 https://192.168.10.14:443` -> HTTP 200.
  - 2026-02-13: `curl -k -I --max-time 8 https://192.168.10.14:55000` -> HTTP 200.
- Gate S3 (2+ endpoint ingestion): PASS
  - 2026-02-14: Kali Defense wazuh-agent 4.9.2-1 active (ID 001); MS-2 sysklogd forwarding
    configured (`*.* @192.168.10.14` in `/etc/syslog.conf`; HUP applied). Both sources
    confirmed delivering events to Wazuh.
- Gate S4 (custom rules deployed and firing): PASS
  - 2026-02-13: `wazuh-config/local_rules.xml` deployed via `scripts/02-deploy-wazuh-rules.sh`;
    rules 100001-100003 confirmed present.
  - 2026-02-14: Rules 100010/100011 added (sshd-stripped composite); custom decoder
    `sshd-stripped` deployed. Firing validated: 100011 (Scenario 01), 100003 (Scenario 05).
- Gate S5 (scenario matrix 01-05): PASS
  - 2026-02-14: All 5 scenarios validated; evidence in `evidence/scenario-*/result.json`.
    Rules fired: 100011, 5763, 2501, 5402, 100003.

## Optional Host Alignment To 192.168.10.1

If you want the host-side interface itself to match the guide exactly (`192.168.10.1/24`), run:

```bash
sudo VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.10.1 --netmask 255.255.255.0
```
