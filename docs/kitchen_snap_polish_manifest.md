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
