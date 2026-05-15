# Home Yard V3 Route Obstruction Screenshot Gate

## Failure Class

The blocked-racer screenshots are third-person chase-camera obstruction failures. They can happen even when the route cells are valid and even when a visible object has collision disabled. The production problem is that wall, shell, furniture, prop, or imported asset geometry can occupy the kart route, spawn envelope, drift margin, or chase-camera frustum after runtime scaling/import.

Metadata such as `route_clearance = outside_route_corridor` is not sufficient. The gate must measure instantiated runtime bounds and inspect screenshots from the camera the player actually uses.

## Hard Rules

- No unplanned wall, furniture, prop, shell, imported asset, or collision AABB may intersect the route corridor, start grid, first-turn corridor, AI/drift margin, checkpoint envelope, or third-person chase-camera swept volume.
- Visual-only assets may still fail if they hide the road, next turn, exit lane, route edge treatment, or kart from the third-person camera.
- Any view that reads like a first-person wall/floor view because the chase camera is inside or behind geometry blocks production.
- Static collision inside the route corridor is allowed only for intentional named hazards or boundaries with explicit gameplay tags, validation cameras, and UAT coverage.

## Required Screenshot Views

Every public `home_yard_v3` course must capture and review:

- `start_grid`
- `third_person_launch`
- `first_turn_chase`
- `camera_clearance`
- `overhead_route`
- `route_sample_25`
- `route_sample_50`
- `route_sample_75`

Each review must score third-person camera clearance, central view occlusion, road visibility, next-turn readability, route corridor clearance, collision risk, and visual confusion. Minimum score is 4/5 per category. Any zero or central camera/route occlusion above 35% blocks the gate.

## Test Implementation Specs

`test_home_yard_v3_runtime_route_aabb_swept_clearance.gd`

- Load each public course through `TrackCatalog` and `TrackRuntimeBuilder`.
- Compute route sample capsules or expanded AABBs using route corridor width, kart width, AI/drift margin, and vertical clearance.
- Compute a chase-camera swept volume for launch, first turn, and representative samples.
- Walk all instantiated `MeshInstance3D`, `StaticBody3D`, `CollisionObject3D`, and generated shell/prop holders.
- Fail overlaps unless the node is invisible infrastructure or an intentional named hazard/boundary with manifest coverage.

`test_home_yard_v3_third_person_route_obstruction_screenshots.gd`

- Verify `StageVisualDiffCapture.gd` emits the required third-person views from `HomeYardVisualGateContract.gd`.
- Verify screenshot review records exist for each course and required view.
- Fail if any required category is missing, scored below 4, or marked blocked.

## Local Capture Command

```powershell
C:\code\bin\godot_console.exe --headless --path C:\code\TeraPixel\games\racer --script res://tools/capture/StageVisualDiffCapture.gd -- --phase=route_obstruction --track_id=all --output_dir=C:\code\TeraPixel\games\racer\reports\home_yard_v3_route_obstruction
```

Use `--manifest_only=true` only as a smoke check. Production review requires real PNG captures from a render-capable run or live Godot MCP camera validation.
