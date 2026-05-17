# Whole-House Production Iterator

The goal of the `home_yard_v3` loop is a production-ready home stage: a readable house, street, front yard, backyard, interior, furnishings, course layout, and route experience. Meshy is the preferred visible asset source inside that broader production loop; it is not the goal of the loop.

Every iteration should improve one stage domain or one public course toward production readiness. The chosen work must be judged by game-space quality first: layout clarity, route readability, believable home logic, material quality, scale, collision risk, and screenshot readability.

## Production Domains

The iterator must keep all of these domains in scope:

- Stage concept and concept art: whole-house and per-area references must guide the home, yards, street, interior rooms, furnishings, and course identity.
- Site and street context: the street, curb, driveway, sidewalk, mailbox, approach, and neighboring context explain where the home sits.
- Front yard: planting, arrival route, driveway, porch approach, property edges, and landmarks must read clearly.
- Backyard: patio or deck logic, fence or boundary logic, lawn, garden, sandbox, playground, and outdoor landmarks must read as one coherent yard.
- Home exterior shell: walls, roof, doors, windows, trim, gutters, vents, fixtures, and porch or deck transitions must form a believable closed home.
- Transparent openings: windows need transparent or glass-readable materials, not opaque wall patches.
- Home interior layout: room boundaries, circulation, floor transitions, and vertical connections must make the house layout understandable.
- Furnishing and room identity: furniture and fixtures must identify each room at player height without generic box silhouettes.
- Player tracks and areas: route surfaces must stay inside assigned zones, remain above floor or ground, avoid unplanned collisions, and be readable through starts, first turns, and landmarks.
- Course identity: attic, playroom, bedroom, glam closet, outdoor playground, garden, sandbox, and kitchen must each read as distinct playable spaces.
- Technical stability: generation, import, tests, editor recovery, and live camera proof are part of the gate.
- Critical visual review: screenshots must be reviewed like production game art, not accepted just because tests pass.

## Missing-Gate Mitigations

The iterator uses a numeric screenshot rubric before production claims. Each category is scored `0-5`; every category must score at least `4`, and any `0` blocks the gate. Categories include layout clarity, route readability, material quality, scale consistency, room identity, shell closure, yard and street context, furnishing quality, collision risk, transparent-window quality, placeholder leaks, and performance health.

Every production domain needs a manifest entry, validation cameras, route-clearance check when gameplay-adjacent, and screenshot review score. Story-bible concept reference artifacts live under `res://docs/story_bible/concepts/` and block paid asset batches until the relevant references exist.

Meshy batches are scoped to one course or one production domain. Before any paid call, review prompts and present the exact planned assets, target format, estimated credits, poly budgets, validation cameras, and fallback plan. Asset lifecycle states are `planned`, `prompt_approved`, `generated`, `imported`, `optimized`, `placed`, `camera_validated`, `accepted`, `rejected`, and `superseded`.

Replacement provenance is mandatory. Each retired visible asset needs an old path, old origin, replacement path, replacement origin, replacement reason, decision state, and validation result. This prevents old custom, toybox, or early Meshy assets from silently surviving without review.

Route safety is measured, not estimated. Default minimum clearance is `0.75m` lateral and `0.5m` vertical, visual-only collision is disabled or isolated from gameplay, and any prop inside the route corridor must be a named hazard with camera and UAT coverage.

Windows have their own material gate: glass must read as transparent or glass-like, not as an opaque color patch. Close-up cameras must validate frame depth, trim, interior backdrop or curtain when needed, and no visible void/sky leak.

Generated scene drift blocks production. The final `home_yard_v3_map.tscn` must stay generator-driven, and visible scene nodes require generator metadata or manifest coverage. Manual visible scene edits are not accepted as final production work.

Performance is part of production readiness: target `mobile_detail_phase1`, keep the whole stage under the stage triangle budget, prefer texture atlases, cap unique textures, and review Godot import compression before production claims.

Failure handling is explicit. A Meshy asset gets two prompt attempts before changing strategy, one remesh attempt before rejection, then fallback to toybox or a justified Kenney keep-review decision. Rejections must record why: geometry budget, topology, scale, material, silhouette, import, or collision failure.

## Shortcut Deferral

Playable shortcut work is out of scope for this pass. Do not alter route topology for shortcuts, add lap/progress-affecting shortcut gates, or make hidden routes playable. Shortcut concepts from the stage briefs may appear only as off-route dressing, blocked/future gates, or non-playable visual hooks unless the current main route already uses that geometry.

## Asset Source Policy

`home_yard_v3` uses Meshy as the default visible 3D asset source until the current credit budget is exhausted. Toybox is the fallback after Meshy exhaustion or after repeated Meshy failures against the game-ready gate. Kenney assets may remain only when they are licensed, low-poly, visually strong, and clearly fit their stage role.

Paid Meshy calls require explicit approval before each batch. The approval request must list the exact planned assets, target format, estimated credits, area, poly budgets, and fallback plan. Default output is GLB for Godot.

No final visible prop, furnishing, wall dressing, window, door, yard object, street detail, route landmark, or home exterior detail may be a bare Godot primitive. Godot-authored boxes are acceptable only as invisible infrastructure, collision, or temporary generator internals that do not ship as visible assets.

Existing non-Kenney visible assets are replacement candidates by default, including prior Meshy, toybox, optimized, and custom assets. They can remain only after strict production review. Existing Kenney assets can remain after the same review, but do not need automatic Meshy replacement.

Every Meshy asset stores its source package under `res://assets/source/meshy/home_yard_v3/<area>/<asset_slug>/`. Each asset directory must include `<asset_slug>.meshy_prompt.md`, using `res://assets/source/meshy/home_yard_v3/_prompt_record_template.md` as the template.

## Production Order

1. Production domain inventory and replacement triage.
2. Concept reference boards for street and front yard, home exterior, interior rooms, furnishings, backyard, and every course.
3. Street and front yard production pass.
4. Home exterior production pass, including transparent windows and believable trim.
5. Interior layout and furnishing production pass.
6. Backyard production pass.
7. Course identity passes: attic, playroom, bedroom, glam closet, outdoor playground, garden, sandbox, then kitchen polish.
8. Full-house gate.

## Import-Stable Validation

Use the stable Godot sequence for generated assets and regenerated scenes:

1. Switch to a neutral scene when the target generated scene is open, or expect reload recovery.
2. Generate or stage assets.
3. Run `godot_console.exe --headless --path <project> --import`.
4. Recover safe editor dialogs only: `Reload from disk` for external file changes and `OK` for load errors.
5. Wait for `editor_state.readiness == ready`.
6. Run focused tests.
7. Run live camera validation and prove the intended `camera_path`.
8. Inspect screenshots as a critical game designer before claiming production readiness.

## Screenshot Review Gate

Every production claim needs screenshot review for layout clarity, home realism, front yard readability, backyard readability, street context, exterior closure, interior room identity, furnishing quality, route readability, transparent windows, scale consistency, collision risk, visual confusion, and placeholder leaks.

## Commit Rule

Commit only a scoped verified pass. If unrelated dirty work prevents a clean commit, stop with a staging report instead of mixing unrelated changes.
