# SOC Lab Architecture

```mermaid
flowchart LR
  hostMachine[HostMachineVirtualBox] --> hostOnly[HostOnlyNetwork_192_168_10_0_24]
  hostOnly --> kaliAttack[KaliAttack_192_168_10_11]
  hostOnly --> kaliDefense[KaliDefense_192_168_10_12]
  hostOnly --> ms2Target[MS2Target_192_168_10_13]
  hostOnly --> wazuhServer[WazuhServer_192_168_10_14]
  kaliAttack -->|"attack_traffic"| ms2Target
  kaliDefense -->|"wazuh_agent"| wazuhServer
  ms2Target -->|"syslog_udp_514"| wazuhServer
```

## Roles

- `Kali Attack VM`: executes attack scenarios for detection validation.
- `Kali Defense VM`: monitored endpoint with Wazuh agent.
- `MS-2 Target VM`: vulnerable target with syslog forwarding.
- `Wazuh Server VM`: SIEM manager/indexer/dashboard.

## Data Flow

1. Attacks originate from `192.168.10.11`.
2. Target and endpoint logs move to `192.168.10.14`.
3. Wazuh applies default + local custom rules.
4. Analyst validates detections and triages alerts in dashboard/API.
