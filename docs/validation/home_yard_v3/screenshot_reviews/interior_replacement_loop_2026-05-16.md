# Home Yard V3 Interior Replacement Loop Screenshot Review

Camera set: StageVisualDiffCapture interior public-course views
Areas: attic, bedroom, glam_closet, kitchen, playroom
Screenshot manifest: `C:/code/TeraPixel/games/racer/reports/home_yard_v3_interior_loop_final/interior_loop_final_manifest.json`
Contact sheets:
- `C:/code/TeraPixel/games/racer/reports/home_yard_v3_interior_loop_final/interior_loop_final_attic_contact_sheet.png`
- `C:/code/TeraPixel/games/racer/reports/home_yard_v3_interior_loop_final/interior_loop_final_bedroom_contact_sheet.png`
- `C:/code/TeraPixel/games/racer/reports/home_yard_v3_interior_loop_final/interior_loop_final_glam_closet_contact_sheet.png`
- `C:/code/TeraPixel/games/racer/reports/home_yard_v3_interior_loop_final/interior_loop_final_kitchen_contact_sheet.png`
- `C:/code/TeraPixel/games/racer/reports/home_yard_v3_interior_loop_final/interior_loop_final_playroom_contact_sheet.png`
Date: 2026-05-16
Reviewer: Codex critical game designer

## Scores

| Area | Layout clarity | Route readability | Third-person clearance | Central occlusion | Road visibility | Next turn readability | Material quality | Scale consistency | Room identity | Shell closure | Furnishing quality | Collision risk | Placeholder leak check | Performance health | Status |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| attic | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |
| bedroom | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |
| glam_closet | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |
| kitchen | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |
| playroom | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |

## Pass/Fail

Minimum required score per category: 4.
Central route/camera occlusion above 35% blocks production.
A view that makes the third-person racer camera read like a blocked first-person wall view blocks production.

Status: PASS for this implementation loop.

## Findings

- The render-capable capture wrote 88 interior views with no failed attempts.
- Visible room identity is now carried by sourced Meshy or Kenney GLB assets instead of the removed primitive furnishing boxes.
- The temporary measured stair and ladder continuity meshes are hidden and metadata-tagged as validation-only, while the visible connector language comes from sourced Kenney stair geometry.
- The attic chase-camera views initially failed review because the launch deck and guard wall sat too close to the start corridor. The final generator pass insets and lowers that route infrastructure; final attic route samples and launch views keep the road centerline readable.
- Shell/roof context remains visible in high and envelope views by design. Manual screenshot review found no central chase-camera or route sample occlusion above the 35% blocker threshold. This was a visual estimate from the final PNGs, not an automated pixel classifier.

## Required Fixes

None for this loop.

## Evidence

- Final capture command:
  `C:/code/bin/godot_console.exe --path C:/code/TeraPixel/games/racer --script res://tools/capture/StageVisualDiffCapture.gd -- --phase=interior_loop_final --track_id=attic,bedroom,glam_closet,kitchen,playroom --output_dir=C:/code/TeraPixel/games/racer/reports/home_yard_v3_interior_loop_final`
- The final visual manifest reports five interior tracks, 88 views, and an empty `failed_attempts` array.
- Generator source of truth: `res://scripts/tools/GenerateHomeYardV3Map.gd`
- Replacement provenance: `res://assets/source/meshy/home_yard_v3/replacement_provenance.json`

## Interior Shell Fix Pass

Date: 2026-05-16
Capture: `C:/code/TeraPixel/games/racer/reports/home_yard_v3_interior_shell_fix/interior_shell_fix_manifest.json`
Views: 88
Failed attempts: 0

| Area | Layout clarity | Route readability | Third-person clearance | Central occlusion | Road visibility | Next turn readability | Material quality | Scale consistency | Room identity | Shell closure | Furnishing quality | Collision risk | Placeholder leak check | Performance health | Status |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| attic | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |
| bedroom | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |
| glam_closet | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |
| kitchen | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |
| playroom | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | PASS |

### Critique List And Fixes

| Critique | Generated node path | Source location | Why it existed | Fix |
|---|---|---|---|---|
| Exterior planting was visible inside living/dining/front hall views. | `Site/FrontFoundationPlantingLeft`, `Site/FrontFoundationPlantingRight` | `res://scripts/tools/GenerateHomeYardV3Map.gd:441` | The exterior planting beds were authored at `z=135`, behind the front wall face at `z=145`, so they intersected the interior floor volumes. | Moved both beds forward to `z=190`; added `_assert_home_yard_site_props_stay_outside_interior` in `res://tests/unit/test_track_catalog_listing.gd:1284`. |
| Exterior shrub masses leaked into living/dining/front hall volumes. | `Site/FrontShrubMass01` through `Site/FrontShrubMass06` | `res://scripts/tools/GenerateHomeYardV3Map.gd:462` | The front shrub loop used `z=130/135`, which placed visible site props behind the front wall. | Moved the shrub loop to `z=188/193`, outside the interior shell and front wall volume. |
| Upper hallway ceiling did not prove continuous coverage to the exterior shell. | `UpperFloor/RoomFinishes/UpperFloorTenFootCeilingPlane` | `res://scripts/tools/GenerateHomeYardV3Map.gd:556` | A single broad ceiling plane stopped short of the front hall coverage samples and did not document the attic hatch void. | Replaced it with a split ceiling holder and four measured ceiling pieces around the attic hatch; added sample coverage and hatch-void tests in `res://tests/unit/test_track_catalog_listing.gd:1316`. |
| Upstairs stair/hall edge read incomplete at the east side of the stair opening. | `UpperFloor/RoomFinishes/MainStairOpeningRailEast` | `res://scripts/tools/GenerateHomeYardV3Map.gd:570` | The upper stairwell guardrail had north, south, and west rails but no east rail tying the opening edge together. | Added `MainStairOpeningRailEast` and a test requiring it for hallway continuity. |
| Front entry frame lacked a base member in the audited assembly, making the door/glass fit harder to prove. | `ExteriorShell/FrontDoorFrameSill` | `res://scripts/tools/GenerateHomeYardV3Map.gd:691` | The front jambs, mullions, and header existed, but the frame gate had no explicit sill/base member. | Added `FrontDoorFrameSill` and expanded the front-entry fit test to check door panel, sidelights, header, sill, and door glass bounds. |

### Auditor Result

The generated-scene provenance loop has no remaining actionable interior critiques for this pass. The remaining visible generated nodes are either sourced replacement assets, authored architectural shell/opening pieces with provenance metadata, or hidden validation helpers. No central route/camera occlusion was found above the 35% threshold in the interior capture review.

Verification:

- `C:/code/bin/godot_console.exe --headless --path C:/code/TeraPixel/games/racer --script res://scripts/tools/GenerateHomeYardV3Map.gd`
- `powershell.exe -ExecutionPolicy Bypass -File scripts/run-tests.ps1 -Suite unit`
- `powershell.exe -ExecutionPolicy Bypass -File scripts/run-tests.ps1 -Suite unit -Filter test_track_catalog_listing`
- `powershell.exe -ExecutionPolicy Bypass -File scripts/run-tests.ps1 -Suite uat -Filter TestKitchenTrackLoads`
- `C:/code/bin/godot_console.exe --path C:/code/TeraPixel/games/racer --script res://tools/capture/StageVisualDiffCapture.gd -- --phase=interior_shell_fix --track_id=attic,bedroom,glam_closet,kitchen,playroom --output_dir=C:/code/TeraPixel/games/racer/reports/home_yard_v3_interior_shell_fix`
