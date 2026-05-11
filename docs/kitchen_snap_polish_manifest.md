# Kitchen Snap Polish Manifest

This pass preserves the restored Kitchen baseline. It does not move the scene root, floor origin, RoadGridMap, route cells, checkpoints, or broad room origin.

## Transform Changes

| Node | Old transform value | New transform value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/RoomShell/Ceiling` | Missing | `origin=(0, 53.2, 0)`, `scale=(316.4062, 1.4, 221.22151)` | Added | Restore a complete room envelope with ceiling clearance above the fridge, hood, upper cabinets, and doorway while intersecting wall tops to avoid ceiling leaks. |
| `Track/RoomShell/kitchenCabinet25` | `origin.y=-9.03031` | `origin.y=-10` | `-0.96969` | Align right-side cabinet bottom to the lower-cabinet floor baseline. |
| `Track/RoomShell/kitchenCabinet26` | `origin.y=-9.030308` | `origin.y=-10` | `-0.969692` | Align right-side cabinet bottom to the lower-cabinet floor baseline. |
| `Track/RoomShell/doorwayOpen` | `origin.y=-9.231991` | `origin.y=-10` | `-0.768009` | Align door frame bottom to the lower-cabinet floor baseline. |
| `Track/RoomShell/washer` | `origin.y=-9.231987` | `origin.y=-10` | `-0.768013` | Align washer bottom to adjacent floor/cabinet baseline. |
| `Track/RoomShell/dryer` | `origin.y=-9.231991` | `origin.y=-10` | `-0.768009` | Align dryer bottom to adjacent floor/cabinet baseline. |
| `Track/RoomShell/bookcaseOpen` | `origin.y=-9.231991` | `origin.y=-10` | `-0.768009` | Remove small floor float on right-wall fixture. |
| `Track/RoomShell/bookcaseOpen2` | `origin.y=-9.231991` | `origin.y=-10` | `-0.768009` | Remove small floor float on right-wall fixture. |
| `Track/Appliances/doorway` | `origin.y=-9.231991` | `origin.y=-10` | `-0.768009` | Align appliance-side doorway frame to floor baseline. |
| `Track/WaterSurfaces/SinkWater` | `origin.x=-92.59528` | `origin.x=-98.55` | `-5.95472` | Center sink water over the paired sink fixtures. |
| `Track/WaterSurfaces/WasherWater` | `origin=(87.07662, 1.1761613, -73.46675)` | `origin=(15.42, 2.5, 73.36)` | `(-71.65662, 1.3238387, 146.82675)` | Move washer water from the opposite side of the room to the washer face. |

## Validation Views

The affected views are `low_floor_player`, `level_select_angle`, `back_cabinet_wall_run`, `left_wall_corner_run`, `ceiling_clearance`, `sink_effect_anchor`, and `washer_effect_anchor`. The `overhead_route` capture is an inspection view that temporarily hides `Dressing/EditableRoom/Track/RoomShell/Ceiling` so the route and floor envelope remain visible after adding a ceiling.

## Measured Checks

- Floor remains at the restored baseline: `Track/floor.min_y=-20.703`.
- Lowered fixtures now land on the shared object baseline: cabinets 25/26, doorway frames, washer, dryer, and bookcases report `min_y=-20`.
- Ceiling reports `min_y=105` and `max_y=107.8`; tallest non-wall fixtures checked were hood `max_y=88.01`, refrigerator `max_y=84.37`, and upper cabinets `max_y=86`.
- Sink water is centered across the paired sink fixtures on X and remains inside the sink basin height.
- Washer water is centered on the washer face: `x=22.5..39.18` against washer `x=11.33..50.33`, and `z=146.72` against washer front `z=147.32`.

## Player Read

This is still the MVP chaotic Kitchen, not a redesign. The pass is intended to make the room feel complete, reduce distracting floating props, and put effects back where players expect them while preserving the current toy-road layout and route fantasy.

## Craft Review Follow-Up

The first snap pass exposed a more important rule: hand-built stages can be spatially correct but still below quality bar. Baseline preservation keeps the route, room origin, and fantasy intact; it does not preserve crooked craft. This follow-up fixes the defects found during close review.

| Node | Old transform value | New transform value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/RoomShell/DoorHeader` | `origin.y=45.854355`, `scale.y=12` | `origin.y=46.625`, `scale.y=13.55` | `origin.y +0.770645`, `scale.y +1.55` | Close the visible gap above the front door frame by overlapping the ceiling band while preserving the door opening bottom. |
| `Track/RoomShell/RightWall` | `origin.y=21`, `scale.y=68.56597` | `origin.y=20.3075`, `scale.y=67.185` | `origin.y -0.6925`, `scale.y -1.38097` | Make the right wall top meet the ceiling instead of protruding through it. |
| `Track/RoomShell/RightWall2` | `origin.y=21`, `scale.y=68.56597` | `origin.y=20.3075`, `scale.y=67.185` | `origin.y -0.6925`, `scale.y -1.38097` | Match the right-wall segment top to the ceiling seam. |
| `Track/RoomShell/RightWall3` | `origin.y=21`, `scale.y=68.56597` | `origin.y=20.3075`, `scale.y=67.185` | `origin.y -0.6925`, `scale.y -1.38097` | Match the right-wall segment top to the ceiling seam. |
| `Track/RoomShell/RightWall4` | `origin.y=49.97618`, `scale.y=16.144611` | `origin.y=47.905`, `scale.y=12` | `origin.y -2.07118`, `scale.y -4.144611` | Remove the visible high wall protrusion above the ceiling line. |
| `Track/RoomShell/DoorwayOpenHeader` | Missing | `origin=(-37.65, 46.85, 65.75)`, `scale=(3.2, 14.1, 24)` | Added | Fill the interior doorway gap between the doorway prefab top and the ceiling/wall seam. |
| `Track/RoomShell/FrontWallRight` | `origin.y=21`, `scale.y=66.385` | `origin.y=20.85375`, `scale.y=66.0925` | `origin.y -0.14625`, `scale.y -0.2925` | Align the front-wall top with the ceiling seam. |
| `Track/RoomShell/FrontWallRight2` | `origin.y=21`, `scale.y=66.385` | `origin.y=20.85375`, `scale.y=66.0925` | `origin.y -0.14625`, `scale.y -0.2925` | Align the front-wall top with the ceiling seam. |
| `Track/RoomShell/kitchenCabinetCornerInner4` | `origin.y=-9.030309` | `origin.y=-10` | `-0.969691` | Level the right countertop/cabinet corner with adjacent cabinets. |
| `Track/Appliances/hoodModern` | `origin=(-128.67912, 25.528194, -20.211254)` | `origin=(-125.6066, 25.528194, -12.746695)` | `(+3.07252, 0, +7.464559)` | Center the vent hood over the stove/cooktop bounds. |
| `Track/WaterSurfaces/WasherWater` | `scale=(8.337667, 6.7815514)`, `origin=(15.42, 2.5, 73.36)` | `scale=(5.2, 4.8)`, `origin=(15.42, 2.5, 73.95)` | Shrunk and moved `+0.59z` | Keep the water effect inside the washer door/glass instead of floating on the exterior. |
| `Track/UpperCabinets/LeftUpperCabinetD` | Present at `origin=(-133.17755, 23.5, 44.20774)` | Removed | Removed | Reserve a real fridge void so the upper cabinet no longer intersects the refrigerator. |

## Craft Follow-Up Measured Checks

- `DoorHeader.max_y=106.8`, overlapping the ceiling band `105..107.8`.
- `DoorwayOpenHeader` reports `x=-78.5..-66.5`, `y=79.6..107.8`, and `z=106..157`, overlapping the doorway prefab top and bridging the adjacent wall segments to the ceiling seam.
- Right/front wall tops now resolve to about `max_y=107.8`, matching the ceiling line.
- `kitchenCabinetCornerInner4` now reports `min_y=-20` and `max_y=25`, matching adjacent lower cabinets.
- `hoodModern` now shares the stove Z span `-68.49..-25.49` and is centered over the cooktop footprint.
- `WasherWater` now reports `x=25.64..36.04`, `y=0.2..9.8`, `z=147.9`, contained within washer bounds `x=11.33..50.33`, `y=-20..27`, `z=147.32..186.32`.
- `LeftUpperCabinetD` was removed to preserve fridge clearance; `LeftUpperCabinetE` begins at `z=101.42`, beyond refrigerator `z=98.76`.

## Craft Validation Views

The follow-up capture added precision gates: `door_lintel_seam`, `rear_doorway_header_gap`, `right_countertop_corner`, `washer_water_containment`, `stove_hood_appliance_slot`, `oven_side_gap_closeup`, `fridge_upper_clearance`, and `right_wall_ceiling_seam`. The route/player views remain in the capture harness; the close-up gates are mandatory for accepting cabinet, appliance, effect, and envelope polish.

## Slot And Seam Correction

The second craft review found remaining wall gaps and lower-cabinet clipping into the oven. The root miss was checking top heights and hood centering without validating horizontal wall extents or negative space around the stove.

| Node | Old transform value | New transform value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/RoomShell/BackWallLeftOfWindow` | `origin.y=21`, `scale.y=64.53761` | `origin.y=21.315598`, `scale.y=65.16881` | `origin.y +0.315598`, `scale.y +0.6312` | Overlap the ceiling band instead of leaving a sub-unit top seam. |
| `Track/RoomShell/BackWallRightOfWindow` | `origin.y=21`, `scale.y=64.53761` | `origin.y=21.315598`, `scale.y=65.16881` | `origin.y +0.315598`, `scale.y +0.6312` | Overlap the ceiling band instead of leaving a sub-unit top seam. |
| `Track/RoomShell/LeftWall` | `origin.y=22.300934`, `scale.y=60.449`, `scale.z=193.426` | `origin.y=22.98815`, `scale.y=61.823566`, `scale.z=198.2` | `origin.y +0.687216`, `scale.y +1.374566`, `scale.z +4.774` | Close front/back corner gaps and overlap the ceiling band. |
| `Track/RoomShell/FrontWallLeft` | `origin.y=21.195286`, `scale.y=62.42` | `origin.y=21.942642`, `scale.y=63.914715` | `origin.y +0.747356`, `scale.y +1.494715` | Close the visible top seam under the ceiling. |
| `Track/RoomShell/DoorwayOpenHeader` | `origin=(-37.65, 46.85, 65.75)`, `scale=(3.2, 14.1, 24)` | `origin=(-36.25, 46.85, 65.75)`, `scale=(6, 14.1, 25.5)` | Wider/deeper header | Cover the full interior doorway frame width and adjacent wall/header seam. |
| `Track/RoomShell/kitchenCabinet13` | `origin.z=-31.019432` | `origin.z=-35.353668` | `-4.334236` | Open a left-side oven gap instead of intersecting the stove AABB. |
| `Track/RoomShell/kitchenCabinet14` | `origin.z=-52.565254` | `origin.z=-56.89949` | `-4.334236` | Move the adjacent cabinet chain with `kitchenCabinet13` to preserve the run. |
| `Track/RoomShell/kitchenCabinet15` | `origin.z=6.597663` | `origin.z=8.14663` | `+1.548967` | Open a right-side oven gap instead of intersecting the stove AABB. |
| `Track/RoomShell/kitchenCabinet17` | `origin.z=23.536942` | `origin.z=25.085909` | `+1.548967` | Move the adjacent cabinet chain with `kitchenCabinet15` to preserve the run. |

## Slot And Seam Measured Checks

- `LeftWall` now spans `z=-198.2..198.2`, overlapping both front wall `z=-198..-194` and back wall `z=194..198`.
- `BackWallLeftOfWindow`, `BackWallRightOfWindow`, `FrontWallLeft`, and `LeftWall` now all report `max_y=107.8`, matching the ceiling top line.
- `DoorwayOpenHeader` now spans `x=-78.5..-66.5`, covering the doorway frame width `x=-76.19..-67.28`.
- `kitchenCabinet13.max_z=-70.49` and `kitchenStove.min_z=-68.49`, leaving about `2` world units of left-side oven clearance.
- `kitchenCabinet15.min_z=-23.49` and `kitchenStove.max_z=-25.49`, leaving about `2` world units of right-side oven clearance.

## Craft Replay Read

From route and fixture cameras, this pass should make repeat laps feel less like driving through a broken prototype: the doorway no longer exposes a frame gap, the wall/ceiling edges read as intentional enclosure, the washer effect is contained, the stove/hood/fridge area is no longer visibly interpenetrating, and the right counter run has a shared top plane. The Kitchen is still intentionally MVP-chaotic; deeper Sir Clink theming and richer replay hooks remain a later creative pass.
