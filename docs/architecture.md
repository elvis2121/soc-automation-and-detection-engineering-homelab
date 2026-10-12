# SOC Homelab Architecture

Cleaned public summary of the June 2026 lab blueprint
(`SOC_Homelab_Architecture_Documentation.docx`). Internal addresses, hostnames,
credentials, and other lab-private values have been removed. No configuration
was invented beyond what that document and the published screenshots describe.

## Overview

This homelab simulates an enterprise-style Security Operations Center: forced
egress inspection, endpoint and network telemetry into Splunk, and an automated
SOAR loop driven by a local LLM for triage.

Three operational planes:

| Plane | Components | Role |
| --- | --- | --- |
| Data plane | pfSense, Squid (SSL inspection), Suricata | Whitelist egress, decrypt inspected web traffic, network detection |
| Telemetry plane | Windows 11 endpoint (Sysmon, Wazuh agent, Splunk Universal Forwarder), remote syslog | Host and network evidence into Splunk |
| Response plane | n8n, VirusTotal v3, local LLM `qwen/qwen3.5-9b` (LM Studio / Ollama; Hermes3-8B and Gemma also tested), DFIR-IRIS, Velociraptor, Wazuh Active Response | Enrich, triage, case-manage, collect, isolate |

## Topology (logical)

- **Perimeter:** pfSense replaces any-any outbound with an explicit whitelist /
  default-deny so LAN clients cannot reach the internet on ports 80/443 except
  through the proxy.
- **Proxy:** Squid on port 3128 with an internal lab CA (4096-bit RSA, SHA-256)
  re-signs TLS so full URI and user-agent metadata land in access logs.
- **IDS:** Suricata inline (FreeBSD netmap); LRO/TSO/checksum offloading
  disabled; Emerging Threats Open ruleset; alerts forwarded by syslog.
- **Endpoint:** Windows 11 with Sysmon (Olaf Hartong modular config — Event ID 6
  driver loads, Event ID 1 process create), Wazuh agent (manager over port 1514),
  and Splunk Universal Forwarder.
- **SIEM:** Splunk correlates forwarded logs and fires a webhook into n8n.
- **SOAR host:** Docker containers for n8n, Velociraptor, and DFIR-IRIS.

Diagram evidence: repository assets Ref 1–2 (inter-VLAN telemetry / SOAR flow
and consolidated architecture).

## Synthetic event design

Threat emulation uses PowerShell scripts that **write JSON lines to a local
file**. They do **not** open real connections to the IOC.

| Script | Path | Purpose |
| --- | --- | --- |
| `highrisk.ps1` | [`scripts/highrisk.ps1`](../scripts/highrisk.ps1) | Emits a `HIGH_RISK` event: rule "VirusTotal Malicious IP Communication", process `powershell.exe`, destination TEST-NET IP `198.51.100.66:443`, `vt_verdict=malicious`. Evidence text states no real network traffic was generated. |
| `payload-vt-low-risk.ps1` | [`scripts/lowrisk.ps1`](../scripts/lowrisk.ps1) | Emits a `LOW_RISK` event: rule "Benign Browser Network Activity", process `chrome.exe`, destination = lab gateway placeholder, `vt_verdict=harmless`. |

Both scripts append a single compressed JSON object to
`C:\SOAR-Test\soar_vt_test.jsonl` and set `test_mode = true`. Recommended
actions in the payload match the SOAR branches (escalate + Velociraptor vs
monitor/close).

Lab-private source and endpoint addresses from the original document were
replaced with placeholders (`<ENDPOINT_LAB_IP>`, `<LAB_GATEWAY_IP>`,
`<SPLUNK_HOST>`). The documentation address `198.51.100.66` is kept.

## SOAR flow: n8n → VirusTotal → LLM → response

Enrichment source for the production lab design is **VirusTotal v3** (not MISP).
See the repository README footnote about the Ref 10 screenshot.

Sequence after Splunk sends a webhook to n8n:

1. **Normalize** the alert payload.
2. **DFIR-IRIS:** create a case (`POST /api/v1/cases/add`) with an ISO-8601
   `event_date` (n8n `$now`) so the timeline stays ordered.
3. **VirusTotal v3:** HTTP request node looks up the file hash or source IP and
   pulls reputation / detection counts.
4. **Local LLM triage:** evidence packet goes to a local model via LM Studio or
   Ollama. Primary model: **`qwen/qwen3.5-9b`**. Hermes3-8B and Gemma were also tested.
   Temperature is fixed at **0.1**. The model must return a reproducible string
   containing either `FINAL_DECISION: HIGH_RISK` or `FINAL_DECISION: LOW_RISK`.
5. **Switch** on that verdict:
   - **LOW_RISK:** update the DFIR-IRIS case and close (monitor-only).
   - **HIGH_RISK:** run forensics and isolation (below), then add a DFIR-IRIS
     timeline event.

## Velociraptor collection

On high risk, n8n triggers a Velociraptor collection against the alerting agent.
The documented collection artifact is **`Windows.Triage.Collection`**, invoked
from the Velociraptor container (config under `/velociraptor/`, agent id from the
alert JSON). The sweep is intended to capture volatile host state (memory-related
keys, sockets, processes) before isolation cuts the network path.

Published evidence: Refs 12–14 (collection run, MFT, registry artifacts).

## Wazuh Active Response isolation

In parallel, n8n authenticates to the Wazuh Manager REST API over HTTPS port
**55000**, then issues an **Active Response** action against the agent (examples
named in the blueprint: `firewall-drop` / `host-deny`). That installs a host
firewall rule and isolates the endpoint from the lab network.

Published evidence: Ref 8 (active response isolation).

## LLM settings (summary)

| Setting | Value from the lab blueprint |
| --- | --- |
| Runtime | LM Studio or Ollama |
| Primary model | `qwen/qwen3.5-9b` |
| Also tested | Hermes3-8B, Gemma |
| Temperature | `0.1` |
| Required output markers | `FINAL_DECISION: HIGH_RISK` or `FINAL_DECISION: LOW_RISK` |

## What this document is not

- Not a runnable compose stack or export of the n8n workflow / Splunk saved
  searches / Wazuh rules (those exports are no longer available).
- Not a claim that ATT&CK techniques were executed live — validation used
  synthetic JSON events only. See the ATT&CK table in the README.
