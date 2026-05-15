# Attic Meshy Batch Screenshot Review - 2026-05-13

## Scope
- Course: `attic`
- Assets: `low_poly_dusty_attic_trunk`, `low_poly_attic_jack_in_the_box_setpiece`, `low_poly_attic_sheet_tunnel`
- Scene: `res://assets/gameplay/tracks/home_yard_v3/home_yard_v3_map.tscn`

## Live Editor Capture Result
- MCP session: `Racer`
- `editor_state.project_name`: `Racer`
- Initial readiness reached `ready`, then returned to persistent `importing`.
- Safe dialog helper result: no safe `Reload from disk` or `OK` dialog was available.
- Viewport target capture was attempted for `Attic/AtticChest`, `Attic/AtticJackSetpiece`, and `Attic/AtticSheetTunnelSetpiece`.
- MCP reported `Attic/AtticSheetTunnelSetpiece` as not found in the live editor scene even though the regenerated disk scene contains it.

## Critical Designer Read
- Production readiness: fail for live visual proof.
- The capture was stale and not valid for asset acceptance.
- Framing showed mostly attic floor with only partial asset silhouettes at the top edge.
- The sheet tunnel could not be reviewed because the open editor scene had not reloaded the regenerated disk scene.
- No claim should be made about final visual clarity, scale, material quality, or player-height readability from this capture.

## Deterministic Headless Validation
- Passed: the regenerated scene loads the three Meshy attic asset instances from disk.
- Passed: attic metadata exports the three Meshy asset paths.
- Passed: route-clearance metadata for the three attic stage props remains `outside_route_corridor`.
- Passed: required validation cameras exist, including `AtticAssetCloseupCamera`.
- Passed: old custom attic chest and jack-in-the-box asset paths were not found in the attic stage props.

## Follow-Up Gate
- Recover or restart the live editor session so it reloads `home_yard_v3_map.tscn` from disk.
- Re-capture `AtticStartPlayerCamera`, `AtticRouteCamera`, `AtticAssetCloseupCamera`, and `AtticGableProfileCamera`.
- Score the assets for route readability, scale, silhouette, material quality, collision risk, and visual confusion before production acceptance.
