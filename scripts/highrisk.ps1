# Extracted from SOC_Homelab_Architecture_Documentation.docx (June 2026).
# Lab IPs and hostnames redacted to placeholders; TEST-NET IP 198.51.100.66 retained.
# Synthetic event generator — does not send real network traffic.

param(
    [string]$TargetIp = "198.51.100.66"
)

$LogDir = "C:\SOAR-Test"
$LogPath = Join-Path $LogDir "soar_vt_test.jsonl"

if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$eventTime = [DateTimeOffset]::Now.ToUnixTimeSeconds().ToString() + ".000"

$payload = [ordered]@{
    sid                 = "ps1-high-risk-vt-ip-test-001"
    search_name         = "SOC HIGH_RISK VirusTotal Malicious IP Test"
    app                 = "search"
    owner               = "lab-analyst"
    results_link        = "http://<SPLUNK_HOST>:8000/app/search/@go?sid=ps1-high-risk-vt-ip-test-001"

    _time               = $eventTime
    risk_level          = "HIGH_RISK"

    src_ip              = "<ENDPOINT_LAB_IP>"
    endpoint_ip         = "<ENDPOINT_LAB_IP>"
    host                = $env:COMPUTERNAME
    detected_user       = "$env:USERDOMAIN\$env:USERNAME"

    rule_name           = "VirusTotal Malicious IP Communication"
    process_name        = "powershell.exe"
    process_path        = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    parent_process      = "cmd.exe"

    destination_ip      = $TargetIp
    dest_ip             = $TargetIp
    destination_port    = 443
    protocol            = "TCP"

    ioc_type            = "ip"
    ioc_value           = $TargetIp

    threat_intel_source = "VirusTotal"
    vt_verdict          = "malicious"
    vt_malicious        = 18
    vt_suspicious       = 4
    vt_harmless         = 2
    vt_undetected       = 62
    vt_detection_ratio  = "18/86"
    vt_reputation       = -42

    evidence            = "Synthetic high-risk SOAR test. The test IP $TargetIp is marked as VirusTotal malicious for workflow validation. No real network traffic was generated."
    recommended_action  = "Escalate immediately. Create or update DFIR-IRIS case, add timeline event, and trigger Velociraptor collection."

    test_mode           = $true
    generated_by        = "highrisk.ps1"
}

$json = $payload | ConvertTo-Json -Depth 10 -Compress

try {
    Add-Content -Path $LogPath -Value $json -ErrorAction Stop
    Write-Host "[+] High-risk event written successfully to $LogPath"
    Write-Host "[+] IOC IP: $TargetIp"
}
catch {
    Write-Host "[!] Failed to write event to $LogPath"
    Write-Host $_.Exception.Message
    exit 1
}
