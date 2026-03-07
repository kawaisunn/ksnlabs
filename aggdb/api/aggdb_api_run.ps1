# aggdb_api_run.ps1
# One-click startup for ITD_AggDB API server.
# Usage: Right-click → Run with PowerShell, or:  .\aggdb_api_run.ps1

$ErrorActionPreference = "Stop"
$PYTHON = "C:\Users\ctate.IGS2\AppData\Local\Programs\Python\Python314\python.exe"
$API_DIR = "C:\dev\ksnlabs\aggdb\api"

Write-Host "`n=====================================" -ForegroundColor Yellow
Write-Host "  ITD_AggDB API Server — RP-315" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow

# Check Python
if (-not (Test-Path $PYTHON)) {
    Write-Host "ERROR: Python not found at $PYTHON" -ForegroundColor Red
    Write-Host "Update `$PYTHON path in this script." -ForegroundColor Red
    pause; exit 1
}

# Check dependencies
Write-Host "`nChecking dependencies..." -ForegroundColor Cyan
$deps = @("fastapi", "uvicorn", "pyodbc", "pydantic")
$missing = @()
foreach ($dep in $deps) {
    $check = & $PYTHON -c "import $dep" 2>&1
    if ($LASTEXITCODE -ne 0) { $missing += $dep }
}

if ($missing.Count -gt 0) {
    Write-Host "Installing missing packages: $($missing -join ', ')" -ForegroundColor Yellow
    & $PYTHON -m pip install -r "$API_DIR\requirements.txt" --break-system-packages -q
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: pip install failed" -ForegroundColor Red
        pause; exit 1
    }
}

# Quick DB connectivity test
Write-Host "Testing SQL Server connection..." -ForegroundColor Cyan
try {
    $dbTest = Invoke-Sqlcmd -ServerInstance 'IGS-Intrusion\SQLEXPRESS' -Database 'ITD_AggDB' `
        -Query "SELECT DB_NAME() AS db" -ErrorAction Stop
    Write-Host "  Connected: $($dbTest.db)" -ForegroundColor Green
} catch {
    Write-Host "WARNING: SQL Server not reachable. API will start but DB calls will fail." -ForegroundColor Yellow
}

# Launch
Write-Host "`nStarting server..." -ForegroundColor Green
Write-Host "  API:     http://127.0.0.1:8000" -ForegroundColor White
Write-Host "  Swagger: http://127.0.0.1:8000/docs" -ForegroundColor White
Write-Host "  Frontend: http://127.0.0.1:8000/" -ForegroundColor White
Write-Host "`nPress Ctrl+C to stop.`n" -ForegroundColor Gray

Set-Location $API_DIR
& $PYTHON main.py
