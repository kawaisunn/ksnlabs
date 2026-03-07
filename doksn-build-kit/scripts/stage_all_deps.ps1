<#
  stage_all_deps.ps1
  Purpose:  Download ALL Doksn build dependencies to a single staging folder on the host
            so builds (MSI, MSIX, keywrds standalone) can run offline or in a sandbox.
  Context:  Run on BIGSPIDER (with internet) BEFORE building or launching sandbox.
  Author:   kawaisunn / IGS — AI-assisted (Claude Opus 4.6, 2026-03-07)
  Usage:    pwsh -ExecutionPolicy Bypass -File stage_all_deps.ps1 [-StageDir <path>]

  Downloads:
    [1] .NET 8 SDK installer (exe)
    [2] WiX Toolset v3.14 installer (exe)
    [3] Tesseract OCR installer (exe)
    [4] Ghostscript installer (exe)
    [5] Poppler binaries (zip)
    [6] LibreOffice MSI
    [7] Windows 10 SDK (optional — for MSIX)
    [8] Python wheel cache
#>

[CmdletBinding()]
param(
    [string]$StageDir   = "C:\dev\ocritd\sandbox\staging",
    [string]$SourceDir  = "C:\dev\ocritd",
    [switch]$SkipLarge,
    [switch]$SkipMSIXPrep
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Ensure-Dir([string]$p) {
    if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Download-File([string]$url, [string]$dest, [string]$label) {
    $filename = Split-Path $dest -Leaf
    if (Test-Path $dest) {
        $sizeMB = [math]::Round((Get-Item $dest).Length / 1MB, 1)
        Write-Host "  SKIP (exists): $filename (${sizeMB} MB)" -ForegroundColor Gray
        return $true
    }
    Write-Host "  Downloading: $label ..." -ForegroundColor Cyan
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        $ProgressPreference = 'Continue'
        $sizeMB = [math]::Round((Get-Item $dest).Length / 1MB, 1)
        Write-Host "  OK: $filename (${sizeMB} MB)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  FAIL: $filename — $_" -ForegroundColor Red
        Write-Host "  URL: $url" -ForegroundColor Yellow
        return $false
    }
}

Write-Host ""
Write-Host "=== Doksn Build Kit — Dependency Staging ===" -ForegroundColor Yellow
Write-Host "Stage dir : $StageDir" -ForegroundColor Gray
Write-Host "Source dir: $SourceDir" -ForegroundColor Gray
Write-Host ""

Ensure-Dir $StageDir
Ensure-Dir "$StageDir\installers"
Ensure-Dir "$StageDir\wheels"

$results = @{}

Write-Host "[1/8] .NET 8 SDK" -ForegroundColor Yellow
$results["dotnet"] = Download-File "https://builds.dotnet.microsoft.com/dotnet/Sdk/8.0.404/dotnet-sdk-8.0.404-win-x64.exe" "$StageDir\installers\dotnet-sdk-8.0-win-x64.exe" ".NET 8.0.404 SDK (x64)"

Write-Host "[2/8] WiX Toolset v3.14" -ForegroundColor Yellow
$results["wix"] = Download-File "https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314.exe" "$StageDir\installers\wix314.exe" "WiX Toolset v3.14.1 RTM"

Write-Host "[3/8] Tesseract OCR" -ForegroundColor Yellow
$results["tesseract"] = Download-File "https://digi.bib.uni-mannheim.de/tesseract/tesseract-ocr-w64-setup-5.3.0.20221222.exe" "$StageDir\installers\tesseract-setup.exe" "Tesseract 5.3 (UB Mannheim)"

Write-Host "[4/8] Ghostscript" -ForegroundColor Yellow
$results["ghostscript"] = Download-File "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10040/gs10040w64.exe" "$StageDir\installers\ghostscript-setup.exe" "Ghostscript 10.04.0 (x64)"

Write-Host "[5/8] Poppler" -ForegroundColor Yellow
$results["poppler"] = Download-File "https://github.com/oschwartz10612/poppler-windows/releases/download/v24.08.0-0/Release-24.08.0-0.zip" "$StageDir\installers\poppler.zip" "Poppler 24.08 Windows"

Write-Host "[6/8] LibreOffice" -ForegroundColor Yellow
if ($SkipLarge) {
    Write-Host "  SKIP (-SkipLarge)" -ForegroundColor Yellow
    $results["libreoffice"] = $false
} else {
    $results["libreoffice"] = Download-File "https://download.documentfoundation.org/libreoffice/stable/25.8.4/win/x86_64/LibreOffice_25.8.4_Win_x86-64.msi" "$StageDir\installers\libreoffice.msi" "LibreOffice 25.8.4 (x64) ~350 MB"
}

Write-Host "[7/8] Windows SDK (MSIX prep)" -ForegroundColor Yellow
if ($SkipMSIXPrep) {
    Write-Host "  SKIP (-SkipMSIXPrep)" -ForegroundColor Yellow
    $results["winsdk"] = $false
} else {
    $results["winsdk"] = Download-File "https://go.microsoft.com/fwlink/?linkid=2272610" "$StageDir\installers\winsdksetup.exe" "Windows SDK installer (for makeappx.exe)"
}

Write-Host "[8/8] Python wheels" -ForegroundColor Yellow
$existingWheels = (Get-ChildItem "$StageDir\wheels" -Filter "*.whl" -EA SilentlyContinue).Count
if ($existingWheels -ge 40) {
    Write-Host "  SKIP: $existingWheels wheels already staged" -ForegroundColor Gray
    $results["wheels"] = $true
} else {
    $hostPython = $null
    foreach ($c in @("python","python3","C:\Program Files\Python314\python.exe","C:\Program Files\Python313\python.exe")) {
        try { $v = & $c --version 2>&1; if ($v -match 'Python') { $hostPython = $c; break } } catch {}
    }
    if ($hostPython) {
        $reqFile = Join-Path $SourceDir "requirements.txt"
        $pipArgs = @("-m","pip","download","--dest","$StageDir\wheels","--python-version","3.13","--only-binary=:all:","--platform","win_amd64")
        if (Test-Path $reqFile) { $pipArgs += @("-r",$reqFile) }
        else { $pipArgs += @("ocrmypdf","pdfplumber","python-docx","openpyxl","python-pptx","Pillow","charset-normalizer","pydantic","rich","tqdm","striprtf","xlsxwriter","lxml","pikepdf") }
        try { & $hostPython @pipArgs 2>&1 | Out-Host; $results["wheels"] = $true } catch { $results["wheels"] = $false }
    } else { Write-Host "  WARN: No Python found" -ForegroundColor Yellow; $results["wheels"] = $false }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
foreach ($key in $results.Keys | Sort-Object) {
    $s = if ($results[$key]) { "OK" } else { "MISSING" }
    $c = if ($results[$key]) { "Green" } else { "Red" }
    Write-Host ("  {0,-15} [{1}]" -f $key, $s) -ForegroundColor $c
}
Write-Host ""