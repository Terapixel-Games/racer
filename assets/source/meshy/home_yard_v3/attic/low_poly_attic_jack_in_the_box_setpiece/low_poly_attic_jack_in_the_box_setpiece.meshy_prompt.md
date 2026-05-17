# low_poly_attic_jack_in_the_box_setpiece Meshy Prompt Record

## Asset Intent
- Intended area: attic
- Gameplay role: prank setpiece and visual hazard/future false-gate hook; non-playable shortcut dressing for this pass
- Visible classification: visible landmark
- Replacement decision: Meshy regenerate
- Supersedes: `res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn`

## Meshy Request
- Prompt: Low-poly game-ready toy-scale attic jack-in-the-box prank setpiece for arcade kart racing. Clean playful uncanny toy mechanism, compact box with spring/prank silhouette and false-gate visual language, cardboard, polished wood, string, toy plastic, Popper purple accents, readable from kart camera, no character body, no text, no logos, no humans.
- Negative prompt: humanoid clown character, horror gore, dirty abandoned prop, readable text, logos, high-poly tiny springs, fragile snaggy mesh, gameplay collision maze
- Target format: glb
- Poly budget: 8000 triangles
- Scale: toy-scale route-side setpiece for `home_yard_v3` attic
- Meshy task id: `019e2003-5692-7187-ba1d-3bf713138951`
- Meshy refine task id: `019e2009-d9c3-7244-997b-3476c1235308`
- Credits spent: 30 credits (20 preview + 10 refine)
- Source concept image/reference: `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/attic/stage_key_art.png`, `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/attic/stage_concept.md`

## Material Notes
- Materials: clean toy plastic, cardboard, polished wood, string, Popper purple accents
- Transparent materials: none
- Texture constraints: no readable labels; strong simple color blocks
- Godot import notes: GLB only; collision helpers authored separately

## Gameplay Integration
- Collision policy: visual off-route or named prank hazard only after explicit validation
- Route clearance: pending
- Placement notes: no lap/progress shortcut behavior in this pass
- Validation cameras: AtticAssetCloseupCamera

## Validation Result
- Triangle result: pending
- Import health: passed headless Godot import after stale `.import` metadata was regenerated
- Scale/origin check: pending
- Material readability: pending
- Player-height screenshot review: pending
- Final status: imported_generator_integrated_pending_visual_validation

## Toybox Training Notes
- Prompt lessons: ask for setpiece/mechanism, not a character
- Shape language: compact box, spring/prank silhouette, false-gate visual language
- Failure cases to avoid: clown figure, text, dense spring geometry, horror mood
