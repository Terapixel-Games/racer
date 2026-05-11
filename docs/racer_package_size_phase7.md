# Racer Package Size Phase 7 Shared Atlas Research

Phase 7 evaluates a game-wide shared racer atlas without changing production assets.

## Gate Command

```powershell
godot --headless --path . --script tools\shared_racer_atlas_research.gd
```

## Current Baseline

- Profile: `mobile_detail_phase1`
- Racer atlas count: 8
- Per-racer atlas resolution: 2048 x 2048
- Current staged atlas source bytes: `34,647,771`
- Current runtime model layout: one LOD0 atlas per racer, with LOD1/LOD2 reusing that racer's LOD0 atlas

## Candidates

| Candidate | Layout | Per-racer detail | Mobile 4096 edge gate | Detail gate | Result |
| --- | ---: | ---: | --- | --- | --- |
| Current per-racer atlases | 8 x 2048 | 1.0x | Pass | Pass | Keep |
| Shared preserve-detail atlas | 8192 x 4096 | 1.0x | Fail | Pass | Reject |
| Shared mobile-safe atlas | 4096 x 2048 | 0.5x | Pass | Fail | Defer |

The preserve-detail shared atlas has the same texture pixel count as the current eight-atlas baseline, so it is not a meaningful package-size win unless cross-image JPG compression beats the current per-racer JPGs. The mobile-safe 4096 candidate estimates `8,661,943` source texture bytes, or `25,985,828` bytes saved, but that saving comes from reducing each racer's atlas cell from 2048 to 1024.

## Decision

Do not switch production racers to a shared atlas in this round.

The only shared atlas that preserves the 2048 eye, tire, teeth, and decal detail needs an 8192-wide texture. That violates the current mobile texture-edge gate. A mobile-safe 4096 shared atlas cuts each racer's atlas cell to 1024, which is exactly the type of detail loss this optimization pass was designed to prevent.

## Follow-Up Criteria

Reopen shared atlases only if one of these becomes true:

- render-backed crop comparisons prove a lower per-racer cell size still passes the LOD0 detail threshold,
- the game introduces racer groupings where a 2048 shared atlas is useful for only two to four racers at a time,
- target devices and Godot import settings explicitly support an 8192 edge without memory or compatibility risk.
