# SESSION HANDOFF: 2026-03-19
## Machine: IGS-Intrusion (RDP) | Model: Claude Opus 4.6 (claude.ai)

### Completed
1. **db.js fix** - Clean here-string deployment. msnodesqlv8 Windows Auth. IGS2\ctate, localhost\SQLEXPRESS, ITD_AggDB, SQL 2022 v16. 18 routes confirmed via PowerShell.
2. **Git initialized** - C:\dev\_DOCKSN, commit 1d97eb8, 32 files. No remote.
3. **Nightly backup** - Task Scheduler ITD_AggDB_Nightly_Backup, 2AM daily. SQL Agent won't start (Express). Script: scripts\Backup-ITDAggDB.cmd.
4. **ToiQaDon scaffolded** - C:\dev\toiqadon\, Electron + keywrds dev window. Inert.
5. **Decisions** - TQde/TQdo = one app + AD roles. Launcher = C# exe (deferred).

### Learnings L097-L102
- L097: SQL Agent won't start on Express, use Task Scheduler
- L098: Chrome fetch fails on Intrusion, PowerShell works
- L099: TQde + TQdo = one app, AD filtering
- L100: Launcher = C# exe; ToiQaDon = dev console only
- L101: Here-string + WriteAllText = safe JS deployment
- L102: Git init'd, no remote, spring cleaning sorts location

### Next Session
1. Git status + commit
2. Verify ToiQa + CAIT shadow
3. Dev copy ITD_AggDB / launcher / sandbox for Liam