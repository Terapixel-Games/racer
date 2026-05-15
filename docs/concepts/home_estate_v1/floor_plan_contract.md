# Home Estate V1 Floor Plan Contract

## Source

User-provided three-sheet residential plan:

- Main floor: 72 ft wide by 69 ft 2 in deep, 1,800 sq ft.
- Upper floor: 1,086 sq ft plus future bonus room.
- Basement: basement plus unexcavated zones.

Style and image reference:

- Monster House Plans Plan 38-526 modern farmhouse page supplied by the user: two-story, four-bedroom, three-car garage, broad covered porches, and layered gable roof hierarchy.
- The generated stage should read as a modern farmhouse game environment, not as a literal floor-plan diagram.
- Visible room-name labels, plan annotations, and bare diagram markers are validation defects in the playable scene.

## Orientation And Scale

- Front/street is `+Z`; rear patio/backyard is `-Z`.
- `1 floor-plan foot = 4 Godot units`.
- Human-scale house shell remains authoritative; toy racers and road overlays are small objects inside it.

## Main Floor Program

- `three_car_garage`: 24 ft by 30 ft 6 in, left/rear side, 10 ft 6 in ceiling.
- `mud_office_service`: mud room, office, pantry, pool/garage bath, service bench.
- `kitchen_dining`: kitchen 11 ft 6 in by 14 ft with island, pantry, dining 10 ft by 13 ft.
- `great_room`: 16 ft 8 in by 21 ft 8 in, fireplace, 12 ft ceiling, open stair adjacency.
- `master_suite`: 13 ft by 16 ft, bath, WIC, vaulted private wing.
- `covered_porch_front`: 10 ft by 26 ft.
- `covered_porch_rear`: 10 ft by 26 ft.
- `rear_patio_pool_edge`: patio, optional garage seating, pool-adjacent area. Pool is reference only and not included as playable water in this scaffold.

## Upper Floor Program

- `upper_loft`: 11 ft 4 in by 16 ft, built-ins and stair landing.
- `upper_bedroom_west`: 11 ft by 11 ft 4 in.
- `upper_bedroom_east`: 12 ft 8 in by 13 ft.
- `upper_bedroom_rear`: 12 ft by 12 ft.
- `upper_bath_laundry`: bath, WICs, washer/dryer.
- `future_bonus_room`: 12 ft by 20 ft over the garage, planned but not route-primary in the first scaffold.

## Basement Program

- `basement_shell`: broad lower-level route/readability test area.
- `unexcavated_zones`: visible foundations only; not playable route space.

## Racing Mode Scaffold

First-pass modes are map modes only and do not replace the current eight public `home_yard_v3` course ids:

- `estate_kitchen`
- `estate_great_room`
- `estate_garage`
- `estate_master_suite`
- `estate_upper_loft`
- `estate_patio`

## Gates

- Scene and map definition must be generator-driven.
- Main, upper, patio, and basement holders must exist.
- Routes must use RoadGridMap metadata, closed loops, spawn slots, and exported metadata.
- No public course id remap occurs in this scaffold pass.
- The stage should be registered as map `home_estate_v1`, with mode definitions available through `TrackCatalog.get_mode_definition("home_estate_v1", mode_id)`.
- The generated scene must include visible architectural/furnishing stand-ins for room identity until sourced Kenney/Meshy/toybox assets replace them.
- Tests must fail if visible `Label3D` plan labels are present in the stage scene.
