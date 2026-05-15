# Playroom Meshy Batch Screenshot Review - 2026-05-13

## Scope
- Course: `playroom`
- Assets: `low_poly_playroom_plush_landmark`, `low_poly_playroom_toy_block_tower`, `low_poly_playroom_ramp_side_toy_bins`
- Scene: `res://assets/gameplay/tracks/home_yard_v3/home_yard_v3_map.tscn`

## Live Editor Capture Result
- MCP session: `Racer`
- `editor_state.project_name`: `Racer`
- Initial readiness reached `ready`.
- Viewport capture against `MainFloor/PlayroomPlushLandmark`, `MainFloor/PlayroomBlockTower`, and `MainFloor/PlayroomToyBins` failed because the live editor hierarchy did not contain those regenerated disk nodes.
- Safe reload attempt switched the editor back to `readiness=importing`.
- Safe dialog helper result: no safe `Reload from disk` or `OK` dialog was available.

## Critical Designer Read
- Production readiness: fail for live visual proof.
- The playroom asset batch cannot yet be accepted visually because the live editor scene is stale.
- No final judgment should be made about layout clarity, scale, material quality, route readability, or visual confusion from this live editor state.

## Deterministic Headless Validation
- Passed: the regenerated scene loads the three Meshy playroom asset instances from disk.
- Passed: playroom metadata exports the three Meshy asset paths.
- Passed: route-clearance metadata for playroom stage props remains `outside_route_corridor`.
- Passed: required playroom validation cameras exist: `PlayroomStartPlayerCamera`, `PlayroomRouteCamera`, and `PlayroomAssetCloseupCamera`.

## Follow-Up Gate
- Recover or restart the live editor session so it reloads `home_yard_v3_map.tscn` from disk.
- Re-capture `PlayroomStartPlayerCamera`, `PlayroomRouteCamera`, and `PlayroomAssetCloseupCamera`.
- Score the Meshy previews for arena identity, silhouette, scale, material quality, route readability, collision risk, and placeholder leaks before production acceptance.
