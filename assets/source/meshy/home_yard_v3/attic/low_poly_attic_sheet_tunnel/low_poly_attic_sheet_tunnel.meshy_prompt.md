# low_poly_attic_sheet_tunnel Meshy Prompt Record

## Asset Intent
- Intended area: attic
- Gameplay role: clean sheet tunnel landmark and non-playable shortcut visual hook for this pass
- Visible classification: visible landmark
- Replacement decision: new Meshy course-identity asset
- Supersedes:

## Meshy Request
- Prompt: Low-poly game-ready toy-scale clean attic sheet tunnel for arcade kart racing. White cloth tunnel draped over tidy box supports with string ties and subtle prank route cues, camera-safe wide opening, pristine not dirty, strong route-readable silhouette, cardboard tan and Popper purple accents, modular GLB-friendly landmark, no text, no logos, no humans.
- Negative prompt: dirty horror sheet, cramped unusable tunnel, humans, ghosts, readable text, logos, high-poly cloth wrinkles, dark unreadable interior, fragile collision snag
- Target format: glb
- Poly budget: 8000 triangles
- Scale: toy-scale route landmark for `home_yard_v3` attic
- Meshy task id: `019e2003-747f-7e3c-b237-4cc7afff7c05`
- Credits spent: 20 preview credits
- Source concept image/reference: `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/attic/stage_key_art.png`, `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/attic/stage_concept.md`

## Material Notes
- Materials: clean white cloth, cardboard supports, string ties, Popper purple accents
- Transparent materials: none
- Texture constraints: broad cloth folds, no noisy wrinkle detail
- Godot import notes: GLB only; collision helpers authored separately if used on route

## Gameplay Integration
- Collision policy: visual off-route; tunnel helper collision only after camera-safe validation in a later pass
- Route clearance: pending
- Placement notes: no new playable shortcut; visual hook only in this pass
- Validation cameras: AtticRouteCamera, AtticAssetCloseupCamera

## Validation Result
- Triangle result: pending
- Import health: passed headless Godot import
- Scale/origin check: pending
- Material readability: pending
- Player-height screenshot review: pending
- Final status: imported_generator_integrated_pending_visual_validation

## Toybox Training Notes
- Prompt lessons: clean sheet tunnel must be wide, readable, and toy-scale
- Shape language: white cloth arch over box supports with string ties
- Failure cases to avoid: ghost imagery, cramped passage, noisy cloth, dark interior
