# Original filename in lab documentation: payload-vt-low-risk.ps1
# Extracted from SOC_Homelab_Architecture_Documentation.docx (June 2026).
# Lab IPs and hostnames redacted to placeholders. Synthetic event — does not connect externally.

# payload-vt-low-risk.ps1
# Safe synthetic benign SOAR test event. Does not connect to any external IP.

$LogPath = "C:\SOAR-Test\soar_vt_test.jsonl"

$eventTime = [DateTimeOffset]::Now.ToUnixTimeSeconds().ToString() + ".000"

$payload = [ordered]@{
    sid                = "postman-low-risk-vt-ip-test-002"
    search_name        = "SOC LOW_RISK VirusTotal Benign IP Test"
    app                = "search"
    owner              = "lab-analyst"
    results_link       = "http://<SPLUNK_HOST>:8000/app/search/@go?sid=postman-low-risk-vt-ip-test-002"

    _time              = $eventTime
    risk_level         = "LOW_RISK"

    src_ip             = "<ENDPOINT_LAB_IP>"
    endpoint_ip        = "<ENDPOINT_LAB_IP>"
    host               = $env:COMPUTERNAME
    detected_user      = "$env:USERDOMAIN\$env:USERNAME"

    rule_name          = "Benign Browser Network Activity"
    process_name       = "chrome.exe"
    process_path       = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    parent_process     = "explorer.exe"

    destination_ip     = "<LAB_GATEWAY_IP>"
    dest_ip            = "<LAB_GATEWAY_IP>"
    destination_port   = 443
    protocol           = "TCP"

    ioc_type           = "ip"
    ioc_value          = "<LAB_GATEWAY_IP>"

    threat_intel_source = "VirusTotal"
    vt_verdict          = "harmless"
    vt_malicious        = 0
    vt_suspicious       = 0
    vt_harmless         = 75
    vt_undetected       = 11
    vt_detection_ratio  = "0/86"
    vt_reputation       = 0

    vt_categories       = @(
        "private-network",
        "lab-gateway",
        "benign"
    )

    evidence = "Routine internal browser connection to the local lab gateway. User opened a normal browser session. No suspicious process behavior. No privileged process access. No persistence. No file impact. No service disruption. No external IOC observed."

    recommended_action = "No containment required. Monitor only and close after analyst review if no additional suspicious activity is observed."

    test_mode = $true
    generated_by = "payload-vt-low-risk.ps1"
}

$json = $payload | ConvertTo-Json -Depth 10 -Compress

Add-Content -Path $LogPath -Value $json

Write-Host "[+] Low-risk VirusTotal synthetic event written to $LogPath"
