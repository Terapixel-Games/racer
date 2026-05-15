# Home Yard V3 Beta Gate Existing Test Inventory

This inventory maps existing repo tests that can already serve as beta gates for `home_yard_v3`, and names the missing validators that still need implementation.

## Existing Usable Gates

| Gate | Existing coverage | Notes |
|---|---|---|
| Public course catalog | `tests/unit/test_track_catalog_listing.gd`, `tests/unit/test_track_map_definition.gd` | Verifies the eight public courses resolve through `home_yard_v3`, old `home_yard` and `home_yard_v2` are hidden from normal catalog resolution, and each mode uses RoadGridMap metadata. |
| Track definition validity | `tests/unit/test_track_definition.gd` | Verifies route, lap gate, spawn count, checkpoint order, stage interactions, route bounds, and metadata validation behavior. |
| Metadata export | `tests/unit/test_track_metadata_export.gd` | Verifies server/client metadata shape, stage props, interactions, audio zones, package metadata, and shared-map paths. |
| Shared map scene and cameras | `tests/unit/test_track_catalog_listing.gd` | Verifies `home_yard_v3_map.tscn` instantiates and key start, shell, route, roof, and yard validation cameras can become current in a headless scene. |
| Runtime scene smoke | `tests/uat/TestKitchenTrackLoads.gd` | Verifies runtime builder output, GridMap route visuals, invisible boundaries, shared dressing holders, stage props, several start-corridor checks, outdoor shared shell use, and kitchen polish details. |
| Kitchen shell/material polish | `tests/uat/TestKitchenTrackLoads.gd` | Includes window glass alpha, wall/window infill, door header depth, visible support placement, visual-only decor, and route clearance for named kitchen props. |
| Route and GridMap rendering | `tests/unit/test_track_grid_road_builder.gd`, `tests/unit/test_track_ribbon_mesh.gd`, `tests/unit/test_track_catalog_listing.gd` | Verifies route-cell contracts, generated road continuity, ramp/vertical contracts, and RoadGridMap source. |
| Camera behavior | `tests/unit/test_camera_occlusion.gd`, `tests/unit/test_racer_visual_regression.gd` | Verifies runtime camera occlusion math and visual regression target presence. |
| Package/export/performance outer gate | `tests/unit/test_package_size_audit.gd`, `tests/unit/test_package_size_audit_sprite_lod.gd`, `tests/unit/test_build_gate_contract.gd`, `tests/unit/test_export_presets.gd` | Useful for beta packaging and size guardrails, but not yet area-specific to `home_yard_v3`. |
| Wall collision baseline | `tests/unit/test_track_walls.gd` | Covers visible mesh wall collision for legacy wall systems; can inform shell collision validators. |
| Meshy-first loop contract | `tests/unit/test_home_yard_meshy_first_asset_manifest.gd` | Verifies the loop contract, asset source policy, concept/provenance/gate specs, and production-domain requirements. |

## Missing Executable Specs

| Missing validator | Spec target | Required behavior |
|---|---|---|
| `test_home_yard_v3_concept_artifacts.gd` | Concept references | Fail if any required concept artifact is missing or lacks intent, references, shape language, material palette, gameplay readability notes, and prompt notes. |
| `test_home_yard_v3_area_manifests.gd` | Area manifests | Fail if any area manifest is missing required lifecycle, source, route-clearance, collision, validation camera, screenshot score, or blocked-item fields. |
| `test_home_yard_v3_replacement_provenance.gd` | Asset replacement provenance | Fail if every old non-Kenney visible asset lacks a keep/reject/replacement mapping and validation result. |
| `test_home_yard_v3_no_visible_placeholders.gd` | Placeholder leakage | Fail if visible stage props or final scene nodes are Godot primitives without generator metadata, manifest coverage, or invisible infrastructure classification. |
| `test_home_yard_v3_route_collision_clearance.gd` | Route corridor clearance | Compute route corridor against prop/furniture/landscape AABBs and fail unplanned lateral or vertical clearance violations. |
| `test_home_yard_v3_runtime_route_aabb_swept_clearance.gd` | Runtime obstruction clearance | Instantiate every public course and fail if wall, shell, furniture, prop, imported asset, or collision AABBs intersect the route corridor, spawn grid, drift margin, or third-person chase-camera swept volume unless declared as intentional named hazards. |
| `test_home_yard_v3_third_person_route_obstruction_screenshots.gd` | Third-person visual obstruction | Require start-grid, launch chase, first-turn chase, camera-clearance, overhead, and route-sample screenshots for every public course, with scores proving the road/next turn remain visible and the camera does not read as blocked or first-person. |
| `test_home_yard_v3_transparent_windows.gd` | Window material gate | Fail opaque exterior window panes, missing close-up cameras, and void/sky leaks behind decorative openings. |
| `test_home_yard_v3_scene_drift.gd` | Generator-driven scene drift | Fail final visible scene nodes not represented by generator metadata, mode metadata, area manifests, or provenance records. |
| `test_home_yard_v3_performance_budget.gd` | Mobile budget | Fail if total/area triangles, material count, texture sizes, or import compression settings exceed the manifest budget. |
| `test_home_yard_v3_camera_screenshot_scores.gd` | Visual review records | Fail if required camera captures are missing critical designer scores or if any score is below the gate threshold. |
| `test_home_yard_v3_import_recovery.gd` | Editor import stability | Dry-run or smoke-test the safe dialog helper contract and verify post-recovery readiness/camera checks are recorded. |

## Beta Run Sequence

1. Confirm concept artifacts and area manifests.
2. Run headless import.
3. Run focused home-yard unit gates.
4. Run full unit suite.
5. Run full UAT suite.
6. Capture required cameras through live Godot MCP or deterministic headless camera validation, including third-person launch and first-turn chase views.
7. Record screenshot scores, rejecting any view where central route/camera occlusion makes the kart read as blocked.
8. Check provenance and performance budgets.
9. Commit only clean scoped verified work.
