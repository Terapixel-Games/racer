# low_poly_playroom_plush_landmark Meshy Prompt Record

## Asset Intent
- Intended area: playroom
- Gameplay role: route-side plush arena mascot landmark; non-playable dressing
- Visible classification: visible landmark
- Replacement decision: Meshy regenerate / upgrade candidate
- Supersedes: `res://assets/source/kenney/furniture_kit/bear.glb` if strict Kenney keep-review fails

## Meshy Request
- Prompt: Low-poly game-ready toy-scale playroom plush landmark for arcade kart racing. Clean champion arena playroom, Slammo red accents, plush toy mascot silhouette on a small molded plastic podium, foam mat base, trophy-sports pageantry without readable text, route-side landmark readable from kart camera, no logos, no humans, no letters, GLB-friendly.
- Negative prompt: readable text, logos, humans, horror toy, dirty fabric, dense fur, fragile thin parts, route blocker, high-poly sculpt
- Target format: glb
- Poly budget: 8000 triangles
- Scale: toy-scale route-side landmark for `home_yard_v3` playroom
- Meshy task id: `019e2029-e547-7721-8f5e-80c63e7ee736`
- Credits spent: 20 preview credits
- Source concept image/reference: `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/playroom/stage_key_art.png`, `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/playroom/stage_concept.md`

## Material Notes
- Materials: plush fabric, molded plastic podium, foam mat base, Slammo red accents
- Transparent materials: none
- Texture constraints: no readable labels; strong simple color blocks
- Godot import notes: GLB only; collision helpers authored separately

## Gameplay Integration
- Collision policy: visual off-route, collision disabled or isolated
- Route clearance: pending
- Placement notes: no playable shortcut or route topology change
- Validation cameras: PlayroomAssetCloseupCamera, PlayroomStartPlayerCamera

## Validation Result
- Triangle result: pending
- Import health: passed headless Godot import
- Scale/origin check: pending
- Material readability: pending
- Player-height screenshot review: pending
- Final status: imported_generator_integrated_pending_visual_validation

## Toybox Training Notes
- Prompt lessons: combine plush mascot silhouette with arena podium, not a character.
- Shape language: broad plush landmark, podium base, trophy-sports accents.
- Failure cases to avoid: text, logos, dense fur, horror mood, route-blocking scale.
