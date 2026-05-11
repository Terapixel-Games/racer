# Racer Visual Regression Phase 5

Phase 5 adds a local visual regression loop for racer package optimization. It captures deterministic racer screenshots, records detail crop metadata, and compares candidates against a baseline with explicit failure reports.

## Capture

Capture Rexx and Moko at the default 1280x720 gate:

```powershell
godot --path . --script tools\capture\RacerVisualRegressionCapture.gd -- --phase=baseline --output_dir=reports\racer_visual_regression\baseline --racers=Rexx,Moko
godot --path . --script tools\capture\RacerVisualRegressionCapture.gd -- --phase=candidate --output_dir=reports\racer_visual_regression\candidate --racers=Rexx,Moko
```

Use `--manifest_only=true` for headless smoke checks. PNG capture requires a render-capable Godot run; the headless dummy renderer cannot read back viewport pixels.

The capture manifest stores:

- selected racer asset profile,
- source model path and byte size,
- full screenshot path,
- crop paths and pixel rectangles for eyes, face/teeth, decals, and tire treads,
- threshold metadata and failed capture attempts.

## Compare

Compare candidate to baseline:

```powershell
python tools\compare_racer_visual_regression.py --baseline reports\racer_visual_regression\baseline\baseline_manifest.json --candidate reports\racer_visual_regression\candidate\candidate_manifest.json --report reports\racer_visual_regression\candidate_report.json
```

The report records full-frame score, per-crop detail scores, selected profile, model size, and failed attempts. The gate fails if full render or any detail crop falls below `0.99`.

Use review-only quality tiers when evaluating size/quality tradeoffs for humans:

```powershell
python tools\compare_racer_visual_regression.py --baseline reports\racer_visual_regression\baseline\baseline_manifest.json --candidate reports\racer_visual_regression\candidate\candidate_manifest.json --report reports\racer_visual_regression\candidate_strict_report.json --quality-tier strict
python tools\compare_racer_visual_regression.py --baseline reports\racer_visual_regression\baseline\baseline_manifest.json --candidate reports\racer_visual_regression\candidate\candidate_manifest.json --report reports\racer_visual_regression\candidate_human_90_report.json --quality-tier human_90
python tools\compare_racer_visual_regression.py --baseline reports\racer_visual_regression\baseline\baseline_manifest.json --candidate reports\racer_visual_regression\candidate\candidate_manifest.json --report reports\racer_visual_regression\candidate_human_70_report.json --quality-tier human_70
```

Only `strict` is production-eligible. `human_90` and `human_70` are comparison
tiers for reviewer studies and include model, texture, and total staged byte
metadata from the capture manifest.

## Scope

Targets currently covered:

- `level_select_preview`
- `driving_camera`

Detail crops currently covered:

- `eyes`
- `face_teeth`
- `decals`
- `tire_treads`

This pass formalizes the local regression harness. Future CI wiring should call the same capture and compare tools when racer assets change.
