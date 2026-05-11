# Racer Package Size Phase 4 Runtime LOD Selection

Measured on 2026-05-11 after staging `lod1` and `lod2` racer GLBs for the eight-racer roster.

## Change

- Staged LOD1 and LOD2 GLBs under `assets/optimized/racers/<slug>/`.
- Added roster helpers for LOD0, LOD1, and LOD2 racer model paths.
- Added race-only runtime LOD switching in `CarController` and `RaceController`.
- Level select still uses the configured LOD0 racer model path.

## Staged LOD Cost

| Checkpoint | Bytes | MiB |
| --- | ---: | ---: |
| Web `index.pck` after LOD staging | 565,878,328 | 539.7 |
| Total Web build after LOD staging | 604,272,643 | 576.3 |
| LOD0 racer GLBs | 218,483,632 | 208.4 |
| LOD1 racer GLBs | 199,629,260 | 190.4 |
| LOD2 racer GLBs | 147,144,116 | 140.3 |
| LOD GLB total | 346,773,376 | 330.7 |
| Runtime racer GLB total | 565,257,008 | 539.1 |
| LOD atlas source copies | 69,295,542 | 66.1 |
| Total staged LOD cost | 416,068,918 | 396.8 |

## Gate Notes

- LOD0 remains the default roster profile and level-select path.
- Race camera distance switches car visuals to LOD1 at 28 units and LOD2 at 52 units.
- Close camera views switch back to LOD0.
- The staged LOD outputs duplicate atlas images today; a later texture-reference dedupe pass should reduce that cost.
- Web `index.pck` increased by 283,678,448 bytes versus the Phase 2 checkpoint because LOD1/LOD2 are now shipped in addition to LOD0.
