# Furnishings Reference

## Design Intent

Furnishings should make every room and course identity readable at racing speed. They must be real assets from Kenney, Meshy, or toybox fallback, not visible Godot boxes.

## Reference Images Or Links

- `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/kitchen/stage_concept.md`
- `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/playroom/stage_concept.md`
- `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/bedroom/stage_concept.md`
- `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/glam_closet/stage_concept.md`
- `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/attic/stage_concept.md`

## Shape Language

Strong silhouettes: refrigerator/sink/cabinets/cutting board for kitchen, ring/grandstand/marble machine for playroom, bed/blanket/lamp/toy triage for bedroom, mirror/vanity/jewelry/perfume for glam closet, trunk/sheets/boxes/string mechanisms for attic.

## Material Palette

Room-specific material hierarchy with low-poly simplicity: glossy appliances and tile, foam/plastic playroom pieces, plush bedroom fabric, glam mirror/glitter/metal accents, attic cardboard/wood/cloth/string.

## Gameplay Readability Notes

Furnishings are route-side landmarks unless explicitly authored as hazards. Visual-only assets should have collision disabled or isolated. Support-face placement must be validated so objects rest on floors, counters, shelves, beds, or walls.

## Asset Prompt Notes

Each prompt must state intended area, gameplay role, scale, poly budget, collision policy, and validation camera. Avoid tiny surface detail that disappears from the racing camera.
