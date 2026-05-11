# Racer Package Size Phase 1 Baseline

Measured on 2026-05-11 from `main` after staging `mobile_detail_phase1` racer assets.

## Export Commands

- Web: `godot_console --headless --recovery-mode --path . --export-release Web build/web/index.html`
- Android: `godot_console --headless --recovery-mode --path . --export-debug Android build/android/racer-debug-phase1.apk`

The regular headless Web export writes the pack but exits nonzero because the `gamedev_ai` editor plugin calls `EditorSettings.save()` during headless startup. `--recovery-mode` disables editor plugins and produced a clean Web export.

The Android export wrote a readable APK but did not return before the 10-minute timeout. The generated archive was validated enough for package measurement, but the export command lifecycle still needs cleanup before this phase is considered fully automated.

## Size Checkpoints

| Checkpoint | Bytes | MiB |
| --- | ---: | ---: |
| Web `index.pck` | 297,940,796 | 284.1 |
| Web build total | 336,335,111 | 320.8 |
| Android latest APK | 728,602,023 | 694.8 |
| Source racer GLBs | 458,871,056 | 437.6 |
| Optimized racer GLBs | 218,483,632 | 208.4 |
| Optimized racer atlases | 34,647,771 | 33.0 |
| Optimized racer staged total | 253,131,403 | 241.4 |
| Racer GLB savings | 240,387,424 | 229.3 |

## Gate Notes

- Web export preset includes the eight `mobile_detail_phase1` racer GLBs and JPG atlases.
- Web export preset excludes `assets/source/meshy/2026-04-27-character-track-batch`.
- Android APK inspection found eight optimized racer GLBs and zero `assets/source/**` entries.
- `PackageSizeAudit` now records Android APK/AAB package files plus the latest Android package path and size.
