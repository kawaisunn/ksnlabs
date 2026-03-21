# Session Handoff: 2026-03-19 backup-shadow-fix
**Machine**: IGS-Antiquarian (web Claude, Opus 4.6)
**Duration**: ~45 min
**Next session**: Likely IGS-Intrusion

## Accomplished

1. **CAIT shadow v2.1 fix + restart** — Old process (PID 86204) had been running since 03-15 but logging 11,167 identical ConvertTo-Json errors. Root cause: `$sites | ConvertTo-Json` fails on empty arrays (sends nothing through pipeline). Fixed to `-InputObject`. Also added: null-safe fingerprinting, `Get-SiteList` helper, error-streak throttling. New PID 209604, collecting real data (241 sites, 30 test types baselined).

2. **SQL instance correction** — Engram incorrectly stated "MSSQLSERVER(v15)+SQLSERVER2022(v16), NOT SQLEXPRESS." Production is actually `SQLEXPRESS` (v16). Verified via FastAPI db.py connection string. Cloud memory entries #3 and #8 corrected. Intrusion has 10 SQL instances total from IGS data centralization history.

3. **Immediate backup** — Manual backup taken: `ITD_AggDB_20260319_011903.bak` (10.02 MB). No backups had existed since Feb 24.

4. **Automated backup infrastructure deployed**:
   - `ITD_AggDB_DailyBackup` on Intrusion: SYSTEM, daily 2AM, 14-day retention, `C:\dev\aggdb\MSSQL16.SQLEXPRESS\MSSQL\Backup\`
   - `ITD_AggDB_SyncToRift` on Antiquarian: ctate.IGS2, daily 3AM, pulls to `\\igs-rift2.igs.uidaho.edu\ITD_data_confidential$\DB_Backups\`, 7-day retention
   - SYSTEM granted db_backupoperator on ITD_AggDB (was failing without it)
   - Both tasks tested and confirmed working. First backup on Rift confirmed.

5. **Dev DB restored** — `ITD_AggDB_DEV` on SQLEXPRESS, cloned from today's backup. 241 sites, 37 Rebecca records, full schema. Ready for Doksn write-path testing.

6. **Rebecca's work cataloged** — 37 records across 9 D3 sites (March 13-18). Types: 13 QAMS, 12 IR142, 9 TestReport, 3 Plat. Source PDFs at `J:\ITD\D3\{SiteID}\`. This is the comparison dataset for Doksn.

## Corrections Made
- Cloud memory #3: SQLEXPRESS is production (was incorrectly listing MSSQLSERVER/SQLSERVER2022)
- Cloud memory #8: Same SQL instance correction + removed "NOT SQLEXPRESS"
- Buffer v1.0.18: Full rewrite with correct DB state, backup infrastructure, Rebecca activity summary

## Scripts Created/Modified
- `C:\dev\_DOCKSN\Start-CaitShadow.ps1` — v2.1 (ConvertTo-Json fix, null safety, error throttling)
- `C:\dev\_DOCKSN\Backup-ITDAggDB.ps1` — NEW: backup script for scheduled task
- `C:\dev\_DOCKSN\Register-AggDBBackupTask.ps1` — NEW: deploys backup task to Intrusion
- `C:\dev\_DOCKSN\Sync-AggDBBackupToRift.ps1` — NEW: pull-to-Rift sync script

## Next Session Priority (INTRUSION)

1. **db.js fix** — Clean copy on Bigspider `C:\dev\_DOCKSN\server\db.js`. Paste via here-string from `C:\dev\ksnlabs\.ai\NEXT_SESSION_db_fix.md`. Then `node --watch server/index.js`.
2. **Doksn comparison** — Process Rebecca's source PDFs from `J:\ITD\D3\` through Doksn pipeline, compare extracted metadata against her 37 manual Rec entries in ITD_AggDB_DEV.
3. **Wire action_log.py** into main.py (4 edits per ACTION_LOG_INTEGRATION.md)
4. **Deploy CAIT shadow to Intrusion** — Copy v2.1 script, register as scheduled task
5. **Documentation** — Update grey paper v3, include backup schedule

## Known Issues
- Rift sync only runs when ctate is logged on to Antiquarian (network credential requirement). Primary backup on Intrusion runs regardless.
- RESTORE VERIFYONLY warns under SYSTEM (cosmetic — lacks CREATE DATABASE on master)
- ToiQa down on Intrusion (port 3000 not responding, needs db.js fix)
- Git: uncommitted changes on Antiquarian and Bigspider

## Learnings
L097-L103 written to `session_2026-03-19_learnings.json`
