# Configure IIS auth for AggDB - using full section paths
$appcmd = "$env:SystemRoot\System32\inetsrv\appcmd.exe"

# Auth is set (anon=off, win=on). Now set URL authorization via full path.
& $appcmd set config "Default Web Site/aggdb" -section:system.webServer/security/authorization /~"" /commit:apphost
& $appcmd set config "Default Web Site/aggdb" -section:system.webServer/security/authorization /+"[accessType='Allow',users='IGS2\ctate']" /commit:apphost
& $appcmd set config "Default Web Site/aggdb" -section:system.webServer/security/authorization /+"[accessType='Allow',users='IGS2\rkanderson']" /commit:apphost
& $appcmd set config "Default Web Site/aggdb" -section:system.webServer/security/authorization /+"[accessType='Allow',users='IGS2\cberti']" /commit:apphost
& $appcmd set config "Default Web Site/aggdb" -section:system.webServer/security/authorization /+"[accessType='Allow',users='IGS2\lknudsen']" /commit:apphost
& $appcmd set config "Default Web Site/aggdb" -section:system.webServer/security/authorization /+"[accessType='Deny',users='*']" /commit:apphost

Write-Host "---VERIFY AUTH---"
& $appcmd list config "Default Web Site/aggdb" -section:system.webServer/security/authentication/windowsAuthentication
& $appcmd list config "Default Web Site/aggdb" -section:system.webServer/security/authentication/anonymousAuthentication
& $appcmd list config "Default Web Site/aggdb" -section:system.webServer/security/authorization
