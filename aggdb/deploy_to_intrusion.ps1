# deploy_to_intrusion.ps1
# Deploys AggDB API + frontend + Python to IGS-Intrusion
# Run from your workstation (where you're admin on both machines)

$ErrorActionPreference = "Stop"
$Target = "IGS-Intrusion"
$RemoteBase = "\\$Target\C$\dev\aggdb"
$PythonSrc = "C:\Users\ctate.IGS2\AppData\Local\Programs\Python\Python314"
$PythonDst = "$RemoteBase\python314"
$ApiSrc = "C:\dev\ksnlabs\aggdb\api"
$FrontendSrc = "C:\dev\ksnlabs\aggdb\frontend"
$ApiDst = "$RemoteBase\api"
$FrontendDst = "$RemoteBase\frontend"

Write-Host "`n=== AggDB Deployment to $Target ===" -ForegroundColor Yellow

# 1. Test connectivity
Write-Host "Testing connection to $Target..." -ForegroundColor Cyan
if (!(Test-Path "\\$Target\C$")) {
    Write-Host "ERROR: Cannot reach \\$Target\C$ — check network/permissions" -ForegroundColor Red
    exit 1
}
Write-Host "  Connected." -ForegroundColor Green

# 2. Copy Python (skip if already there)
if (Test-Path $PythonDst) {
    Write-Host "Python314 already on $Target — skipping copy." -ForegroundColor Gray
} else {
    Write-Host "Copying Python314 to $Target (~120MB)..." -ForegroundColor Cyan
    robocopy $PythonSrc $PythonDst /E /NJH /NJS /NDL /NFL /NC /NS /NP
    if ($LASTEXITCODE -gt 7) { Write-Host "ERROR: robocopy failed" -ForegroundColor Red; exit 1 }
    Write-Host "  Python copied." -ForegroundColor Green
}

# 3. Copy API
Write-Host "Copying API to $Target..." -ForegroundColor Cyan
if (!(Test-Path $ApiDst)) { New-Item -ItemType Directory -Path $ApiDst -Force | Out-Null }
Copy-Item "$ApiSrc\main.py" "$ApiDst\main.py" -Force
Copy-Item "$ApiSrc\models.py" "$ApiDst\models.py" -Force
Copy-Item "$ApiSrc\requirements.txt" "$ApiDst\requirements.txt" -Force
Write-Host "  API copied." -ForegroundColor Green

# 4. Write server-local db.py (localhost instead of IGS-Intrusion)
Write-Host "Writing server-local db.py..." -ForegroundColor Cyan
@'
"""
ITD_AggDB database connection layer.
Server-local config: localhost\\SQLEXPRESS (running on IGS-Intrusion).
"""
import pyodbc
from contextlib import contextmanager

SERVER = r"localhost\SQLEXPRESS"
DATABASE = "ITD_AggDB"
CONN_STR = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    f"Trusted_Connection=yes;"
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

def fetch_all(query: str, params=None) -> list[dict]:
    with get_cursor() as cur:
        cur.execute(query, params or [])
        cols = [col[0] for col in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]

def fetch_one(query: str, params=None) -> dict | None:
    with get_cursor() as cur:
        cur.execute(query, params or [])
        row = cur.fetchone()
        if row is None:
            return None
        cols = [col[0] for col in cur.description]
        return dict(zip(cols, row))

def execute(query: str, params=None):
    with get_cursor() as cur:
        cur.execute(query, params or [])
        return cur.rowcount

def execute_returning_id(query: str, params=None) -> int:
    with get_cursor() as cur:
        cur.execute(query, params or [])
        cur.execute("SELECT SCOPE_IDENTITY()")
        row = cur.fetchone()
        return int(row[0]) if row and row[0] else 0

def next_id(table: str, column: str) -> int:
    row = fetch_one(f"SELECT ISNULL(MAX([{column}]), 0) + 1 AS next_id FROM [{table}]")
    return row["next_id"] if row else 1

def health_check() -> dict:
    row = fetch_one(
        "SELECT DB_NAME() AS [database], @@SERVERNAME AS server, "
        "SUSER_SNAME() AS db_user, CONVERT(varchar, GETDATE(), 120) AS db_time"
    )
    return row or {}
'@ | Set-Content "$ApiDst\db.py" -Encoding UTF8
Write-Host "  db.py written (localhost\SQLEXPRESS)." -ForegroundColor Green

# 5. Copy frontend
Write-Host "Copying frontend..." -ForegroundColor Cyan
if (!(Test-Path $FrontendDst)) { New-Item -ItemType Directory -Path $FrontendDst -Force | Out-Null }
Copy-Item "$FrontendSrc\ITD_AggDB_v4.html" "$FrontendDst\ITD_AggDB_v4.html" -Force
Write-Host "  Frontend copied." -ForegroundColor Green

# 6. Install pip dependencies on target
Write-Host "Installing Python dependencies on $Target..." -ForegroundColor Cyan
Invoke-Command -ComputerName $Target -ScriptBlock {
    $py = "C:\dev\aggdb\python314\python.exe"
    & $py -m pip install fastapi uvicorn pyodbc pydantic --break-system-packages -q 2>&1
}
Write-Host "  Dependencies installed." -ForegroundColor Green

# 7. Write startup batch file
Write-Host "Writing start_aggdb.bat..." -ForegroundColor Cyan
@'
@echo off
title ITD_AggDB API Server — RP-315
echo =============================================
echo   ITD_AggDB API Server — RP-315
echo   http://IGS-Intrusion:8000
echo   http://IGS-Intrusion:8000/docs
echo =============================================
echo.
cd /d C:\dev\aggdb\api
C:\dev\aggdb\python314\python.exe main.py
pause
'@ | Set-Content "$RemoteBase\start_aggdb.bat" -Encoding ASCII
Write-Host "  start_aggdb.bat written." -ForegroundColor Green

# 8. Write Windows service installer (optional, for auto-start)
@'
@echo off
REM Install AggDB API as a Windows service using NSSM (if available)
REM Download nssm from https://nssm.cc if needed
REM nssm install AggDB_API "C:\dev\aggdb\python314\python.exe" "C:\dev\aggdb\api\main.py"
REM nssm set AggDB_API AppDirectory "C:\dev\aggdb\api"
REM nssm start AggDB_API
echo Service install is manual — edit this file or run start_aggdb.bat
pause
'@ | Set-Content "$RemoteBase\install_service.bat" -Encoding ASCII

# 9. Firewall rule for port 8000
Write-Host "Adding firewall rule for port 8000..." -ForegroundColor Cyan
Invoke-Command -ComputerName $Target -ScriptBlock {
    $existing = Get-NetFirewallRule -DisplayName "AggDB API" -ErrorAction SilentlyContinue
    if (!$existing) {
        New-NetFirewallRule -DisplayName "AggDB API" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow -Profile Any | Out-Null
        Write-Host "  Firewall rule created." 
    } else {
        Write-Host "  Firewall rule already exists."
    }
}
Write-Host "  Done." -ForegroundColor Green

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "On $Target, run:  C:\dev\aggdb\start_aggdb.bat" -ForegroundColor White
Write-Host "Rebecca accesses: http://IGS-Intrusion:8000" -ForegroundColor White
Write-Host "Swagger docs:     http://IGS-Intrusion:8000/docs" -ForegroundColor White
Write-Host ""
