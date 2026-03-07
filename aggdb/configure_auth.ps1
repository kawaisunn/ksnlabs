# Configure IIS auth for AggDB app
# Run on IGS-Intrusion

# 1. Simplify web.config to just rewrite rules
@'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="AggDB_Frontend" stopProcessing="true">
          <match url="^$" />
          <action type="Rewrite" url="http://localhost:8000/" />
        </rule>
        <rule name="AggDB_All" stopProcessing="true">
          <match url="(.*)" />
          <action type="Rewrite" url="http://localhost:8000/{R:1}" />
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
'@ | Set-Content "C:\dev\aggdb\iis_aggdb\web.config" -Encoding UTF8

$appcmd = "$env:SystemRoot\System32\inetsrv\appcmd.exe"

# 2. Set auth at app level via appcmd
& $appcmd set config "Default Web Site/aggdb" /section:anonymousAuthentication /enabled:false /commit:apphost
& $appcmd set config "Default Web Site/aggdb" /section:windowsAuthentication /enabled:true /commit:apphost

# 3. Clear and set authorization
& $appcmd set config "Default Web Site/aggdb" /section:authorization /-"[users='*',accessType='Allow']" /commit:apphost 2>$null
& $appcmd set config "Default Web Site/aggdb" /section:authorization /-"[users='*',accessType='Deny']" /commit:apphost 2>$null

& $appcmd set config "Default Web Site/aggdb" /section:authorization /+"[accessType='Allow',users='IGS2\ctate']" /commit:apphost
& $appcmd set config "Default Web Site/aggdb" /section:authorization /+"[accessType='Allow',users='IGS2\rkanderson']" /commit:apphost
& $appcmd set config "Default Web Site/aggdb" /section:authorization /+"[accessType='Allow',users='IGS2\cberti']" /commit:apphost
& $appcmd set config "Default Web Site/aggdb" /section:authorization /+"[accessType='Allow',users='IGS2\lknudsen']" /commit:apphost
& $appcmd set config "Default Web Site/aggdb" /section:authorization /+"[accessType='Deny',users='*']" /commit:apphost

Write-Host "Auth configured. Testing..."
& $appcmd list config "Default Web Site/aggdb" /section:authorization
