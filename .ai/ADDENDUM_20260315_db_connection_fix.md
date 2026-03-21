# ADDENDUM — DB Connection Fix (for next Claude session on Intrusion)
# Written 2026-03-15 by Opus 4.6 on Bigspider
# DO NOT overwrite buffer.jsonld or any SESSION_HANDOFF files

## PROBLEM
server/db.js on Intrusion has escaping corruption from being written through
the ToiQa filesystem API. The mssql/msnodesqlv8 driver throws:
"The config.server property is required and must be of type string."

## WHAT TO DO (in order)

### Step 1: Kill any running node processes
```powershell
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
```

### Step 2: Rewrite server/db.js with clean PowerShell here-string
```powershell
@'
const sql = require('mssql/msnodesqlv8');
let pool = null, connected = false, lastError = null, driverUsed = 'msnodesqlv8';

async function connect(settings, broadcast) {
  if (pool) { try { await pool.close(); } catch(e) {} pool = null; connected = false; }
  lastError = null;
  const server = settings.dbServer || 'localhost';
  const config = { server, database: settings.dbName || 'ITD_AggDB', driver: 'msnodesqlv8', options: { trustedConnection: true, trustServerCertificate: true }, connectionTimeout: 15000, requestTimeout: 30000 };
  if (broadcast) broadcast('console', { level: 'info', msg: '[db] Connecting via msnodesqlv8 to ' + server + '...' });
  try {
    pool = new sql.ConnectionPool(config);
    await pool.connect();
    connected = true; driverUsed = 'msnodesqlv8 (Windows Auth)';
    if (broadcast) { broadcast('console', { level: 'info', msg: '[db] Connected to ' + config.database }); broadcast('db_status', getStatus(settings)); }
    return { ok: true, driver: driverUsed };
  } catch(e) {
    lastError = e.message; connected = false;
    if (broadcast) { broadcast('console', { level: 'error', msg: '[db] ' + e.message }); broadcast('db_status', getStatus(settings)); }
    return { ok: false, error: e.message, driver: driverUsed };
  }
}
function getStatus(s) { return { configured: !!(s.dbServer && s.dbName), server: s.dbServer||'(not set)', database: s.dbName||'(not set)', connected, driver: driverUsed, error: lastError }; }
async function query(q, params) { if (!pool||!connected) throw new Error('Not connected'); const r = pool.request(); if (params) for (const [k,v] of Object.entries(params)) r.input(k,v); return await r.query(q); }
function getPool() { return pool; }
module.exports = { connect, getStatus, query, getPool, sql };
'@ | Set-Content C:\dev\_DOCKSN\server\db.js -Encoding UTF8
```

### Step 3: Start ToiQa with auto-reload
```powershell
cd C:\dev\_DOCKSN
node --watch server/index.js
```

### Step 4: Test from a SEPARATE PowerShell window
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/db/test" -Method POST -ContentType "application/json" -Body '{"server":"localhost","database":"ITD_AggDB","auth":"windows"}'
```

### Step 5: If connected, verify tables
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/db/tables"
```

## WHAT NOT TO DO
- Do NOT overwrite buffer.jsonld
- Do NOT overwrite any SESSION_HANDOFF_*.md files
- Do NOT rewrite server/index.js (routes are correct, only db.js needs fixing)
- Do NOT rewrite public/index.html (frontend patches are correct)
- Do NOT reinstall msnodesqlv8 (already installed, npm confirmed)

## CONTEXT FOR NEXT SESSION
- msnodesqlv8 is installed (Deploy-ToiQaServer.ps1 confirmed)
- ODBC 17 + 18 both present
- AD domain: igs2.idahogeology.org (confirmed from NetSetup.LOG)
- SQL instances: MSSQLSERVER (v15 default), SQLSERVER2022 (v16)
- settings.json already has dbServer: "localhost"
- server/index.js has real routes: POST /api/db/test, /api/db/connect, /api/db/query, GET /api/db/tables
- public/index.html Test Connection button calls POST /api/db/test

## AFTER DB IS CONNECTED — NEXT PRIORITIES
1. Spin up ITD_AggDB dev copy for safe testing
2. Set up full backup schedule for production ITD_AggDB
3. Then proceed to sprint priorities in buffer.jsonld
