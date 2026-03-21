# NEXT SESSION: Fix DB Connection on Intrusion
# This file is THE FIRST THING to address. Memory says so.
# Location of this file: C:\dev\ksnlabs\.ai\NEXT_SESSION_db_fix.md
# Clean db.js source: C:\dev\_DOCKSN\server\db.js (on Bigspider)
#
# WHAT HAPPENED: db.js was written through ToiQa's /api/fs/write
# endpoint which corrupts JavaScript string escaping. The file
# must be written directly on Intrusion via PowerShell Set-Content.
#
# OPTION A: If session is on Intrusion (Claude Desktop or RDP)
# ─────────────────────────────────────────────────────────────
# Paste this ENTIRE block into PowerShell on Intrusion:

# Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
# Start-Sleep -Seconds 2
# @'
# const sql = require('mssql/msnodesqlv8');
# let pool = null, connected = false, lastError = null, driverUsed = 'msnodesqlv8';
# async function connect(settings, broadcast) {
#   if (pool) { try { await pool.close(); } catch(e) {} pool = null; connected = false; }
#   lastError = null;
#   const server = settings.dbServer || 'localhost';
#   const config = { server, database: settings.dbName || 'ITD_AggDB', driver: 'msnodesqlv8', options: { trustedConnection: true, trustServerCertificate: true }, connectionTimeout: 15000, requestTimeout: 30000 };
#   if (broadcast) broadcast('console', { level: 'info', msg: '[db] Connecting via msnodesqlv8 to ' + server + '...' });
#   try {
#     pool = new sql.ConnectionPool(config);
#     await pool.connect();
#     connected = true; driverUsed = 'msnodesqlv8 (Windows Auth)';
#     if (broadcast) { broadcast('console', { level: 'info', msg: '[db] Connected to ' + config.database }); broadcast('db_status', getStatus(settings)); }
#     return { ok: true, driver: driverUsed };
#   } catch(e) {
#     lastError = e.message; connected = false;
#     if (broadcast) { broadcast('console', { level: 'error', msg: '[db] ' + e.message }); broadcast('db_status', getStatus(settings)); }
#     return { ok: false, error: e.message, driver: driverUsed };
#   }
# }
# function getStatus(s) { return { configured: !!(s.dbServer && s.dbName), server: s.dbServer||'(not set)', database: s.dbName||'(not set)', connected, driver: driverUsed, error: lastError }; }
# async function query(q, params) { if (!pool||!connected) throw new Error('Not connected'); const r = pool.request(); if (params) for (const [k,v] of Object.entries(params)) r.input(k,v); return await r.query(q); }
# function getPool() { return pool; }
# module.exports = { connect, getStatus, query, getPool, sql };
# '@ | Set-Content C:\dev\_DOCKSN\server\db.js -Encoding UTF8
# cd C:\dev\_DOCKSN
# node --watch server/index.js

# Then from a SECOND PowerShell window:
# Invoke-RestMethod -Uri "http://localhost:3000/api/db/test" -Method POST -ContentType "application/json" -Body '{"server":"localhost","database":"ITD_AggDB","auth":"windows"}' -TimeoutSec 30

# OPTION B: If session is on Bigspider with VPN
# ─────────────────────────────────────────────────────────────
# Clean db.js already exists at C:\dev\_DOCKSN\server\db.js on Bigspider.
# Copy it to Intrusion. Requires either:
#   a) Admin PowerShell to set TrustedHosts then use Invoke-Command
#   b) RDP to Intrusion and paste Option A
#   c) ToiQa must be running first (chicken-and-egg if db.js is broken)
#
# For admin PowerShell on Bigspider:
# Set-Item WSMan:\localhost\Client\TrustedHosts -Value '172.20.222.123' -Force
# Then: Copy the file content via Invoke-Command

# OPTION C: If session is on Antiquarian (IGS domain)
# ─────────────────────────────────────────────────────────────
# Antiquarian has UNC access to Intrusion. Copy from Bigspider first:
# Copy-Item "\\BIGSPIDER\c$\dev\_DOCKSN\server\db.js" "\\IGS-Intrusion\c$\dev\_DOCKSN\server\db.js" -Force
# Or just paste Option A via RDP to Intrusion.

# AFTER DB IS CONNECTED:
# 1. Spin up ITD_AggDB dev copy for safe testing
# 2. Set up full backup schedule for production ITD_AggDB
# 3. Continue sprint priorities per buffer.jsonld

# LEARNING (engram candidate):
# NEVER write JavaScript files through ToiQa /api/fs/write.
# String escaping in JS content gets corrupted passing through a JS API.
# PowerShell @'...'@ here-strings or direct filesystem writes are safe.
