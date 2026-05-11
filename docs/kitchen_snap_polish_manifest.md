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

## Wall Seam Cover Correction

The third wall review showed that exact butt-jointed modular wall boxes can still read as hairline cracks from editor/player cameras. This correction adds intentional wall-color overlap strips on visible coplanar wall joints instead of relying on adjacent box faces to render as one sealed surface.

| Node | Old transform value | New transform value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/RoomShell/WallSeamCovers/BackWallWindowLeftSeamCover` | Missing | `origin=(-124, 26.95, 97.6)`, `scale=(1.5, 53.9, 0.35)` | Added | Cover the left vertical back-wall/window panel joint. |
| `Track/RoomShell/WallSeamCovers/BackWallWindowRightSeamCover` | Missing | `origin=(-70, 26.95, 97.6)`, `scale=(1.5, 53.9, 0.35)` | Added | Cover the right vertical back-wall/window panel joint. |
| `Track/RoomShell/WallSeamCovers/RightWallDoorLeftSeamCover` | Missing | `origin=(-37, 20.3, 53.8)`, `scale=(0.35, 67.2, 1.5)` | Added | Cover the visible left doorway/right-wall panel seam. |
| `Track/RoomShell/WallSeamCovers/RightWallDoorRightSeamCover` | Missing | `origin=(-37, 20.3, 77.5)`, `scale=(0.35, 67.2, 1.5)` | Added | Cover the visible right doorway/right-wall panel seam. |

The capture harness now includes `right_wall_panel_joints` and `back_wall_window_joints` so these modular wall seams are checked directly instead of inferred from broad route screenshots.

## Cabinet Wall Closure Correction

The fourth review showed that cabinet/counter runs still exposed bright negative space where imported fixture backs did not reach the back/right wall planes. This was not a wall-panel seam; it was a fixture-to-envelope closure miss. The correction adds intentional wall-trim colored deck fillers and backsplash strips so the cabinet/counter run reads as built into the room instead of floating in front of the walls.

| Node | Old transform value | New transform value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/RoomShell/CabinetWallClosures/BackCounterDeckFiller` | Missing | `origin=(-36.25, 12.35, 94.9)`, `scale=(217.5, 0.35, 4.4)` | Added | Cover the horizontal top gap between the back counter/appliance run and the back wall face. |
| `Track/RoomShell/CabinetWallClosures/BackCounterBacksplash` | Missing | `origin=(-36.25, 14.1, 96.7)`, `scale=(217.5, 3, 0.55)` | Added | Add an intentional vertical backsplash against the back wall so model backs do not reveal a slot. |
| `Track/RoomShell/CabinetWallClosures/RightCounterDeckFiller` | Missing | `origin=(71.2, 12.35, 59)`, `scale=(1.7, 0.35, 76)` | Added | Cover the horizontal top gap between the right cabinet/corner run and the right wall face. |
| `Track/RoomShell/CabinetWallClosures/RightCounterBacksplash` | Missing | `origin=(71.4, 14.1, 59)`, `scale=(0.55, 3, 76)` | Added | Add an intentional vertical backsplash against the right wall so side gaps read as closed trim. |

The capture harness now includes `counter_wall_closure`, a direct view of the back/right cabinet-to-wall closure that previously needed manual screenshot review to catch.

Measured closure checks:

- `BackCounterDeckFiller` spans global `z=185.4..194.2`, closing fixture backs to the back-wall interior face at about `z=194`.
- `BackCounterBacksplash` spans global `z=192.85..193.95` and `y=22.2..34.2`, reading as a vertical backsplash below the window band.
- `RightCounterDeckFiller` spans global `x=140.7..144.1`, closing the right cabinet/corner run to the right-wall interior face at about `x=143.8`.
- `RightCounterBacksplash` spans global `x=142.25..143.35` and `y=22.2..34.2`, reading as a right-wall side backsplash instead of an exposed slot.

## Door Frame Wall Fit Correction

The fifth review showed the interior doorway wall pieces still read as overlapping chunks around the doorway frame. The root issue was treating the doorway top fill as a broad slab instead of fitting the wall plane to the doorway prefab frame.

| Node | Old transform value | New transform value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/RoomShell/RightWall4` | `origin=(-37.06749, 47.905, 65.11378)`, `scale=(2, 12, 35.36012)` | Removed | Removed | Eliminate the redundant wall slab that crossed the doorway top and protruded around the frame. |
| `Track/RoomShell/DoorwayOpenHeader` | `origin=(-36.25, 46.85, 65.75)`, `scale=(6, 14.1, 25.5)` | `origin=(-37.65, 47.1875, 65.925)`, `scale=(3.2, 13.425, 24.85)` | `origin=(-1.4, +0.3375, +0.175)`, `scale=(-2.8, -0.675, -0.65)` | Fit the lintel to the wall plane and prefab top instead of filling the full doorway-frame depth. |

Measured door-fit checks:

- `doorwayOpen` frame bounds are `x=-76.191..-67.281`, `y=-20..80.953`, `z=108.209..156.809`.
- `DoorwayOpenHeader` now spans `x=-78.5..-72.1`, `y=80.95..107.8`, `z=107..156.7`, matching the wall plane thickness, starting at the prefab top, and overlapping the side wall runs without protruding through the visible frame depth.
- `RightWall2.max_z=107.684` and `RightWall3.min_z=154.826`, so the header overlaps both side wall runs while preserving the doorway opening.

The capture harness now includes `door_frame_wall_fit`, a direct view of wall-to-frame fit around the interior doorway.

## Upper Cabinet Orientation Correction

The sixth review showed the back-wall upper cabinets facing the wall instead of the playable room side. The imported `kitchenCabinetUpper` asset has its door/front on local `+Z`; the back-wall cabinets reused an unflipped transform, which put that front face into the back wall. This correction flips only the back-wall upper cabinet local `Z` axis and shifts the origins so the cabinets keep the same wall-plane footprint while their doors face the room.

| Node | Old transform value | New transform value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/UpperCabinets/BackUpperCabinetLeftB` | `basis.z=(0, 0, 50)`, `origin.z=97.81024` | `basis.z=(0, 0, -50)`, `origin.z=87.81024` | Flipped local `Z`, `origin.z -10` | Turn the cabinet door/front toward the room while preserving the back-wall footprint. |
| `Track/UpperCabinets/BackUpperCabinetLeftC` | `basis.z=(0, 0, 50)`, `origin.z=97.81024` | `basis.z=(0, 0, -50)`, `origin.z=87.81024` | Flipped local `Z`, `origin.z -10` | Turn the cabinet door/front toward the room while preserving the back-wall footprint. |

Measured orientation checks:

- The raw upper-cabinet asset front/door is on local `+Z`.
- Both corrected cabinets keep the same world AABB as before: `z=174.62..196.62`, so the wall footprint is preserved.
- With local `+Z` now mapped toward room-side `-Z`, the front/door face is visible from the route and cabinet-run cameras instead of being pressed into the back wall.

The capture harness now includes `back_upper_cabinet_faces`, a direct back-wall upper-cabinet orientation view.

## Front Door Frame Depth Correction

The seventh review showed the front wall still did not align cleanly with the closed-door prefab frame. The X edges were nearly correct, but the wall only existed as a shallow flat plane while the door prefab extends deeper into the room. This correction treats the closed front door as a full opening assembly: the lintel now spans only the door opening, matches the door-frame depth, and left/right wall returns wrap the jambs.

| Node | Old transform value | New transform value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/RoomShell/DoorHeader` | `origin=(-57.708828, 46.625, -98)`, `scale=(82, 13.55, 2)` | `origin=(-86.55, 47.1875, -95.932)`, `scale=(25.1, 13.425, 5.67)` | Narrowed X span, extended Z depth, shifted to door top/depth | Stop the header from overlapping the right wall run and make the lintel fit the door-frame depth. |
| `Track/RoomShell/FrontDoorWallReturns/FrontDoorLeftJambReturn` | Missing | `origin=(-99.635, 15.2375, -95.932)`, `scale=(2, 50.475, 5.67)` | Added | Wrap the left side of the front door frame from floor to prefab top. |
| `Track/RoomShell/FrontDoorWallReturns/FrontDoorRightJambReturn` | Missing | `origin=(-73.335, 15.2375, -95.932)`, `scale=(2, 50.475, 5.67)` | Added | Wrap the right side of the front door frame from floor to prefab top. |

Measured front-door checks:

- Closed-door prefab bounds are `x=-197.270..-148.670`, `y=-20..80.953`, `z=-197.533..-186.193`.
- `DoorHeader` now spans `x=-198.200..-148.000`, `y=80.950..107.800`, `z=-197.534..-186.194`, matching the door top and depth while slightly overlapping the adjacent wall runs.
- `FrontDoorLeftJambReturn` spans `x=-201.270..-197.270`, `y=-20..80.950`, `z=-197.534..-186.194`.
- `FrontDoorRightJambReturn` spans `x=-148.670..-144.670`, `y=-20..80.950`, `z=-197.534..-186.194`.

The capture harness now includes `front_door_frame_fit`, a direct view of the closed front-door wall returns and lintel.

## Interior Doorway Depth Correction

The eighth review showed the interior doorway frame still protruding past the surrounding wall/header assembly. The wall/header thickness was already correct at `x=-78.5..-72.1`; the doorway prefab depth was the oversized part, spanning `x=-76.191..-67.281`. This correction scales only the doorway prefab depth axis and shifts it so the frame fits inside the existing wall thickness.

| Node | Old transform value | New transform value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/RoomShell/doorwayOpen` | `basis.z=(50, 0, -0.000002)`, `origin=(-33.640514, -10, 78.40431)` | `basis.z=(35.915, 0, -0.00000157)`, `origin=(-36.05, -10, 78.40431)` | Reduced frame depth, `origin.x -2.409486` | Fit the doorway frame inside the wall/header thickness without moving the route, wall, ceiling, or doorway width. |

Measured interior-door checks:

- `doorwayOpen` now spans `x=-78.500..-72.100`, `y=-20..80.953`, `z=108.209..156.809`.
- `DoorwayOpenHeader` spans `x=-78.500..-72.100`, `y=80.950..107.800`, `z=107.000..156.700`.
- `RightWall2` ends at `z=107.684` and `RightWall3` begins at `z=154.826`, so the doorway width remains preserved while the frame no longer protrudes past the wall plane.

The capture harness now includes `interior_door_depth_fit`, a direct view for the doorway-depth-to-wall-thickness relationship.

## Washer Window Water Surface Correction

The ninth review showed that the washer water was technically contained but still read as a square blue decal inside the round door. The root cause was using a separate rectangular `PlaneMesh` effect as the visible water instead of the washer model's own porthole glass surface.

| Node | Old value | New value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/RoomShell/washer/washer(Clone)/washerDoor` surface `1` (`glass`) | Base GLB glass material only | `surface_material_override/1 = Material_washer_water` using `res://assets/shaders/washer_window_water.gdshader` | Added surface override | Render the water through the actual washer window aperture instead of as a freestanding patch. |
| `Track/WaterSurfaces/WasherWater` | Visible `PlaneMesh_water`, `scale=(5.2, 4.8)`, general `Material_toon_water` | Hidden legacy anchor, `scale=(6.3, 5.6)`, washer-window material | Hidden from render | Keep the old authoring path available for tests/inspection while preventing the square patch from drawing. |
| `tools/capture/KitchenVisualDiffCapture.gd` | Broad washer containment view only | Added `washer_water_natural_closeup` | Added camera | Validate water silhouette and texture from a close player/editor view. |

Measured surface checks:

- `washerDoor` surface `1` is the imported washer `glass` surface.
- The runtime washer door surface override resolves to `res://assets/shaders/washer_window_water.gdshader`.
- The separate `WasherWater` node remains present but is `visible=false`, so it cannot create a square water patch in game views.
- The closeup capture `washer_water_window_localuv_washer_water_natural_closeup.png` shows the shader confined to the round porthole with procedural water variation.

## Outer Back-Wall Floor Leak Correction

The tenth review showed a visible exterior leak along the lower back wall below the window. The root cause was that the lower window infill panel preserved the window-bottom height but did not extend down to the room floor/wall-base datum. From low exterior/editor angles, the floor plane was visible under the wall panel.

| Node | Old transform value | New transform value | Delta | Reason |
| --- | --- | --- | --- | --- |
| `Track/RoomShell/BackWallBelowWindow` | `origin=(0, 12, 98)`, `scale=(316.4062, 24, 2)` | `origin=(0, 6.3655, 98)`, `scale=(316.4062, 35.269, 2)` | `origin.y -5.6345`, `scale.y +11.269` | Extend the panel down to the adjacent back-wall base while preserving the existing window-bottom top edge. |
| `tools/capture/KitchenVisualDiffCapture.gd` | No direct exterior floor-leak view | Added `outer_back_wall_floor_leak` | Added camera | Validate the exact low exterior angle that exposed the shell leak. |

Measured closure checks:

- `BackWallBelowWindow` previously spanned global `y=0..48`, leaving the floor/base line visible from outside.
- `BackWallBelowWindow` now spans global `y=-22.538..48`, matching the adjacent `BackWallLeftOfWindow` and `BackWallRightOfWindow` lower datum.
- The authored floor plane is at about global `y=-20.703`, so the wall panel overlaps the floor plane instead of ending above it.
- The UAT load test now asserts the lower window infill overlaps the floor plane and preserves the existing window-bottom height.

## Craft Replay Read

From route and fixture cameras, this pass should make repeat laps feel less like driving through a broken prototype: the doorway no longer exposes a frame gap, the wall/ceiling edges read as intentional enclosure, the washer effect is contained, the stove/hood/fridge area is no longer visibly interpenetrating, and the right counter run has a shared top plane. The Kitchen is still intentionally MVP-chaotic; deeper Sir Clink theming and richer replay hooks remain a later creative pass.
