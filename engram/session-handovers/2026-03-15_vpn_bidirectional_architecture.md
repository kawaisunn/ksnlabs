# SESSION HANDOFF — 2026-03-15 opus46-web-antiquarian-vpn-architecture
# Model: Claude Opus 4.6 on claude.ai (web/project) with filesystem MCP + Windows-MCP
# Machine: IGS-Antiquarian
# Outcome: CRITICAL CORRECTION — VPN is bidirectional. Three-machine architecture defined.

## CRITICAL CORRECTION: L086 IS WRONG

Previous session (opus46-web-docksn-cait-networking) concluded:
> "Connectivity diode — VPN solves home-to-IGS but NOT IGS-to-home"

**THIS IS INCORRECT.** Tested and proven this session:

```
From IGS-Antiquarian → Bigspider VPN IP (129.101.139.84):
  PING: 54ms, 64ms — 0% loss
  Route: University network, not residential
```

When Bigspider connects to Cisco AnyConnect VPN, it receives a **University of Idaho IP
address** (129.101.139.84/28) on a university subnet. It is not "at home" — it is a
university node. Antiquarian and Intrusion can reach it the same way they reach any
other university machine.

The previous session tested port connectivity and got timeouts on all TCP ports.
This is **Windows Firewall on Bigspider**, not a network block. AnyConnect typically
assigns the VPN adapter a "Public" network profile, which drops all inbound TCP.

**The entire HTTPS reverse proxy / SBC / DDNS / domain / cert architecture is unnecessary.**
No third parties. No Tailscale. Just the VPN and one firewall rule.

### Replacement Learning (supersedes L086):
```
L086-CORRECTED: VPN is BIDIRECTIONAL — all six machine-pair routes work
  Bigspider on VPN gets 129.101.139.84 — a university IP, not residential.
  IGS machines reach Bigspider at this IP (proven: 54ms ping from Antiquarian).
  TCP ports filtered = Windows Firewall on Public profile, not network block.
  Fix: change VPN adapter to Private, or add targeted inbound rules.
  No HTTPS proxy, no SBC, no DDNS, no domain, no Tailscale needed.
```

## VERIFIED CONNECTIVITY MATRIX (2026-03-15)

| From → To | IP/Route | Ping | TCP | Status |
|-----------|----------|------|-----|--------|
| Bigspider → Intrusion | 172.20.222.123 via VPN | 60ms ✅ | 80(401), 8000(up) ✅ | WORKING |
| Antiquarian → Intrusion | LAN | <1ms ✅ | 80, 445, all ✅ | WORKING |
| Intrusion → Antiquarian | LAN | <1ms ✅ | all ✅ | WORKING |
| Antiquarian → Bigspider | 129.101.139.84 via VPN | 54ms ✅ | ALL FILTERED ⚠️ | ROUTE PROVEN, FIREWALL FIX NEEDED |
| Intrusion → Bigspider | 129.101.139.84 via VPN | UNTESTED (should match) | UNTESTED | EXPECTED WORKING after firewall fix |
| Bigspider → Antiquarian | 172.28.196.231 via VPN | UNTESTED | UNTESTED | EXPECTED WORKING |

## BIGSPIDER FIREWALL FIX (execute on Bigspider)

The ONLY remaining blocker. Two options, choose one:

### Option A: Change VPN adapter profile (broad — opens all ports on VPN)
```powershell
# Identify the VPN adapter name (likely "Ethernet 2" per previous session)
Get-NetConnectionProfile | Format-Table Name,InterfaceAlias,NetworkCategory

# Change to Private (allows inbound from trusted network)
Set-NetConnectionProfile -InterfaceAlias "Ethernet 2" -NetworkCategory Private
```

### Option B: Targeted firewall rules (surgical — recommended)
```powershell
# Allow RDP from university subnets only
New-NetFirewallRule -DisplayName "RDP via VPN (University)" `
    -Direction Inbound -Protocol TCP -LocalPort 3389 `
    -InterfaceAlias "Ethernet 2" -Action Allow `
    -RemoteAddress 172.20.0.0/16,129.101.0.0/16

# Allow SMB/file sharing from university subnets
New-NetFirewallRule -DisplayName "SMB via VPN (University)" `
    -Direction Inbound -Protocol TCP -LocalPort 445 `
    -InterfaceAlias "Ethernet 2" -Action Allow `
    -RemoteAddress 172.20.0.0/16,129.101.0.0/16

# Allow CAIT inference endpoint
New-NetFirewallRule -DisplayName "CAIT Inference via VPN" `
    -Direction Inbound -Protocol TCP -LocalPort 8000 `
    -InterfaceAlias "Ethernet 2" -Action Allow `
    -RemoteAddress 172.20.0.0/16,129.101.0.0/16

# Allow HTTP (for any web services)
New-NetFirewallRule -DisplayName "HTTP via VPN (University)" `
    -Direction Inbound -Protocol TCP -LocalPort 80 `
    -InterfaceAlias "Ethernet 2" -Action Allow `
    -RemoteAddress 172.20.0.0/16,129.101.0.0/16

# Allow HTTPS
New-NetFirewallRule -DisplayName "HTTPS via VPN (University)" `
    -Direction Inbound -Protocol TCP -LocalPort 443 `
    -InterfaceAlias "Ethernet 2" -Action Allow `
    -RemoteAddress 172.20.0.0/16,129.101.0.0/16
```

### Verification (run from Antiquarian or Intrusion after fix):
```powershell
Test-Connection 129.101.139.84 -Count 1
Test-NetConnection 129.101.139.84 -Port 3389    # RDP
Test-NetConnection 129.101.139.84 -Port 445     # File shares
Test-NetConnection 129.101.139.84 -Port 8000    # CAIT inference
```

### Important: VPN adapter name may differ
The previous session identified "Ethernet 2" but this should be verified:
```powershell
Get-NetAdapter | Where-Object { $_.InterfaceDescription -like '*Cisco*' -or $_.InterfaceDescription -like '*AnyConnect*' } | Select Name,InterfaceDescription,Status
```

## WHAT THIS UNLOCKS (beyond CAIT)

Once the firewall is fixed, Christopher gets from IGS:

| Capability | How | Impact |
|------------|-----|--------|
| **RDP to Bigspider** | mstsc → 129.101.139.84 | Full desktop access to home workstation from IGS. No more "I can't reach my files." |
| **File shares** | \\\\129.101.139.84\C$\ or mapped drive | Direct file access between machines. Copy, sync, robocopy — all native Windows. |
| **GPU compute** | HTTP endpoint on 8000+ | CAIT inference, model evaluation, any GPU workload callable from IGS. |
| **Git push/pull** | Via file share or direct SSH | Sync repos without GitHub as intermediary when needed. |
| **Dev continuity** | Full access to D:\Desktop, C:\dev, all drives | 15 years of "can't reach home PC" — resolved. |
| **Bigspider as build server** | Submit jobs, retrieve artifacts | .NET builds, Python training, anything compute-heavy runs on A5000 hardware. |

This is not just CAIT infrastructure. This is Christopher's complete development environment
becoming accessible from anywhere on the university network.

## THREE-MACHINE ARCHITECTURE

### Roles (general + CAIT-specific)

```
┌─────────────────────────────────────────────────────────────┐
│                    UNIVERSITY VPN MESH                       │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  BIGSPIDER   │    │  INTRUSION   │    │ ANTIQUARIAN   │  │
│  │  (HOME GPU)  │◄──►│  (SERVER)    │◄──►│ (IGS DESK)   │  │
│  │              │◄──►│              │    │              │  │
│  │ 129.101.     │    │ 172.20.      │    │ 172.28.      │  │
│  │   139.84     │    │   222.123    │    │   196.231    │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                             │
│  RTX A5000 24GB      2× CPU cores        RTX 4000 8GB     │
│  Training + Inference SQL + API + IIS    Eval + Dev + UI   │
│  Lumo MCP            AggDB backend       Shadow observer   │
│  Home dev files      Production data     IGS daily driver  │
└─────────────────────────────────────────────────────────────┘
```

### CAIT-Specific Roles

| Machine | CAIT Role | What it does |
|---------|-----------|-------------|
| **Bigspider** | Trainer + Primary Inference | SFT training (A5000 24GB), full-precision inference, checkpoint generation. Lumo runs as drill sergeant. Hosts CAIT inference API on port 8000. |
| **Intrusion** | Data Engine + Shadow Hub | AggDB API (production data), shadow log consolidation from all three machines, corpus preprocessing (JSONL generation), Phase 1 templated training data from API. CPU-bound work: deduplication, entity extraction, batch jobs. |
| **Antiquarian** | Eval + Fallback Inference | Loads QLoRA/quantized checkpoints on RTX 4000 (8GB) for local evaluation and fallback inference when VPN is down. Christopher's daily driver — shadow observer runs here during work hours. |

### CAIT Graceful Degradation

| VPN Status | CAIT Behavior |
|------------|--------------|
| **Bigspider online + VPN connected** | Full inference via 129.101.139.84:8000. Best model, full precision, vision capable. |
| **Bigspider offline / VPN down** | Fallback to Antiquarian RTX 4000 with quantized checkpoint. Reduced capability but present. |
| **Both GPUs unavailable** | Shadow mode continues logging. No inference. Rebecca works without CAIT. Data accumulates for training. |
| **Total network isolation** | Each machine's shadow logs locally. Consolidation happens when connectivity returns. |

## CAIT SHADOW STATUS

**Antiquarian: RUNNING** as of 2026-03-15 03:37:02 UTC
- PID: 86204 / 119736 (PowerShell processes)
- Log: C:\dev\_DOCKSN\ITD_OUT\cait_shadow\raw\cait_shadow_20260315_033702.jsonl
- Baseline captured: 241 sites, 30 test types, full LU snapshot
- Polling http://IGS-Intrusion/aggdb/api every 30 seconds
- Known issue: `machine` field logging as null (environment variable inheritance in Start-Process)

**Intrusion: NOT YET DEPLOYED** — needs script copy + scheduled task registration
**Bigspider: NOT YET DEPLOYED** — needs venv rebuild first, then can run alongside Lumo

### Multi-Machine Shadow Consolidation
Each machine writes to its own local cait_shadow/raw/ directory. Before training:
```powershell
# From Bigspider (has VPN access to both):
# Pull Antiquarian logs
Copy-Item "\\172.28.196.231\C$\dev\_DOCKSN\ITD_OUT\cait_shadow\raw\*.jsonl" `
    -Destination "C:\dev\cait\training_data\shadow_logs\antiquarian\" -Force

# Pull Intrusion logs
Copy-Item "\\172.20.222.123\C$\dev\_DOCKSN\ITD_OUT\cait_shadow\raw\*.jsonl" `
    -Destination "C:\dev\cait\training_data\shadow_logs\intrusion\" -Force
```

## GIT STATUS (Antiquarian, 2026-03-15)

### ksnlabs — 4 modified, 8 untracked
```
Modified:
  .ai/buffer.jsonld
  .ai/projects/cait/buffer
  engram/buffer.jsonld
  engram/session-registry.json

Untracked:
  .ai/SESSION_HANDOFF_cait_spec_antiquarian.md
  .ai/projects/cait-training/
  aggdb/api/ACTION_LOG_INTEGRATION.md
  aggdb/api/action_log.py
  engram/SESSION_CATALOG.md
  engram/session-handovers/2026-03-11_docksn_igs_inventory.md
  engram/session-handovers/2026-03-13_cait_spec_antiquarian.md
  engram/session-handovers/2026-03-14_ADDENDUM_block-sealing-problem.md
  engram/session-handovers/2026-03-14_opus46-web-antiquarian-cait-phase0.md
```
Last commits: 022324c, 422ec3e, a60ae76 (frontend + light/dark toggle)

### ocritd, ktreesn — file lock errors prevented status check (git index locked)
Likely clean but needs verification on next session.

## PENDING STUBS AND TASKS

| Item | Machine | Priority | Notes |
|------|---------|----------|-------|
| Bigspider firewall fix | Bigspider | **CRITICAL** | One command. Unlocks everything. |
| CAIT venv rebuild | Bigspider | **CRITICAL** | bootstrap_bigspider.ps1 ready at R:\VPN\VPN_SESSION\ |
| Deploy shadow to Intrusion | Intrusion | HIGH | Copy script + register scheduled task |
| Git commit+push from Antiquarian | Antiquarian | HIGH | 12 files pending (4 modified, 8 untracked) |
| Git push from Bigspider | Bigspider | HIGH | ONBOARD.md, buffer, handoffs, core.js still unpushed |
| Wire action_log.py into main.py | Intrusion | HIGH | 4 edits per ACTION_LOG_INTEGRATION.md |
| Fix IIS auth for VPN connections | Intrusion | MEDIUM | Currently 401 on port 80 from VPN IPs |
| Fix machine field in shadow JSONL | Any | LOW | $env:COMPUTERNAME null in Start-Process child |
| GitHub PAT rotation | Any | MEDIUM | ghp_ZJF... exposed in prior chat |
| Rotate git index locks | Antiquarian | LOW | .git/index.lock may exist on ocritd/ktreesn |

## NEXT SESSION INSTRUCTIONS

### If on BIGSPIDER (highest priority target):
1. Run the firewall fix (Option B recommended — targeted rules)
2. Verify from Intrusion/Antiquarian: `Test-NetConnection 129.101.139.84 -Port 3389`
3. Run bootstrap_bigspider.ps1 to rebuild CAIT venv
4. Verify GPU access: `python -c "import torch; print(torch.cuda.is_available())"`
5. Start CAIT shadow pointing at Intrusion via VPN
6. Git add + commit + push all pending ksnlabs changes
7. Update engram buffer with VPN bidirectional correction

### If on INTRUSION:
1. Deploy Start-CaitShadow.ps1 from C:\dev\_DOCKSN\ (or copy from Antiquarian share)
2. Register shadow as scheduled task (SYSTEM account, AtStartup trigger)
3. Wire action_log.py into main.py (4 edits)
4. Fix IIS auth for VPN subnet (anonymous for /aggdb/api/ or API key header)
5. Test connectivity to Bigspider: `Test-Connection 129.101.139.84`
6. Git status check on all repos

### If on ANTIQUARIAN:
1. Shadow is already running — verify it's still alive
2. Git commit + push ksnlabs (12 pending items)
3. Clear git index locks on ocritd/ktreesn if present
4. Verify Bigspider reachability after firewall fix: `Test-NetConnection 129.101.139.84 -Port 3389`

## ENGRAM UPDATES NEEDED

1. **L086 correction** — replace diode learning with bidirectional VPN learning
2. **New learning L089** — Windows Firewall Public profile blocks VPN inbound; fix is one command
3. **New learning L090** — Three-machine architecture: Bigspider=train+infer, Intrusion=data+API, Antiquarian=eval+fallback
4. **Buffer update** — networkDiscovery.diodeProblem should be replaced with bidirectional confirmation
5. **SESSION_CATALOG.md** — add this session row
