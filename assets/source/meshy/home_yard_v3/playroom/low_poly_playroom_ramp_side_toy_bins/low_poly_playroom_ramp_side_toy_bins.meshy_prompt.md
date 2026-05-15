# low_poly_playroom_ramp_side_toy_bins Meshy Prompt Record

## Asset Intent
- Intended area: playroom
- Gameplay role: ramp-side toy bin and soft block route boundary dressing
- Visible classification: visible landmark / boundary dressing
- Replacement decision: new Meshy course-identity asset
- Supersedes:

## Meshy Request
- Prompt: Low-poly game-ready toy-scale playroom ramp-side toy bin set for arcade kart racing. Clean foam mat playroom arena, colorful toy storage bins and soft block guards arranged as route-side boundary dressing, Slammo red accents, trophy-sports energy, readable from kart camera, no playable shortcut, no text, no logos, no humans, no fragile thin pieces, GLB-friendly.
- Negative prompt: readable labels, logos, humans, cluttered trash, dirty room, high-poly tiny toys, fragile handles, route-blocking maze, playable shortcut gate
- Target format: glb
- Poly budget: 8000 triangles
- Scale: toy-scale route-side boundary set for `home_yard_v3` playroom
- Meshy task id: `019e202a-3936-71e1-b52a-f47ed664b4f2`
- Credits spent: 20 preview credits
- Source concept image/reference: `res://assets/gameplay/tracks/playroom/stage_key_art.png`, `res://assets/gameplay/tracks/playroom/stage_concept.md`

## Material Notes
- Materials: molded plastic bins, soft foam blocks, foam mat contact surfaces, Slammo red accents
- Transparent materials: none
- Texture constraints: broad readable colors; no labels
- Godot import notes: GLB only; collision helpers authored separately

## Gameplay Integration
- Collision policy: visual off-route unless explicitly converted to route boundary collision
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
- Prompt lessons: frame bins as route-side boundary dressing, not clutter.
- Shape language: storage bins, soft block guards, foam mat base.
- Failure cases to avoid: text labels, clutter pile, fragile handles, shortcut gate.
