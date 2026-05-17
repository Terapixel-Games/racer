# Interior Layout Reference

## Design Intent

The interior should explain the house layout clearly: main floor public rooms, upper floor private rooms, attic storage, vertical connectors, and thresholds. Each room must feel inhabited and functional before faction dressing is added.

## Reference Images Or Links

- `res://docs/story_bible/concepts/floor_plans/racer_house_yard_concept_floor_plan.png`
- `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/kitchen/stage_concept.md`
- `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/playroom/stage_concept.md`
- `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/bedroom/stage_concept.md`
- `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/glam_closet/stage_concept.md`
- `res://docs/story_bible/concepts/stages/legacy_home_yard_courses/attic/stage_concept.md`

## Shape Language

Rooms need clear floors, walls, ceilings, openings, thresholds, vertical links, and circulation paths. Furniture should identify room function and reinforce boundaries without making the route feel cluttered.

## Upper Floor Plan Addendum

The upper floor uses a front hallway/landing band for the main stair, room doorways, and attic-access doorway language. The Bedroom and Glam Closet territories should be pushed back toward the rear upper-floor wall rather than remaining centered in the old footprint after the hall is carved out. The front band is circulation; the rear zones are the playable private-room courses.

- Bedroom rear room zone: spans the rear upper floor behind the front hall, with its public doorway on the hall divider.
- Glam Closet rear room zone: spans the rear upper floor behind the front hall, with its public doorway on the hall divider and the Bedroom/Glam cased opening kept inside the rear room depth.
- Main stair: lands in the front entry/upper hall, never in the garage/service bay.
- Attic access: reads as a doorway/hatch off the upper hall, not as a disconnected prop inside a room route.
- Validation: generated bounds must prove the front hall band exists, bedroom/glam zones are reflowed to the rear wall, and no leftover dead rear strip remains after adding the hall.

## Attic And Roof Clearance Addendum

The attic course occupies the playable central volume inside the Dutch gambrel roof. Exterior shell closure may seal eaves, gables, rakes, fascia, and perimeter soffits, but it must not create a full-footprint flat slab across the attic floor or route volume.

- Attic playable zone: central floor and route corridor remain clear from the finished attic deck upward through the declared human/player clearance volume.
- Roof closure: use perimeter/eave/gable/rake pieces or sloped underside planes derived from the roof contract; avoid broad rectangular closure planes under the roof.
- Hatch/ladder: attic access remains clear through the upper-floor assembly and must not be capped by roof closure geometry.
- Validation: roof, soffit, fascia, gable, and closure node bounds must be checked against the attic route envelope, human clearance marker, hatch opening, and attic player-height cameras.

## Material Palette

Kitchen tile and cabinets, playroom mats and toy plastics, bedroom carpet/fabric/wood, glam closet glossy shelves/mirrors/fabric, attic planks/beams/cardboard/cloth.

## Gameplay Readability Notes

Routes must be legible within the first seconds from start cameras. Room boundaries and route edges should not fight each other. Furniture and fixtures should read as landmarks, boundaries, hazards, or off-route decor with explicit collision policy.

## Asset Prompt Notes

Prompts should produce furniture and fixtures as room-specific low-poly objects: cabinets, bed, lamp, vanity, shelves, trunk, sheet tunnel, toy arena pieces, and route landmarks sized for toy-kart gameplay.
