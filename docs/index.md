---
title: SOC Automation and Detection Engineering Homelab
description: End-to-end SOC homelab with Splunk, Wazuh, n8n, DFIR-IRIS, Velociraptor, and automated response validation.
---

# SOC Automation and Detection Engineering Homelab

This repository documents an end-to-end SOC engineering homelab built to simulate enterprise-style monitoring, alert triage, enrichment, case management, forensic collection, and automated containment.

## Overview

The lab is organized into three operational planes:

- Data plane: `pfSense`, `Squid Proxy`, and `Suricata` enforce controlled egress, SSL inspection, and network detection coverage.
- Telemetry plane: `Sysmon`, `Wazuh`, remote syslog, and `Splunk Universal Forwarder` push endpoint and network evidence into `Splunk`.
- Response plane: `n8n` orchestrates `VirusTotal`, a local LLM triage step, `DFIR-IRIS`, `Velociraptor`, and `Wazuh Active Response`.

## Objectives

- Build a realistic SOC homelab with segmented traffic inspection and centralized telemetry.
- Validate Splunk-driven detections with synthetic high-risk and low-risk events.
- Automate analyst workflows for enrichment, ticketing, triage, forensics, and containment.
- Preserve evidence with screenshots that are ready for GitHub and GitHub Pages publication.

## Lab Stack

| Layer | Components | Purpose |
| --- | --- | --- |
| Perimeter and inspection | `pfSense`, `Squid Proxy`, `Suricata` | Force proxy-based egress, decrypt inspected traffic, and monitor network activity. |
| Endpoint telemetry | `Windows 11`, `Sysmon`, `Wazuh Agent`, `Splunk UF` | Generate host telemetry and forward it into the SIEM pipeline. |
| Analytics and correlation | `Splunk` | Centralize logs, run searches, and trigger SOAR workflows. |
| SOAR and case handling | `n8n`, `DFIR-IRIS` | Normalize alerts, enrich evidence, and track investigations. |
| Forensics and containment | `Velociraptor`, `Wazuh Active Response` | Collect volatile evidence and isolate affected endpoints. |
| Intelligence and reasoning | `VirusTotal`, local LLM via `LM Studio` or `Ollama` | Enrich indicators and provide deterministic triage output. |

## Detection and Response Flow

1. Endpoint, proxy, firewall, and IDS telemetry is forwarded into `Splunk`.
2. A Splunk correlation search sends a webhook payload into `n8n`.
3. `n8n` creates or updates a case in `DFIR-IRIS`.
4. The workflow enriches the alert with `VirusTotal`.
5. A local LLM returns a deterministic `HIGH_RISK` or `LOW_RISK` triage decision.
6. High-risk alerts trigger `Velociraptor` collection and `Wazuh` host isolation.
7. Low-risk alerts are documented and closed with supporting context.

## Validation Approach

Two synthetic scenarios were used to validate the workflow safely:

- High-risk path: a simulated malicious IOC event designed to trigger escalation, enrichment, forensic collection, and containment.
- Low-risk path: a benign browser and gateway activity event designed to confirm safe closure behavior.

No real malware execution or uncontrolled external traffic was required for these tests.

## Evidence Walkthrough

### 1. Architecture and topology

**Ref 1.** Inter-VLAN telemetry flow and SOAR remediation pipeline control vectors.

![Network topology and SOAR remediation flow](assets/step-01.png)

**Ref 2.** Consolidated homelab architecture connecting perimeter inspection, telemetry, SIEM, and response services.

![Homelab architecture overview](assets/step-02.png)

### 2. Perimeter and endpoint instrumentation

**Ref 3.** `pfSense` perimeter configuration supporting LAN control, proxy routing, and inspection.

![pfSense perimeter configuration](assets/step-03.png)

**Ref 4.** Windows 11 endpoint prepared with `Sysmon`, `Splunk Universal Forwarder`, and `Wazuh Agent`.

![Windows 11 endpoint with SOC tooling](assets/step-04.png)

**Ref 5.** Additional endpoint evidence showing the installed monitoring stack used during workflow validation.

![Endpoint telemetry instrumentation evidence](assets/step-05.png)

### 3. Splunk detection and correlation

**Ref 6.** Splunk evidence view used to validate the alerting and correlation stage before handing off to SOAR.

![Splunk detection and correlation view](assets/step-06.png)

### 4. Wazuh telemetry and active response

**Ref 7.** Wazuh alert forwarding into the centralized workflow.

![Wazuh alert forwarding view](assets/step-07.png)

**Ref 8.** Wazuh active response enforcing host isolation through a firewall rule.

![Wazuh active response isolation evidence](assets/step-08.png)

### 5. SOAR orchestration and case handling

**Ref 9.** `n8n` workflow receiving Splunk alerts and orchestrating the response chain.

![n8n workflow overview](assets/step-09.png)

**Ref 10.** `n8n` branching logic for enrichment, triage, case updates, and automated follow-on actions.

![n8n branching and response logic](assets/step-10.png)

**Ref 11.** `DFIR-IRIS` investigation case created and updated for each alert.

![DFIR-IRIS case management evidence](assets/step-11.png)

### 6. Forensic collection

**Ref 12.** `Velociraptor` forensic collection execution for the affected host.

![Velociraptor collection evidence](assets/step-12.png)

**Ref 13.** Master File Table artifact collection captured during the response workflow.

![Master File Table artifact evidence](assets/step-13.png)

**Ref 14.** Windows Registry artifact collection preserved as part of automated triage.

![Windows Registry artifact evidence](assets/step-14.png)

## MITRE ATT&CK Mapping
Validation used **synthetic JSON events only**. No adversary technique was executed live on the wire.

| Scenario | Technique (emulated only) | ID | Detection source | Response evidence |
|---|---|---|---|---|
| High-risk path (`scripts/highrisk.ps1`) | Emulated scenario (synthetic events, no live execution): PowerShell-associated outbound connection to a VirusTotal-flagged IP | N/A — not executed | Splunk correlation search (Ref 6), Wazuh alert (Ref 7) | Velociraptor collection (Refs 12-14), Wazuh host isolation (Ref 8), DFIR-IRIS case (Ref 11) |
| Low-risk path (`scripts/lowrisk.ps1`, original name `payload-vt-low-risk.ps1`) | N/A (benign synthetic browser/gateway activity) | N/A | Splunk correlation search (Ref 6) | Documented and closed (flow step 7) |

Published test generators: [`scripts/highrisk.ps1`](../scripts/highrisk.ps1), [`scripts/lowrisk.ps1`](../scripts/lowrisk.ps1). Architecture write-up: [`architecture.md`](architecture.md).

## Detection & Response Logic
> **Summary grounded in the lab blueprint and screenshots.** The original SPL saved searches, n8n workflow export, and Wazuh rule files are no longer available. Behaviour below matches [`architecture.md`](architecture.md) and the evidence refs. Exact query syntax is not reproduced.

**Enrichment source:** VirusTotal v3 (confirmed in the June 2026 architecture blueprint and in the synthetic event payloads: `threat_intel_source = "VirusTotal"`).

> **Footnote — Ref 10:** The Ref 10 workflow screenshot shows an earlier **Shuffle / MISP** prototype (node labelled "MISP Threat Intel Lookup"). The production lab design documented in [`architecture.md`](architecture.md) uses **n8n** with **VirusTotal v3** enrichment. Treat Ref 10 as historical prototype evidence, not the final enrichment path.

### 1. Trigger (Splunk, Ref 6)
Synthetic events from [`scripts/highrisk.ps1`](../scripts/highrisk.ps1) and [`scripts/lowrisk.ps1`](../scripts/lowrisk.ps1) are indexed in Splunk (written as JSON lines under `C:\SOAR-Test\soar_vt_test.jsonl`; no real IOC connections). A search builds a normalized alert. For the high-risk script the alert carries:
- alert title "VirusTotal Malicious IP Detected" / rule "VirusTotal Malicious IP Communication"
- severity `high`, risk level `HIGH_RISK`, SOAR alert type `VT_HIGH_RISK_TRIGGER`
- workflow action `escalate_to_iris_and_collect_velociraptor`
- IOC: documentation address `198.51.100.66` on port 443 (`threat_intel_source = VirusTotal`)

The low-risk script maps to benign browser/gateway activity and "No containment required… close as false positive or monitor only." Splunk sends the alert to n8n by webhook.

### 2. Case creation and enrichment (n8n and DFIR-IRIS, Refs 9-11)
In n8n, the alert is normalized, **DFIR-IRIS** opens a case, then a **VirusTotal v3** lookup enriches the indicator (reputation / detection counts).

### 3. LLM verdict
The enriched alert is passed to a local model **`qwen/qwen3.5-9b`** (primary) via LM Studio or Ollama at temperature **0.1**; Hermes3-8B and Gemma were also tested. The model must emit `FINAL_DECISION: HIGH_RISK` or `FINAL_DECISION: LOW_RISK`. An n8n switch branches on that verdict.

### 4. Response
- **HIGH_RISK:** Velociraptor runs **`Windows.Triage.Collection`** (Refs 12-14). n8n authenticates to the Wazuh Manager REST API (HTTPS port 55000) and triggers **Active Response** host isolation (e.g. firewall-drop / host-deny) (Ref 8). DFIR-IRIS records a timeline event.
- **LOW_RISK:** DFIR-IRIS is updated and the case is documented and closed (flow step 7).

### Pseudo-flow
```text
Synthetic JSONL event (highrisk.ps1 / payload-vt-low-risk.ps1)
  -> Splunk search builds normalized alert (severity, risk_level, workflow_action, VT fields)
  -> webhook -> n8n: Normalize Alert
  -> DFIR-IRIS: create case
  -> VirusTotal v3 enrichment
  -> Local LLM (temp 0.1): FINAL_DECISION HIGH_RISK | LOW_RISK
  -> if HIGH_RISK:
        Velociraptor Windows.Triage.Collection
        Wazuh Active Response host isolation
        DFIR-IRIS: add timeline event
     else:
        DFIR-IRIS: low-risk update, document and close
```

## GitHub Pages

This site is designed to be published from the `/docs` folder on the `main` branch.

## Notes

- This is a controlled homelab for defensive engineering and portfolio documentation.
- Any IPs, alerts, and containment actions shown here were used for lab validation.
- The write-up is intentionally evidence-heavy so it works well both on GitHub and on GitHub Pages.
