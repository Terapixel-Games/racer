# Modern Farmhouse 38-526 Video Reference Notes

Source: https://youtu.be/OkgTSwtj9S0

Use: art-direction reference only. Do not use extracted frames as final in-game textures, skyboxes, billboards, or promotional assets.

## Extracted Frame Set

- `frame_01.jpg` through `frame_10.jpg`: sampled from the one-minute video at roughly six-second intervals.
- `contact_sheet.jpg`: 5 by 2 sheet for fast design review.

## Architectural Cues To Carry Into `home_estate_v1`

- The house must read as a composed modern farmhouse from the street, not an extruded floor plan.
- Primary materials: white siding or stucco fields, black window frames, dark gray/black standing-seam roof, white trim, and a stone/planting base at grade.
- Roof hierarchy is the dominant silhouette: main cross-gables, garage gable, porch gable, dormer-like upper windows, clean fascia, and visible roof thickness.
- The garage is a strong side wing with three doors, but it should not overpower the entry. The entry porch remains the focal point.
- Porches need real depth: columns, beam/header, roof overhang, floor/step, shadowed recess, and furniture/planting nearby.
- Windows need black frames and transparent/dark glass panes, grouped by room rather than scattered evenly.
- Gable ends need trim/rake boards and wall infill; no floating black roof sheets, overwide caps, or disconnected slabs.
- Landscape is part of the house read: curved front walk, lawn, trees, foundation planting, patio/pool edge, and rear porch seating.

## Failure Modes Now Prohibited

- Visible `Label3D` room names or plan annotations in the world.
- Broad dark roof planes that read as paper sheets.
- Blank side/rear facades.
- Openings that show void/sky instead of glass, doors, curtains, or interior backing.
- Floor-plan-color room slabs as the dominant visual language.
- Porch columns, garage doors, or windows pasted onto walls without trim, depth, or proportional alignment.

## Next Generator Pass Target

Rebuild the visible shell as layered architectural assemblies:

- `ExteriorShell`: main body, garage wing, porch bodies, siding fields, corner boards, stone/plinth base.
- `Openings`: garage doors, front door, black-framed windows with glass, headers, sills, jamb returns.
- `Roof`: separate gabled roof modules with measured eaves, fascia, rake trim, ridge caps, valleys, and porch roof.
- `Site`: curved walk, driveway, lawn, foundation beds, trees/shrubs, rear patio/pool reference.
- `MainFloor` / `UpperFloor`: interior furnishings remain subordinate to shell realism when viewed from outside.
