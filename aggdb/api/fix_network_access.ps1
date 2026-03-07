# fix_network_access.ps1
# Diagnose and fix network access for Rebecca's workstation
# Self-elevates to Administrator if needed

# ── Self-elevate ──────────────────────────────────────────
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Relaunching as Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$ErrorActionPreference = "Stop"
$PORT = 8000
$RULE_NAME = "ITD_AggDB API (TCP $PORT)"

Write-Host "`n===== ITD_AggDB Network Access Diagnostic =====" -ForegroundColor Yellow

# 1. Firewall rule (persistent fix — do this first)
Write-Host "`n[1] Checking Windows Firewall..." -ForegroundColor Cyan
$existingRule = Get-NetFirewallRule -DisplayName $RULE_NAME -ErrorAction SilentlyContinue
if ($existingRule) {
    Write-Host "  Rule '$RULE_NAME' exists (Enabled: $($existingRule.Enabled))" -ForegroundColor Green
    if ($existingRule.Enabled -ne 'True') {
        Write-Host "  Enabling rule..." -ForegroundColor Yellow
        Enable-NetFirewallRule -DisplayName $RULE_NAME
        Write-Host "  Enabled." -ForegroundColor Green
    }
} else {
    Write-Host "  No firewall rule found for port $PORT. Creating..." -ForegroundColor Yellow
    New-NetFirewallRule `
        -DisplayName $RULE_NAME `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $PORT `
        -Action Allow `
        -Profile Domain,Private `
        -Description "Allow inbound access to ITD_AggDB FastAPI server (RP-315)" `
        -ErrorAction Stop
    Write-Host "  Firewall rule created: '$RULE_NAME' (Domain+Private profiles)" -ForegroundColor Green
}

# 2. Show this machine's IPs so we know what Rebecca should use
Write-Host "`n[2] This machine's network addresses:" -ForegroundColor Cyan
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' } | ForEach-Object {
    Write-Host "  $($_.IPAddress)  ($($_.InterfaceAlias))" -ForegroundColor White
}

# 3. Check if API is currently listening
Write-Host "`n[3] Checking if port $PORT is listening..." -ForegroundColor Cyan
$listening = Get-NetTCPConnection -LocalPort $PORT -State Listen -ErrorAction SilentlyContinue
if ($listening) {
    Write-Host "  OK: Port $PORT is listening (PID $($listening.OwningProcess))" -ForegroundColor Green
    $proc = Get-Process -Id $listening.OwningProcess -ErrorAction SilentlyContinue
    if ($proc) { Write-Host "  Process: $($proc.ProcessName) ($($proc.Id))" -ForegroundColor Gray }
} else {
    Write-Host "  NOT RUNNING: Nothing on port $PORT right now." -ForegroundColor Yellow
    Write-Host "  Start the API in another terminal: .\aggdb_api_run.ps1" -ForegroundColor Yellow
}

# 4. Quick local test (only if listening)
Write-Host "`n[4] Testing API locally..." -ForegroundColor Cyan
try {
    $r = Invoke-RestMethod -Uri "http://127.0.0.1:$PORT/api/ping" -TimeoutSec 5
    Write-Host "  API responded: $($r.status) - $($r.msg)" -ForegroundColor Green
} catch {
    Write-Host "  Local API test failed: $_" -ForegroundColor Red
}

# 5. Show Rebecca's URL
$hostname = $env:COMPUTERNAME
Write-Host "`n===== DONE =====" -ForegroundColor Yellow
Write-Host "Rebecca should open:" -ForegroundColor White
Write-Host "  http://${hostname}:${PORT}/" -ForegroundColor Green
Write-Host "  (or use the IP address shown above)" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to close"
