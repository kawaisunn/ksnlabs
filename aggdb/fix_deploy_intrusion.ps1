# fix_deploy_intrusion.ps1
# Clean deployment: downloads Python embeddable, installs only AggDB deps.
# Run from your workstation.

$ErrorActionPreference = "Stop"
$Target = "IGS-Intrusion"
$RemoteBase = "\\$Target\C$\dev\aggdb"
$ApiSrc = "C:\dev\ksnlabs\aggdb\api"
$FrontendSrc = "C:\dev\ksnlabs\aggdb\frontend"

Write-Host "`n=== AggDB Clean Deploy to $Target ===" -ForegroundColor Yellow

# 1. Connectivity
if (!(Test-Path "\\$Target\C$")) { Write-Host "Cannot reach $Target" -ForegroundColor Red; exit 1 }
Write-Host "Connected to $Target" -ForegroundColor Green

# 2. Clean up botched python314 copy
Write-Host "Cleaning up old python314 copy..." -ForegroundColor Cyan
if (Test-Path "$RemoteBase\python314") {
    Remove-Item "$RemoteBase\python314" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed." -ForegroundColor Green
} else { Write-Host "  Nothing to clean." -ForegroundColor Gray }

# 3. Copy API + Frontend
Write-Host "Copying API and frontend..." -ForegroundColor Cyan
foreach ($dir in @("$RemoteBase\api", "$RemoteBase\frontend")) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}
Copy-Item "$ApiSrc\main.py" "$RemoteBase\api\main.py" -Force
Copy-Item "$ApiSrc\models.py" "$RemoteBase\api\models.py" -Force
Copy-Item "$ApiSrc\requirements.txt" "$RemoteBase\api\requirements.txt" -Force
Copy-Item "$FrontendSrc\ITD_AggDB_v4.html" "$RemoteBase\frontend\ITD_AggDB_v4.html" -Force
Write-Host "  Done." -ForegroundColor Green

# 4. Write localhost db.py
Write-Host "Writing server-local db.py..." -ForegroundColor Cyan
@'
"""ITD_AggDB DB layer - localhost SQLEXPRESS on IGS-Intrusion."""
import pyodbc
from contextlib import contextmanager

SERVER = r"localhost\SQLEXPRESS"
DATABASE = "ITD_AggDB"
CONN_STR = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;"
)

def get_connection():
    return pyodbc.connect(CONN_STR)

@contextmanager
def get_cursor():
    conn = get_connection()
    try:
        cursor = conn.cursor()
        yield cursor
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def fetch_all(query, params=None):
    with get_cursor() as cur:
        cur.execute(query, params or [])
        cols = [col[0] for col in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]

def fetch_one(query, params=None):
    with get_cursor() as cur:
        cur.execute(query, params or [])
        row = cur.fetchone()
        if row is None: return None
        cols = [col[0] for col in cur.description]
        return dict(zip(cols, row))

def execute(query, params=None):
    with get_cursor() as cur:
        cur.execute(query, params or [])
        return cur.rowcount

def execute_returning_id(query, params=None):
    with get_cursor() as cur:
        cur.execute(query, params or [])
        cur.execute("SELECT SCOPE_IDENTITY()")
        row = cur.fetchone()
        return int(row[0]) if row and row[0] else 0

def next_id(table, column):
    row = fetch_one(f"SELECT ISNULL(MAX([{column}]), 0) + 1 AS next_id FROM [{table}]")
    return row["next_id"] if row else 1

def health_check():
    return fetch_one(
        "SELECT DB_NAME() AS [database], @@SERVERNAME AS server, "
        "SUSER_SNAME() AS db_user, CONVERT(varchar, GETDATE(), 120) AS db_time"
    ) or {}
'@ | Set-Content "$RemoteBase\api\db.py" -Encoding UTF8
Write-Host "  Done." -ForegroundColor Green

# 5. Download and set up Python on Intrusion
Write-Host "Setting up Python on $Target (remote)..." -ForegroundColor Cyan
Invoke-Command -ComputerName $Target -ScriptBlock {
    $base = "C:\dev\aggdb"
    $pyDir = "$base\python"
    $pyZip = "$base\python-embed.zip"

    # Download Python 3.12 embeddable (stable, well-tested)
    if (!(Test-Path "$pyDir\python.exe")) {
        Write-Host "  Downloading Python 3.12 embeddable..." 
        $url = "https://www.python.org/ftp/python/3.12.8/python-3.12.8-embed-amd64.zip"
        Invoke-WebRequest -Uri $url -OutFile $pyZip -UseBasicParsing
        
        Write-Host "  Extracting..."
        if (Test-Path $pyDir) { Remove-Item $pyDir -Recurse -Force }
        Expand-Archive $pyZip -DestinationPath $pyDir
        Remove-Item $pyZip

        # Enable pip: uncomment import site in python312._pth
        $pth = Get-ChildItem "$pyDir\python*._pth" | Select-Object -First 1
        if ($pth) {
            $content = Get-Content $pth.FullName
            $content = $content -replace '#import site', 'import site'
            Set-Content $pth.FullName $content
            Write-Host "  Enabled site-packages."
        }

        # Get pip
        Write-Host "  Installing pip..."
        Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "$pyDir\get-pip.py" -UseBasicParsing
        & "$pyDir\python.exe" "$pyDir\get-pip.py" --no-warn-script-location 2>&1 | Out-Null
        Write-Host "  pip installed."
    } else {
        Write-Host "  Python already present."
    }

    # Install deps
    Write-Host "  Installing AggDB dependencies..."
    & "$pyDir\python.exe" -m pip install fastapi uvicorn pyodbc pydantic --no-warn-script-location -q 2>&1
    
    # Verify
    $check = & "$pyDir\python.exe" -c "import fastapi,uvicorn,pyodbc,pydantic; print('OK')" 2>&1
    if ($check -match "OK") { Write-Host "  Dependencies verified." -ForegroundColor Green }
    else { Write-Host "  WARNING: dep check output: $check" -ForegroundColor Yellow }
} -ErrorAction Continue
Write-Host "  Python setup complete." -ForegroundColor Green

# 6. Write start batch
Write-Host "Writing start_aggdb.bat..." -ForegroundColor Cyan
@'
@echo off
title ITD_AggDB API Server
echo =============================================
echo   ITD_AggDB API Server — RP-315
echo   URL: http://IGS-Intrusion:8000
echo =============================================
echo.
cd /d C:\dev\aggdb\api
C:\dev\aggdb\python\python.exe main.py
pause
'@ | Set-Content "$RemoteBase\start_aggdb.bat" -Encoding ASCII
Write-Host "  Done." -ForegroundColor Green

# 7. Firewall rule
Write-Host "Firewall rule..." -ForegroundColor Cyan
Invoke-Command -ComputerName $Target -ScriptBlock {
    $r = Get-NetFirewallRule -DisplayName "AggDB API" -ErrorAction SilentlyContinue
    if (!$r) {
        New-NetFirewallRule -DisplayName "AggDB API" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow -Profile Any | Out-Null
        Write-Host "  Created."
    } else { Write-Host "  Already exists." }
}
Write-Host "  Done." -ForegroundColor Green

# 8. Create desktop shortcut for Rebecca/Liam
Write-Host "Creating desktop shortcut..." -ForegroundColor Cyan
Invoke-Command -ComputerName $Target -ScriptBlock {
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut("C:\Users\Public\Desktop\AggDB.lnk")
    $lnk.TargetPath = "http://IGS-Intrusion:8000"
    $lnk.IconLocation = "shell32.dll,13"  # Globe icon
    $lnk.Description = "ITD Aggregate Materials Database — RP-315"
    $lnk.Save()
    Write-Host "  Shortcut created on Public Desktop."
}
Write-Host "  Done." -ForegroundColor Green

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "  Start server:  RDP to $Target, run C:\dev\aggdb\start_aggdb.bat" -ForegroundColor White
Write-Host "  Rebecca opens: http://IGS-Intrusion:8000" -ForegroundColor White
Write-Host "  Shortcut:      AggDB icon on Public Desktop" -ForegroundColor White
Write-Host ""
Write-Host "  Cleanup: See AggDB_Cleanup_Guide.docx" -ForegroundColor Gray
Write-Host "  Expires: Remove within 1 week per IGS policy" -ForegroundColor Yellow
Write-Host ""
