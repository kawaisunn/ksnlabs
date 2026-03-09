# J:\ Mirror Push - Verified 2026-03-08
# Session: claude.ai web (Opus 4.6) on IGS-Antiquarian via RDP to BIGSPIDER

## Transfer Config
- PUSH: Antiquarian J:\(Rift share) -> BIGSPIDER J:\(32TB local) via RDP \\tsclient\J
- PULL: Reverse direction for processed output (BIGSPIDER J:\ -> Antiquarian J:\)
- Script: C:\dev\push_top40_to_bigspider.ps1 (robocopy /E /Z /XO /FFT, mirrors paths exactly)
- Paths are identical on both machines: J:\District#\...\<site>\

## Verification Results
- All 15 sites: robocopy /L shows 0 files needing copy, 0 FAILED
- MD5 spot-checks: D1 Br0002c OCR (2 files MATCH), D3 EL-47s (2 files MATCH)
- Total: ~994 files, ~2.7 GB

## 15 Selected Sites
| District | Sites |
|----------|-------|
| D1 (x5) | Br0002c, Br0145c, Bw0061c, Kt0012c, By0072s |
| D2 (x2) | Lt-172-c, Id-121-c |
| D3 (x2) | AD-62s Blacks Creek source, EL-47s (ITD Glenns Ferry) |
| D4 (x2) | Cs-185-s, Be-72-s |
| D5 (x2) | Bk-127-s, Bg-75-s |
| D6 (x2) | Bn-79-s Ririe Pit, Cu-74-s |

## Path Examples
- Source: J:\District1\District 1 Top 40 Sites\Br0002c\OCR\
- Dest:   J:\District1\District 1 Top 40 Sites\Br0002c\OCR\ (on BIGSPIDER)
- D3 is county-nested: J:\District3\District 3 Top 40 Sites\State Sources\<County>\<site>\
- D4 uses dated folder: J:\District4\2025.11.13.District4Top40Sites\<site>\

## Next Actions
- Run Doksn on BIGSPIDER against J:\ sample sites
- Pull processed output back to Antiquarian J:\ via reverse robocopy
- Expand site selection as needed (add more sites to push script)
