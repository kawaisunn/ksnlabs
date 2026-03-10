# Session Handover — 2026-03-10
## opus46-desktop-docksn-lumo-integration-001

### What Was Done
1. **DOCKSN project bootstrap** — reviewed `.objectives.json`, `.objectives_notIntegrated.txt`, all component states (cait, ktreesn, keywrds, ocritd, aggdb)
2. **Lumo Electron app cleanup** — identified 9GB recursive build artifact (installer packaging its own output). Cut to D:\, rebuilt clean from 6 source files using `rebuild_lumo_clean.ps1`
3. **Three-AI workspace built** — added Claude (claude.ai webview), Lumo (lumo.proton.me webview), and CAIT (local control panel with model status, shadow observer stubs) as tabs in the Electron app. All share the same backend (main.js IPC: filesystem, engram, git, scripts, permissions)
4. **Settings parser fix** — `loadSettings()` patched to strip `//` and `/* */` comments from settings.json before `JSON.parse()`. Inline comments preserved for human readability
5. **CAIT architecture designed** — observer → labeler → training pipeline. Phi-3.5 Vision model weights confirmed on disk. Python deps (torch, transformers) not yet installed
6. **Identified DC instability** — Desktop Commander MCP dropped repeatedly throughout session. Proposed replacing DC with Lumo Electron app as MCP server for Claude Desktop

### Key Decisions
- **Lumo app is the platform** — not just a dashboard, it's CAIT's home and the universal AI workspace
- **Three AIs, one backend** — Claude for architecture, Lumo for unlimited fast work, CAIT for local learning
- **DC replacement path** — main.js already has 90% of the IPC handlers needed to serve as an MCP server. Building this eliminates the DC flakiness problem entirely
- **Phi-3.5 for local labeling** — base model does initial noun/action tagging on observer events. Bootstraps CAIT's own training data
- **Copilot Enterprise** — confirmed Office-only (no API). University "Vandalizer" — needs investigation for Azure OpenAI API access

### What Comes Next (Priority Order)
1. **Build MCP server into Lumo Electron** — expose main.js IPC handlers as MCP tools, configure Claude Desktop to connect to it instead of DC
2. **Observer service** — Node.js file watcher + window title logger in main.js, outputs to `C:\dev\cait\training_data\shadow_raw\`
3. **Install Phi-3.5 deps** — `pip install torch torchvision transformers accelerate pillow` on system Python
4. **Local API server in main.js** — Express on localhost for webview tabs to access filesystem context
5. **Wire labeling pipeline** — observer → Phi-3.5 inference → labeled JSON → CAIT training data
6. **Fix build scripts** — `.gitignore` for deploy/, installer/, node_modules/ to prevent recursive packaging
7. **Pending from buffer** — git PATH fix on Antiquarian, ocritd commit+push, send Rebecca the Excel workbook

### Learnings
- **L071** (tooling): DC MCP connection drops frequently under claude.ai web interface. Node.js-based alternatives (Electron app as MCP server) would be more stable since the process is already running and doesn't depend on a separate MCP transport layer
- **L072** (architecture): Electron webview tags are fully sandboxed — preload.js bridge doesn't cross into webview content. Local API (Express on localhost) or webview preload injection needed for AI tabs to access filesystem
- **L073** (deployment): Electron `electron-packager` will recursively include deploy/ and installer/ output if they exist in the source tree. Must exclude build output dirs or use .gitignore-aware packaging
- **L074** (settings): JSON.parse() fails on JS-style comments. Strip with regex before parsing to keep config files human-readable
- **L075** (infrastructure): Proton Lumo streams tokens very fast on low-traffic infrastructure. Good candidate for high-volume labeling work via paste-context when API unavailable

### Files Created/Modified
- `C:\dev\_DOCKSN\.objectives.json` — reviewed (created earlier same day)
- `C:\dev\lumo\main.js` — webviewTag: true, loadSettings() comment-strip patch
- `C:\dev\lumo\renderer\index.html` — 3 AI tabs (Claude, Lumo, CAIT) + CAIT control panel
- `C:\dev\rebuild_lumo_clean.ps1` — one-shot cleanup script
