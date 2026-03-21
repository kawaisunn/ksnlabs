# Test-BigspiderToIntrusion.ps1
# Run on BIGSPIDER to diagnose connectivity to IGS-Intrusion
# Drop into PowerShell and paste, or save and run

$target = "172.20.222.123"
$hostname = "IGS-Intrusion"
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  BIGSPIDER -> INTRUSION Connectivity Diagnostic" -ForegroundColor Cyan
Write-Host "  Target: $target ($hostname)" -ForegroundColor Cyan
Write-Host "  $(Get-Date)" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# 0. VPN check
Write-Host "[0] VPN Adapter Check" -ForegroundColor Yellow
$vpn = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match 'Cisco|AnyConnect|VPN' -or $_.Name -match 'Ethernet 2' }
if ($vpn) {
    Write-Host "  OK: VPN adapter found - $($vpn.Name) ($($vpn.Status))" -ForegroundColor Green
    $vpnIp = (Get-NetIPAddress -InterfaceIndex $vpn.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    Write-Host "  VPN IP: $vpnIp" -ForegroundColor Gray
} else {
    Write-Host "  FAIL: No VPN adapter found. Connect AnyConnect first." -ForegroundColor Red
    return
}
Write-Host ""

# 1. Ping
Write-Host "[1] ICMP Ping" -ForegroundColor Yellow
$ping = Test-Connection $target -Count 2 -ErrorAction SilentlyContinue
if ($ping) {
    $avg = ($ping | Measure-Object -Property Latency -Average).Average
    Write-Host "  OK: $([math]::Round($avg))ms average" -ForegroundColor Green
} else {
    Write-Host "  FAIL: No ping response" -ForegroundColor Red
}
Write-Host ""

# 2. Port 80 (IIS)
Write-Host "[2] TCP Port 80 (IIS)" -ForegroundColor Yellow
$tcp80 = Test-NetConnection $target -Port 80 -WarningAction SilentlyContinue
Write-Host "  $( if ($tcp80.TcpTestSucceeded) {'OK: Port 80 open'} else {'FAIL: Port 80 closed'} )" -ForegroundColor $( if ($tcp80.TcpTestSucceeded) {'Green'} else {'Red'} )
Write-Host ""

# 3. Port 8000 (FastAPI)
Write-Host "[3] TCP Port 8000 (FastAPI direct)" -ForegroundColor Yellow
$tcp8000 = Test-NetConnection $target -Port 8000 -WarningAction SilentlyContinue
Write-Host "  $( if ($tcp8000.TcpTestSucceeded) {'OK: Port 8000 open'} else {'FAIL: Port 8000 closed'} )" -ForegroundColor $( if ($tcp8000.TcpTestSucceeded) {'Green'} else {'Red'} )
Write-Host ""

# 4. Port 3000 (ToiQa)
Write-Host "[4] TCP Port 3000 (ToiQa)" -ForegroundColor Yellow
$tcp3000 = Test-NetConnection $target -Port 3000 -WarningAction SilentlyContinue
Write-Host "  $( if ($tcp3000.TcpTestSucceeded) {'OK: Port 3000 open'} else {'FAIL: Port 3000 closed'} )" -ForegroundColor $( if ($tcp3000.TcpTestSucceeded) {'Green'} else {'Red'} )
Write-Host ""

# 5. SQL Server Browser (UDP 1434)
Write-Host "[5] UDP 1434 (SQL Browser)" -ForegroundColor Yellow
try {
    $udp = New-Object System.Net.Sockets.UdpClient
    $udp.Client.ReceiveTimeout = 3000
    $bytes = [byte[]](0x02)
    $udp.Send($bytes, $bytes.Length, $target, 1434) | Out-Null
    $ep = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
    $response = $udp.Receive([ref]$ep)
    $info = [System.Text.Encoding]::ASCII.GetString($response)
    Write-Host "  OK: SQL Browser responded" -ForegroundColor Green
    Write-Host "  Instance info: $($info.Substring(0, [Math]::Min(200, $info.Length)))" -ForegroundColor Gray
    $udp.Close()
} catch {
    Write-Host "  FAIL: SQL Browser not reachable (UDP 1434)" -ForegroundColor Red
    Write-Host "  This means SQLEXPRESS named instance discovery won't work remotely" -ForegroundColor DarkYellow
}
Write-Host ""

# 6. Port 1433 (SQL default)
Write-Host "[6] TCP Port 1433 (SQL default)" -ForegroundColor Yellow
$tcp1433 = Test-NetConnection $target -Port 1433 -WarningAction SilentlyContinue
Write-Host "  $( if ($tcp1433.TcpTestSucceeded) {'OK: Port 1433 open'} else {'INFO: Port 1433 closed (expected for named instance)'} )" -ForegroundColor $( if ($tcp1433.TcpTestSucceeded) {'Green'} else {'DarkYellow'} )
Write-Host ""

# 7. HTTP API test
Write-Host "[7] HTTP API Health Check" -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "http://$($hostname)/aggdb/api/health" -UseDefaultCredentials -TimeoutSec 10
    Write-Host "  OK: API healthy" -ForegroundColor Green
    Write-Host "  Response: $($r | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    $status = $_.Exception.Response.StatusCode.value__
    if ($status -eq 401) {
        Write-Host "  PARTIAL: Server responds but demands auth (401)" -ForegroundColor DarkYellow
        Write-Host "  UseDefaultCredentials may not pass through VPN" -ForegroundColor DarkYellow
    } else {
        Write-Host "  FAIL: $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Host ""

# 8. Summary
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "  VPN: $( if ($vpn.Status -eq 'Up') {'Connected'} else {'Down'} )" 
Write-Host "  Ping: $( if ($ping) {'OK'} else {'FAIL'} )"
Write-Host "  IIS (80): $( if ($tcp80.TcpTestSucceeded) {'OK'} else {'FAIL'} )"
Write-Host "  FastAPI (8000): $( if ($tcp8000.TcpTestSucceeded) {'OK'} else {'FAIL'} )"
Write-Host "  ToiQa (3000): $( if ($tcp3000.TcpTestSucceeded) {'OK'} else {'FAIL'} )"
Write-Host "  SQL (1433): $( if ($tcp1433.TcpTestSucceeded) {'OK'} else {'N/A (named)'} )"
Write-Host "=" * 60 -ForegroundColor Cyan
