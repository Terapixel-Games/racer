# Kitchen Normalization Regression Retro

## Context

The Kitchen stage had a mostly correct hand-authored layout before the normalization pass. The intended work was small spatial polish: snap cabinets, appliances, walls, ceiling, and effects into cleaner alignment while preserving the current layout, route, and MVP chaos.

The pass instead treated the scene as a normalization target and changed the world enough to damage the player-facing result.

## What Went Wrong

- Kitchen props floated above the floor.
- The ceiling clipped through tall objects.
- Walls were removed or left open, breaking the room envelope.
- Positional effects were no longer aligned with the sink, washer, and related fixtures.
- The result was worse from normal race-camera views even though the pass had technical goals.

## Root Causes

- The pre-pass Kitchen was not treated as the spatial baseline.
- "Normalize the stage" was interpreted as permission to reshape the world instead of preserving world-space relationships.
- Floor-zero and broad transform cleanup were attempted without proving that every dependent node moved by the same delta.
- Technical tests were treated as sufficient acceptance, but visual and player-quality review were missing.
- The pass did not require before/after screenshots from the route, level-select angle, floor-level view, ceiling clearance, wall corners, or effect anchors before accepting changes.
- The player question, "why would I want to play this stage again?", was not part of the acceptance gate.

## Corrected Principles

- Preserve the authored baseline unless the user explicitly asks for a redesign.
- Treat normalization as a high-risk feature, not routine cleanup.
- Prefer local measured snapping over global root/floor changes.
- If a base transform must move, prove road, props, effects, spawns, checkpoints, audio, cameras, and exported metadata all moved consistently.
- For Kitchen MVP, preserve the current chaos and fantasy while polishing alignment and containment.
- Review every world-building pass from player camera height and route samples, not only editor or overhead views.

## Required Gates For Future Kitchen Work

- Capture before/after views from the start grid, low floor/player view, overhead route, level-select angle, cabinet/wall runs, wall corners, ceiling clearance, sink/washer effect anchors, and representative route cells.
- Produce a transform manifest for moved objects: node path, old transform, new transform, delta, reason, and affected validation views.
- Keep the stage root, floor origin, RoadGridMap, checkpoints, and broad room origin fixed unless a separate normalization gate is approved.
- Snap cabinet backs to wall faces, cabinet bottoms to floor/countertop, appliances to adjacent cabinets with small gaps, walls/door frames/ceilings to corners, and effects to their current fixture anchors.
- Keep Kitchen spawns aligned to the route start: `ordered_route_cells[0]`.
- Use generated fallback spawns for Kitchen unless authored slots are intentionally reintroduced.
- Run relevant Godot tests and report failures honestly.

## Acceptance Question

Kitchen is not accepted because it is merely driveable. It is accepted when the restored baseline is visibly improved, route views are coherent, containment does not leak, camera clearance is comfortable, the first seconds are readable, and the stage has enough charm and pace that a player would want another lap.
