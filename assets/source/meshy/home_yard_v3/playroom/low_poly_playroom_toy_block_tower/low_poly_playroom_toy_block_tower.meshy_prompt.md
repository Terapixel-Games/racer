# low_poly_playroom_toy_block_tower Meshy Prompt Record

## Asset Intent
- Intended area: playroom
- Gameplay role: block tower / grandstand landmark and route-side arena dressing
- Visible classification: visible landmark
- Replacement decision: new Meshy course-identity asset
- Supersedes:

## Meshy Request
- Prompt: Low-poly game-ready toy-scale playroom toy block tower landmark for arcade kart racing. Bright clean plastic blocks stacked like arena grandstand columns, red yellow blue trophy gold palette, Slammo champion arena style, broad readable silhouette, no readable text, no logos, no humans, no tiny clutter, GLB-friendly off-route dressing.
- Negative prompt: letters, numbers, logos, humans, messy clutter pile, unstable thin parts, high-poly bevel clutter, unreadable tiny blocks, route blocker
- Target format: glb
- Poly budget: 8000 triangles
- Scale: toy-scale off-route playroom landmark for `home_yard_v3`
- Meshy task id: `019e202a-0778-7adf-a7b0-6f251e4df793`
- Credits spent: 20 preview credits
- Source concept image/reference: `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/playroom/stage_key_art.png`, `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/playroom/stage_concept.md`

## Material Notes
- Materials: clean molded toy plastic, foam mat contact pads, trophy-gold accent pieces
- Transparent materials: none
- Texture constraints: solid saturated colors; no labels, letters, or numbers
- Godot import notes: GLB only; collision helpers authored separately

## Gameplay Integration
- Collision policy: visual off-route
- Route clearance: pending
- Placement notes: no playable shortcut or route topology change
- Validation cameras: PlayroomAssetCloseupCamera, PlayroomRouteCamera

## Validation Result
- Triangle result: pending
- Import health: passed headless Godot import
- Scale/origin check: pending
- Material readability: pending
- Player-height screenshot review: pending
- Final status: imported_generator_integrated_pending_visual_validation

## Toybox Training Notes
- Prompt lessons: request block grandstand/tower silhouette, not a random pile.
- Shape language: stacked vertical columns, broad color blocks, arena pageantry.
- Failure cases to avoid: readable letters, tiny block noise, unstable geometry.
