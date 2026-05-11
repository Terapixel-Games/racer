# Racer Package Size Phase 2 Texture Import Compression

Measured on 2026-05-11 after normalizing all staged racer atlases to VRAM texture compression.

## Change

- Updated Slammo, Tuggs, and Velva `mobile_detail_phase1` atlas imports from plain compressed texture output to the same S3TC/ETC2 VRAM import path already used by the other five racers.
- Kept all source atlas JPGs at their existing 2048 resolution.
- Did not change racer GLBs or texture source bytes.

## Size Delta

| Checkpoint | Phase 1 Bytes | Phase 2 Bytes | Delta |
| --- | ---: | ---: | ---: |
| Web `index.pck` | 297,940,796 | 282,199,880 | -15,740,916 |
| Web build total | 336,335,111 | 320,594,195 | -15,740,916 |
| Optimized racer staged source total | 253,131,403 | 253,131,403 | 0 |

## Gate Notes

- Fresh Web export completed with `--recovery-mode`.
- Export log packed all eight racer atlas textures through `.s3tc.ctex`.
- `PackageSizeAudit` shows the Web build reduction.
- `test_racer_roster` verifies all eight configured racer GLBs still resolve through the optimized profile.
- `TestLevelSelectFlow` verifies the level-select rotating racer preview still loads and updates selected racers.
