<#
.SYNOPSIS
    ksnPathCopy - Path copy utility for Windows Explorer context menu.
.DESCRIPTION
    Resolves and copies file/folder paths in four formats:
      PathCopy  - Quoted path using mapped drive letters (default)
      Path      - Unquoted path using mapped drive letters
      UNCPath   - Full UNC path using server hostname
      UNCRaw    - UNC path resolved to server IP with minimal indirection
    Designed for IGS/state agency networks with mapped drives, DFS, and
    mixed UNC/drive-letter environments.
.PARAMETER TargetPath
    The file or folder path to process. Passed by Explorer context menu.
.PARAMETER Mode
    One of: PathCopy, Path, UNCPath, UNCRaw. Default: PathCopy.
.NOTES
    Author:  kawaisunn / ksnlabs
    Version: 1.0.0
    Date:    2026-03-11
    License: Proprietary - Idaho Geological Survey / ksnlabs
    Requires: Windows PowerShell 5.1+ or PowerShell 7+
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetPath,

    [Parameter(Position = 1)]
    [ValidateSet('PathCopy', 'Path', 'UNCPath', 'UNCRaw')]
    [string]$Mode = 'PathCopy'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Drive-mapping cache (populated once per invocation) ──────────────
function Get-DriveMappings {
    $mappings = @{}
    try {
        # WMI method — works for net use, GPO, and persistent mappings
        Get-CimInstance Win32_LogicalDisk -Filter "DriveType=4" -ErrorAction Stop | ForEach-Object {
            if ($_.ProviderName) {
                $mappings[$_.DeviceID.TrimEnd(':')] = $_.ProviderName.TrimEnd('\')
            }
        }
    } catch {
        # Fallback: parse net use output
        $netUse = net use 2>&1 | Where-Object { $_ -match '^\s*(OK|Disconnected|Unavailable)\s+(\w):' }
        foreach ($line in $netUse) {
            if ($line -match '^\s*\S+\s+(\w):\s+(\\\\.+?)\s') {
                $mappings[$Matches[1]] = $Matches[2].TrimEnd('\')
            }
        }
    }

    # Also capture subst drives
    try {
        $subst = subst 2>&1
        foreach ($line in $subst) {
            if ($line -match '^(\w):\\:\s+=>\s+(.+)$') {
                $mappings[$Matches[1]] = $Matches[2].TrimEnd('\')
            }
        }
    } catch {}

    return $mappings
}

# ── Resolve a drive-letter path to its UNC equivalent ────────────────
function Resolve-ToUNC {
    param([string]$FilePath)

    # Already UNC?
    if ($FilePath.StartsWith('\\')) { return $FilePath }

    $driveLetter = $FilePath.Substring(0, 1).ToUpper()
    $remainder   = $FilePath.Substring(2)  # everything after "X:"

    $mappings = Get-DriveMappings
    if ($mappings.ContainsKey($driveLetter)) {
        return $mappings[$driveLetter] + $remainder
    }

    # Administrative share fallback for local drives
    # e.g. C:\dev → \\SERVERNAME\C$\dev
    $hostname = [System.Net.Dns]::GetHostName()
    return "\\$hostname\${driveLetter}`$${remainder}"
}

# ── Resolve UNC hostname to IP ───────────────────────────────────────
function Resolve-HostnameToIP {
    param([string]$Hostname)
    try {
        $addresses = [System.Net.Dns]::GetHostAddresses($Hostname)
        # Prefer IPv4
        $ipv4 = $addresses | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
        if ($ipv4) { return $ipv4.IPAddressToString }
        # Fall back to first address
        return $addresses[0].IPAddressToString
    } catch {
        return $Hostname  # Can't resolve — return original
    }
}

# ── Resolve DFS path to actual server path ───────────────────────────
function Resolve-DFSTarget {
    param([string]$UNCPath)
    try {
        # Use dfsutil if available (Server editions)
        $dfsutil = Get-Command dfsutil -ErrorAction SilentlyContinue
        if ($dfsutil) {
            $output = & dfsutil client property state $UNCPath 2>&1
            # Parse for active target
            $targetLine = $output | Select-String -Pattern 'Active Target' -SimpleMatch
            if ($targetLine -and $targetLine -match ':\s*(\\\\[^\s]+)') {
                return $Matches[1]
            }
        }

        # WMI/CIM fallback: query DFS referral via Win32_DfsTarget
        $dfsTargets = Get-CimInstance -Namespace "root\MicrosoftDfs" -ClassName "DfsrReplicatedFolderInfo" -ErrorAction SilentlyContinue
        # This is unreliable across environments, so we fall through gracefully
    } catch {}

    return $UNCPath  # No DFS resolution available — return as-is
}

# ── Ensure mapped-drive form (reverse of Resolve-ToUNC) ─────────────
function Resolve-ToMappedDrive {
    param([string]$FilePath)

    # If already a drive letter path, return as-is
    if ($FilePath -match '^[A-Za-z]:') { return $FilePath }

    # It's UNC — try to find a matching drive mapping
    $mappings = Get-DriveMappings
    $bestMatch = $null
    $bestLength = 0

    foreach ($kvp in $mappings.GetEnumerator()) {
        $uncRoot = $kvp.Value
        if ($FilePath.StartsWith($uncRoot, [StringComparison]::OrdinalIgnoreCase)) {
            if ($uncRoot.Length -gt $bestLength) {
                $bestMatch  = $kvp.Key
                $bestLength = $uncRoot.Length
            }
        }
    }

    if ($bestMatch) {
        $remainder = $FilePath.Substring($bestLength)
        return "${bestMatch}:${remainder}"
    }

    # No matching mapping — return UNC as-is
    return $FilePath
}

# ── Extract server name from UNC path ────────────────────────────────
function Get-UNCServer {
    param([string]$UNCPath)
    if ($UNCPath -match '^\\\\([^\\]+)') {
        return $Matches[1]
    }
    return $null
}

# ── Main logic ───────────────────────────────────────────────────────

# Normalize the input path
$resolvedPath = $TargetPath.TrimEnd('\')
if (-not $resolvedPath) { exit 1 }

$result = switch ($Mode) {

    'PathCopy' {
        # Quoted path using mapped drive letters
        $mapped = Resolve-ToMappedDrive $resolvedPath
        "`"$mapped`""
    }

    'Path' {
        # Unquoted path using mapped drive letters
        Resolve-ToMappedDrive $resolvedPath
    }

    'UNCPath' {
        # Full UNC path with server hostname
        Resolve-ToUNC $resolvedPath
    }

    'UNCRaw' {
        # UNC path with IP, DFS resolved, minimal indirection
        $uncPath = Resolve-ToUNC $resolvedPath

        # Try DFS resolution first
        $resolved = Resolve-DFSTarget $uncPath

        # Resolve hostname to IP
        $server = Get-UNCServer $resolved
        if ($server) {
            $ip = Resolve-HostnameToIP $server
            $resolved = $resolved -replace [regex]::Escape("\\$server"), "\\$ip"
        }
        $resolved
    }
}

# Copy to clipboard
$result | Set-Clipboard

# Brief toast notification (non-blocking, no external dependencies)
# Uses BurntToast if available, otherwise a fast auto-closing form
try {
    $toastAvailable = Get-Command New-BurntToastNotification -ErrorAction SilentlyContinue
    if ($toastAvailable) {
        New-BurntToastNotification -Text "ksnPathCopy", "$Mode → clipboard" -ExpirationTime (Get-Date).AddSeconds(2) -Silent
    } else {
        # Lightweight WinForms tooltip — appears near system tray, vanishes in 1.5s
        Add-Type -AssemblyName System.Windows.Forms
        $notify = [System.Windows.Forms.NotifyIcon]::new()
        $notify.Icon = [System.Drawing.SystemIcons]::Information
        $notify.Visible = $true
        $notify.ShowBalloonTip(1500, "ksnPathCopy", "$Mode copied", [System.Windows.Forms.ToolTipIcon]::Info)
        Start-Sleep -Milliseconds 1800
        $notify.Dispose()
    }
} catch {
    # Notification is optional — clipboard copy is what matters
}

exit 0
