# low_poly_dusty_attic_trunk Meshy Prompt Record

## Asset Intent
- Intended area: attic
- Gameplay role: route-side prank trunk landmark and future false-gate visual hook; non-playable shortcut dressing for this pass
- Visible classification: visible landmark
- Replacement decision: Meshy regenerate
- Supersedes: `res://assets/gameplay/tracks/attic/props/old_chest.glb`

## Meshy Request
- Prompt: Low-poly game-ready toy-scale pristine attic prank trunk landmark for arcade kart racing. Clean polished wooden storage trunk with subtle false-gate/prank mechanism cues, tidy cardboard and string accents, Popper purple accent pieces, uncanny but not dirty, readable silhouette from kart camera, no text, no logos, no humans.
- Negative prompt: dirty abandoned horror chest, gore, readable text, logos, humans, realistic clutter noise, tiny unreadable details, high-poly sculpt, broken route blocker
- Target format: glb
- Poly budget: 8000 triangles
- Scale: toy-scale route-side landmark for `home_yard_v3` attic
- Meshy task id: `019e2003-38b1-7185-a926-d591c2ba4a2c`
- Credits spent: 20 preview credits
- Source concept image/reference: `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/attic/stage_key_art.png`, `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/attic/stage_concept.md`

## Material Notes
- Materials: clean trunk wood, cardboard tan, string, subtle toy plastic prank accents
- Transparent materials: none
- Texture constraints: readable under Godot mobile lighting; avoid baked text
- Godot import notes: GLB only; collision helpers authored separately

## Gameplay Integration
- Collision policy: visual off-route or simple static helper if used as boundary
- Route clearance: pending
- Placement notes: do not create a playable shortcut or route topology change
- Validation cameras: AtticAssetCloseupCamera, AtticStartPlayerCamera

## Validation Result
- Triangle result: pending
- Import health: passed headless Godot import
- Scale/origin check: pending
- Material readability: pending
- Player-height screenshot review: pending
- Final status: imported_generator_integrated_pending_visual_validation

## Toybox Training Notes
- Prompt lessons: emphasize pristine attic and prank trunk rather than dirty chest
- Shape language: broad trunk silhouette, false-gate/prank cues, string/cardboard accents
- Failure cases to avoid: horror chest, text labels, tiny mechanism clutter, route-blocking scale
