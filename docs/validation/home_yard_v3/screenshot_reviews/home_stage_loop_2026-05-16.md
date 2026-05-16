# Home Yard V3 Home Stage Loop Screenshot Review

Date: 2026-05-16
Reviewer: Codex generated-scene provenance auditor

## Scope

Tracks: `outdoor_playground`, `garden`, `sandbox`

Initial capture: `C:/code/TeraPixel/games/racer/reports/home_yard_v3_home_stage_loop/home_stage_loop_manifest.json`

Post-fix capture: `C:/code/TeraPixel/games/racer/reports/home_yard_v3_home_stage_loop_after_preview/home_stage_loop_after_preview_manifest.json`

## Scores

| Area | Preview composition | Route readability | Third-person clearance | Central occlusion | Road visibility | Next turn readability | Landmark readability | Shell context | Visual confusion | Status |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| outdoor_playground | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |
| garden | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |
| sandbox | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |

## Critique List And Fixes

| Critique | View / node path | Source location | Why it existed | Fix |
|---|---|---|---|---|
| Garden level-select screenshot was completely filled by the house wall, so the validation camera did not prove route, yard identity, or landmark readability. | `home_stage_loop_garden_level_select_angle.png` | `res://tools/capture/StageVisualDiffCapture.gd:_level_select_camera_position` | The generic outdoor preview formula placed the camera between the house rear wall and the garden route target. The look ray crossed the house shell before it reached the route. | Moved outdoor level-select camera placement into `res://scripts/logic/HomeYardVisualGateContract.gd` and positioned outdoor previews behind the backyard route. |
| Outdoor playground level-select screenshot improved after the first camera move but the tire-swing tree filled the foreground and hid too much of the route. | `home_stage_loop_after_camera_outdoor_playground_level_select_angle.png` | `res://scripts/logic/HomeYardVisualGateContract.gd:level_select_camera_position` | The tree is a valid landmark, but the shared back-right angle put its canopy between the camera and route center. | Added an `outdoor_playground` back-left elevated preview angle so the tree reads as a side landmark instead of central occlusion. |

## Gates

- Added `HomeYardVisualGateContract.level_select_camera_position()` as the source of truth for level-select validation-camera placement.
- Updated `StageVisualDiffCapture.gd` to use that shared contract.
- Added `test_outdoor_level_select_cameras_stay_behind_backyard_routes()` so outdoor preview cameras cannot regress into the house shell and the playground preview uses the back-left angle.

## Auditor Result

No remaining actionable critiques for this pass. The post-fix level-select views show the outdoor route, yard zone, landmark, and house context without wall-filled frames or central foreground occlusion above the 35% threshold.

## Verification

- `powershell.exe -ExecutionPolicy Bypass -File scripts/run-tests.ps1 -Suite unit -Filter test_home_yard_visual_gate_contract`
- `C:/code/bin/godot_console.exe --path C:/code/TeraPixel/games/racer --script res://tools/capture/StageVisualDiffCapture.gd -- --phase=home_stage_loop_after_preview --track_id=outdoor_playground,garden,sandbox --output_dir=C:/code/TeraPixel/games/racer/reports/home_yard_v3_home_stage_loop_after_preview`
