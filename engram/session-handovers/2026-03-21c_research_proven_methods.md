# SESSION HANDOFF: 2026-03-21c
## Machine: BIGSPIDER (Claude Desktop, Opus 4.6)
## Session ID: opus46-desktop-bigspider-session-20260321c

### What Was Accomplished

1. **Environment confirmed** — Claude Desktop on BIGSPIDER with Lumo MCP + DC operational. Full engram loaded (buffer v1.0.22, all handovers through 03-21b, all learnings).

2. **Two architecture revisions recorded:**
   - **Shell preference policy (L114):** pwsh.exe ALWAYS first, powershell.exe second, cmd.exe third.
   - **Ephemeral databases (L115):** Temporary SQLite (or similar) DBs may be created/destroyed per processing job. Working memory for cross-file queries during active processing. Per-file JSON remains the persistent store. Two-tier: ephemeral DB = working memory, JSON = long-term.

3. **Comprehensive research completed across all 5 DOCKSN areas:**
   Full report: `C:\dev\_DOCKSN\docs\RESEARCH_Proven_Methods_20260321.md` (382 lines)

   **Deduplication:** MinHash + LSH (Broder 1997) via `datasketch` library (MIT license). SimHash as complement. `text-dedup` library wraps everything with TOML config. Bloom filters for memory efficiency at scale.

   **Thesaurus/Keywords:** USGS Thesaurus (public domain, hierarchical, RDF download) as base layer. ITD-specific overlay from LU_ tables. TF-IDF contrast against general English corpus surfaces domain vocabulary automatically. String-matching against controlled vocabulary is the proven deterministic first pass — no ML needed.

   **Date Extraction:** `dateparser` (BSD, 200+ locales, 100M+ pages tested) for detection. `dateutil.parser` with fuzzy mode for embedded dates. Datectx's unique value is contextual classification (test date vs permit date vs document date), not parsing.

   **Fragment Reassembly:** Graph-based community detection via `networkx` (BSD). Documents as vertices, similarity measures (MinHash + keywords + temporal overlap + entity co-occurrence) as edge weights. Louvain algorithm for clustering. Ephemeral SQLite is the natural workspace for this cross-file analysis.

   **Pipeline Architecture:** Adapter → Processor → Sink DAG pattern validated across IBM CCS, HealthEdge, Apache Tika, DCGP. Matches the pedalboard concept exactly. File watchers triggering processing is standard. Classify-first-then-dispatch is universal.

4. **Licensing verified — ALL CLEAR:**
   Every recommended library is MIT, BSD, Apache 2.0, or public domain. USGS Thesaurus and NGMDB vocabularies are federal work products (public domain by law). No GPL, no copyleft, no cloud restrictions. State agency can use, modify, bundle, distribute without restriction. Full table in the research doc.

5. **Deployment scenario confirmed — $0, zero infrastructure:**
   `pip install datasketch dateparser scikit-learn networkx` on BIGSPIDER. SQLite ships with Python. USGS Thesaurus is a free download. J:\ has the documents. First pipeline run on 15 ITD site folders is achievable with existing hardware. No cloud, no GPU (that's CAIT training later), no IT involvement.

### What to Build vs What to Use

**Use (don't reinvent):**
- datasketch → MinHash LSH dedup (MIT)
- dateparser → date extraction (BSD)
- scikit-learn → TF-IDF keyword extraction (BSD)
- networkx → graph-based fragment reassembly (BSD)
- SQLite → ephemeral per-job processing DB (public domain)
- USGS Thesaurus → base geoscience vocabulary (public domain)

**Build (DOCKSN's unique value):**
- Processor chain orchestrator (the pedalboard)
- Per-file JSON contract (schema processors read/write)
- ITD domain vocabulary overlay (aggregates, AASHTO, PLSS)
- CAIT training pipeline (shadow → labeled data → fine-tuned model)
- Prefill logic (extracted metadata → AggDB records with confidence)
- ktreesn index (GIS-aware filesystem catalog with processing state)

### Files Created This Session
- `C:\dev\_DOCKSN\docs\RESEARCH_Proven_Methods_20260321.md` (382 lines — full research report)
- `C:\dev\ksnlabs\engram\session-handovers\2026-03-21c_research_proven_methods.md` (this file)
- Buffer updated to v1.0.23

### What Comes Next (Implementation Priority)
1. `pip install datasketch dateparser scikit-learn networkx` on BIGSPIDER
2. Download USGS Thesaurus RDF → load into keywrds as base vocabulary
3. Wire keywrds to use TF-IDF + thesaurus string-matching on body text
4. Stand up datectx using dateparser.search.search_dates()
5. Replace MD5-only dedup with MinHash LSH via datasketch
6. Build reconstruct processor using networkx community detection
7. Build prefill processor mapping to AggDB schema
8. First pipeline run on 15 real ITD site folders from J:\
9. Review output, iterate, expand

### Buffer State
v1.0.23 — updated with shell preference, ephemeral DB revision, research complete status.

### Git State
ksnlabs: DIRTY — buffer + this handoff + research doc uncommitted.
