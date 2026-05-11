# Racer Package Size Phase 6 CI / Build Gate

Phase 6 adds a shared local and CI build gate for racer package regressions.

## Gate Command

```powershell
scripts\run-build-gate.ps1 -GodotBin godot
```

The gate runs:

- `scripts/run-tests.ps1 -Suite all`
- a fresh Web release export to `build/web/index.html`
- `tools/package_size_audit.gd`
- racer visual-regression manifest capture when racer assets or visual-capture code changed

## Failure Conditions

- Web export no longer uses the explicit resource allowlist.
- Web export allowlists `assets/source/meshy/2026-04-27-character-track-batch`.
- Android export stops excluding `assets/source/**`.
- LOD1/LOD2 atlas source JPGs return to the export allowlist.
- Web `index.pck` exceeds `500,000,000` bytes. The current fresh-export baseline is `489,701,320` bytes, leaving about 10 MB of regression headroom.
- Package audit cannot find optimized LOD0 racer GLBs or staged LOD GLBs.
- Package audit reports duplicate LOD atlas source bytes.

## Visual Regression Scope

CI uses `--manifest_only=true` for the visual-regression capture because headless Linux runners do not provide the same render-backed viewport used for full PNG/crop comparisons. This still validates the selected racer profile, capture targets, crop metadata, and asset paths when racer assets change. Full image and detail-crop comparison remains the render-capable local gate from Phase 5.
