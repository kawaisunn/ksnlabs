# MSIX Packaging Guide for Doksn

**Date**: 2026-03-07
**Status**: Prep - MSI is current production format; MSIX is the target.

## Why MSIX?

MSI works today. MSIX adds clean install/uninstall, auto-update, container isolation, and Intune/SCCM-friendly deployment for UofI IT.

## Two Paths

### Path A: MSIX Packaging Tool (GUI)
Microsoft Store app. Point at MSI, walk through wizard. Easy but manual.

### Path B: makeappx.exe (CLI, scriptable)
From Windows SDK. `convert_msi_to_msix.ps1` implements this path.

## Requirements

- **Code signing cert**: Self-signed (dev), UofI cert (internal), or CA cert (public)
- **Windows SDK**: For makeappx.exe and signtool.exe
- **AppxManifest.xml**: Identity, capabilities (runFullTrust), logo assets

## Known Gotchas

1. MSIX filesystem virtualization vs Doksn output paths
2. External tool paths (Tesseract, Ghostscript) need PATH or config
3. Python subprocess calls from .NET launcher need runFullTrust
4. Placeholder logo assets need replacing before distribution

## Timeline

| Phase | What | When |
|-------|------|------|
| Now | MSI is production | Current |
| Next | Self-signed MSIX for dev | When Windows SDK installed |
| Later | UofI-signed for internal | Coordinate with IT |
| Future | Store-signed for public | If needed |

See `convert_msi_to_msix.ps1` and full build kit zip for implementation details.
