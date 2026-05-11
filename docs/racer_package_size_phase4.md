# Racer Package Size Phase 4 Runtime LOD Selection

Measured on 2026-05-11 after staging `lod1` and `lod2` racer GLBs for the eight-racer roster, then deduplicating LOD texture payloads back to the LOD0 atlas.

## Change

- Staged LOD1 and LOD2 GLBs under `assets/optimized/racers/<slug>/`.
- Rewrote LOD1 and LOD2 GLBs to reference the existing LOD0 atlas image instead of embedding duplicate JPEG payloads.
- Removed duplicate LOD atlas source JPGs and imports from `assets/optimized/racers/<slug>/`.
- Added roster helpers for LOD0, LOD1, and LOD2 racer model paths.
- Added race-only runtime LOD switching in `CarController` and `RaceController`.
- Level select still uses the configured LOD0 racer model path.

## Staged LOD Cost

| Checkpoint | Bytes | MiB |
| --- | ---: | ---: |
| Web `index.pck` after LOD dedupe | 450,494,676 | 429.6 |
| Total Web build after LOD dedupe | 488,888,991 | 466.2 |
| LOD0 racer GLBs | 218,483,632 | 208.4 |
| LOD GLB total after embedded texture removal | 277,477,336 | 264.6 |
| Runtime racer GLB total | 495,960,968 | 473.0 |
| LOD atlas source copies | 0 | 0.0 |
| Total staged LOD cost | 277,477,336 | 264.6 |
| Total staged racer runtime assets | 530,608,739 | 506.0 |

## Gate Notes

- LOD0 remains the default roster profile and level-select path.
- Race camera distance switches car visuals to LOD1 at 28 units and LOD2 at 52 units.
- Close camera views switch back to LOD0.
- LOD1 and LOD2 now reuse each racer's LOD0 atlas source image.
- Web `index.pck` is 115,383,652 bytes smaller than the initial Phase 4 LOD-staging export.
- Web `index.pck` remains 168,294,796 bytes larger than the Phase 2 checkpoint because LOD1/LOD2 meshes are still shipped in addition to LOD0.
