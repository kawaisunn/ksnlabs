# deploy_update.ps1 — Push updated API + frontend to Intrusion and restart
$ErrorActionPreference = "Stop"
$Target = "IGS-Intrusion"
$RemoteBase = "\\$Target\C$\dev\aggdb"
$LocalApi = "C:\dev\ksnlabs\aggdb\api"
$LocalFrontend = "C:\dev\ksnlabs\aggdb\frontend"

Write-Host "`n=== Deploying updates to $Target ===" -ForegroundColor Yellow

# 1. Copy updated files
Write-Host "Copying main.py, models.py..." -ForegroundColor Cyan
Copy-Item "$LocalApi\main.py" "$RemoteBase\api\main.py" -Force
Copy-Item "$LocalApi\models.py" "$RemoteBase\api\models.py" -Force
Write-Host "  API updated." -ForegroundColor Green

Write-Host "Copying ITD_AggDB_v4.html..." -ForegroundColor Cyan
Copy-Item "$LocalFrontend\ITD_AggDB_v4.html" "$RemoteBase\frontend\ITD_AggDB_v4.html" -Force
Write-Host "  Frontend updated." -ForegroundColor Green

# 2. Kill existing API process on Intrusion
Write-Host "Restarting API on $Target..." -ForegroundColor Cyan
Invoke-Command -ComputerName $Target -ScriptBlock {
    $procs = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($p in $procs) {
            Write-Host "  Killing PID $($p.OwningProcess)"
            Stop-Process -Id $p.OwningProcess -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
    }
    # Start API in background
    Start-Process -FilePath "C:\dev\aggdb\python\python.exe" -ArgumentList "C:\dev\aggdb\api\main.py" -WorkingDirectory "C:\dev\aggdb\api" -WindowStyle Hidden
    Start-Sleep -Seconds 3
    # Verify
    try {
        $r = Invoke-RestMethod "http://localhost:8000/api/ping" -TimeoutSec 5
        Write-Host "  API started: $($r.status)" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: API may not have started. Check manually." -ForegroundColor Yellow
    }
}

Write-Host "`n=== Deploy complete ===" -ForegroundColor Green
Write-Host "Rebecca: http://$Target`:8000/" -ForegroundColor White
Write-Host ""
