# Racer Runtime Asset Gap Table

Date: 2026-04-27

Purpose: convert the sourced asset inventory into an implementation checklist for runtime-ready Godot content. This document does not import assets by itself; it defines what can be curated now, what must be authored in Godot, and what still needs sourcing or Meshy fallback.

## Status Definitions

| Status | Meaning |
| --- | --- |
| Ready to curate | Source asset exists and should be turned into runtime scenes/materials next |
| Needs review | Source asset exists, but scale, materials, geometry, or import health must be checked before use |
| Godot-authored | Build with Godot primitives, shaders, particles, or simple scene composition |
| Online CC0 search | Look outside the repo only if local/Meshy coverage is weak |
| Meshy fallback | Generate only if Kenney, Godot-authored, or CC0 options do not carry the identity |
| Outstanding | Asset is planned but not yet sourced |

## Recommended Vertical Slice

Start with Kitchen / Sir Clink for the first runtime slice.

Reasons:

- Strong local Kenney coverage exists for kitchen furniture, food hazards, and utensils.
- Sir Clink has a clear visual identity and a Meshy racer/kart source.
- Kitchen audio identity is already sourced: clatter, sink splash, utensil clink, and kitchen music.
- The track can validate item boxes, hazards, checkpoints, and room-scale dressing without needing the hardest custom props first.

Vertical-slice minimum:

| Piece | Target |
| --- | --- |
| Racer | `assets/gameplay/racers/sir_clink/sir_clink.tscn` |
| Kart | `assets/gameplay/karts/sir_clink_kart/sir_clink_kart.tscn` |
| Track | `assets/gameplay/tracks/kitchen/kitchen_track.tscn` |
| Shared modules | `assets/gameplay/tracks/modules` |
| Items | `assets/gameplay/items/{item_box,boost,marble,jacks,bubble_shield,invincibility,signature_token}` |
| Audio | Curated runtime copies under `assets/audio` from `assets/source/audio` |

## Ready To Import From Kenney

These have local source coverage and should be curated into runtime scenes before searching online.

| Asset need | Source family | Source status | Runtime target | Next action |
| --- | --- | --- | --- | --- |
| Modular road and toy track pieces | Kenney Toy Car Kit | Sourced | `assets/gameplay/tracks/modules` | Build reusable track module scenes with consistent scale, snap points, and collision |
| Finish and start gates | Kenney Toy Car Kit | Sourced | `assets/gameplay/tracks/shared/gates` | Create start/finish scenes and marker sockets |
| Item box | Kenney Toy Car Kit | Sourced | `assets/gameplay/items/item_box` | Create pickup scene with idle animation, collision, and material pass |
| Cones and lightweight hazards | Kenney Toy Car Kit | Sourced | `assets/gameplay/tracks/shared/hazards` | Create static and bumpable variants |
| Smoke puff visual prop | Kenney Toy Car Kit | Sourced | `assets/gameplay/fx/smoke` | Decide mesh prop versus particle replacement |
| Race barriers, flags, pylons, signage | Kenney Racing Kit | Sourced | `assets/gameplay/tracks/shared/race_dressing` | Create dressing prefabs and collision-free decoration variants |
| Bedroom beds, rugs, books, lamps | Kenney Furniture Kit | Sourced | `assets/gameplay/tracks/bedroom/props` | Curate bedroom prop scenes and test toy scale |
| Kitchen tables, chairs, sink, cabinets | Kenney Furniture Kit | Sourced | `assets/gameplay/tracks/kitchen/props` | Build kitchen landmark and collision helper scenes |
| Kitchen fruit, cups, bowls, cookies | Kenney Food Kit | Sourced | `assets/gameplay/tracks/kitchen/hazards` | Create rolling/static hazard variants |
| Kitchen utensils and cutting board | Kenney Food Kit | Sourced | `assets/gameplay/tracks/kitchen/hazards` | Create clink hazards and shortcut dressing |
| Garden stones, path rocks, bridge pieces | Kenney Nature Kit | Sourced | `assets/gameplay/tracks/garden/props` | Build stones, path edges, and shortcut markers |
| Garden bushes, grass, flowers, logs | Kenney Nature Kit | Sourced | `assets/gameplay/tracks/garden/dressing` | Build collision-free dressing plus log obstacle variants |
| Playground ramps, rails, half-pipe, platforms | Kenney Mini Skate | Sourced | `assets/gameplay/tracks/playground/modules` | Convert stunt parts into track ramps and rails |
| Marble projectile | Kenney Marble Kit | Sourced | `assets/gameplay/items/marble` | Create projectile scene with material variants |
| Marble track hazards | Kenney Marble Kit | Sourced | `assets/gameplay/tracks/shared_toys/marble_hazards` | Use for Playroom and Attic toy-machine hazards |
| UI, powerup, impact, foley placeholders | Kenney audio | Sourced | `assets/audio/placeholders` | Keep as fallback library, not final identity audio |

## Ready To Curate From Meshy

These source GLBs exist but should not be treated as final runtime assets until inspected in Godot.

| Asset need | Source status | Runtime target | Review criteria | Next action |
| --- | --- | --- | --- | --- |
| 8 standalone racers | Sourced Meshy GLBs | `assets/gameplay/racers/<racer>` | silhouette, scale, material readability, riggability, polygon count | Open each in Godot, choose vertical-slice candidate first |
| 8 racers in karts | Sourced Meshy GLBs | `assets/gameplay/karts/<racer>_kart` | import health, kart silhouette, wheel placement, origin, collision volume | Prioritize Sir Clink, then the first 4 launch racers |
| 8 landmark sets | Sourced Meshy GLBs | `assets/gameplay/tracks/<track>/landmarks` | splitability, collision suitability, material consistency, scale | Use as visual anchors; author gameplay route separately |
| Racer material textures | Partially sourced where Meshy provided sidecar textures | `assets/gameplay/racers/<racer>/materials` | texture assignment, resolution, color consistency | Normalize naming and clamp resolution if needed |
| Kart material textures | Partially sourced through GLB/material sidecars | `assets/gameplay/karts/<racer>_kart/materials` | toy plastic readability, class color identity | Create shared kart material palette |

Known risk:

| Asset | Risk | Action |
| --- | --- | --- |
| `dash/racer_in_kart.glb` | User reported it would not open in Godot | Re-test import, inspect GLB validity, regenerate or repair before runtime use |
| `tuggs/racer_in_kart.glb.import` and `velva/racer_in_kart.glb.import` | Existing dirty sidecars in workspace | Treat as user/editor-generated until intentionally reviewed |

## Godot-Authored Assets

These should be built directly in Godot instead of sourced externally.

| Asset need | Runtime target | Build approach | Notes |
| --- | --- | --- | --- |
| Bubble shield | `assets/gameplay/items/bubble_shield` | Sphere mesh, transparent shader, impact pop animation | No external mesh needed |
| Invincibility star pickup | `assets/gameplay/items/invincibility` | Simple star mesh or low-poly primitive scene with glow shader | Meshy only if the simple version lacks toy identity |
| Signature token | `assets/gameplay/items/signature_token` | Coin/token mesh, character color material, icon decal later | Figma can guide icon language |
| Boost pad / boost trail | `assets/gameplay/items/boost` and `assets/gameplay/fx/boost` | Kenney pad base plus shader, particles, and smoke | Runtime feedback matters more than source mesh |
| Perfume mist hazard | `assets/gameplay/fx/perfume_mist` | Particles, translucent cone/volume, glam material | Use in Glam Closet track |
| Track route, checkpoints, lap triggers | `assets/gameplay/tracks/<track>/race_logic` | Godot-authored markers, areas, and collision | Do not inherit competitive logic from generated visual meshes |
| Collision helper meshes | `assets/gameplay/tracks/<track>/collision` | Simple invisible boxes/ramps/walls | Keep separate from decorative source meshes |
| Runtime audio buses and volume presets | `assets/audio` plus project settings | Godot bus routing and curated stream scenes | Source files are imported; runtime usage still needs wiring |

## Online CC0 Search Backlog

Search only after local source review proves a concrete gap.

| Gap | First source | Runtime target | Search trigger |
| --- | --- | --- | --- |
| Carpet, blanket, plush fabric | Generated texture approved | `assets/gameplay/materials/fabric/plush_fabric_albedo.png` | Use generated texture first; search ambientCG only if it fails in-scene |
| Kitchen tile | Generated texture approved | `assets/gameplay/materials/tile/kitchen_tile_albedo.png` | Use generated texture first; search CC0 only if it fails in-scene |
| Wood floor / table surface | Generated attic cardboard/wood texture approved | `assets/gameplay/materials/attic/attic_cardboard_wood_albedo.png` | Reuse for attic first; search CC0 if a cleaner wood floor is needed |
| Sand material | Generated texture approved | `assets/gameplay/materials/sand/sandbox_sand_albedo.png` | Use generated texture first; search ambientCG only if it fails in-scene |
| Dirt, mud, leaf ground | Generated texture approved | `assets/gameplay/materials/garden/garden_dirt_mud_albedo.png` | Use generated texture first; search ambientCG only if it fails in-scene |
| Cardboard and dusty cloth | Generated texture approved | `assets/gameplay/materials/attic/attic_cardboard_wood_albedo.png` | Use generated texture first; search CC0 only if it fails in-scene |
| Low-poly shovel, bucket, bones | Quaternius | `assets/gameplay/tracks/sandbox/props` | Meshy sandbox landmark does not split cleanly |
| Low-poly trunk, crates, storage boxes | Quaternius | `assets/gameplay/tracks/attic/props` | Kenney furniture/Meshy attic landmarks are insufficient |
| Playground slide/swing/seesaw fallback | Quaternius or Poly Haven CC0 models | `assets/gameplay/tracks/playground/props` | Meshy landmark set is not usable as separate pieces |

## Meshy Fallback List

Use Meshy only for these if local or simple authored options do not carry the toy identity.

| Asset need | Why Meshy may be justified | First non-Meshy attempt |
| --- | --- | --- |
| Jacks trap | Needs instantly readable toy trap silhouette | Simple low-poly crossed jack shape in Godot |
| Character-specific signature props | Needs racer-specific identity | Token material/icon plus existing racer silhouette |
| Sandbox fossil/bone set | Strong Rexx identity if Kenney/Quaternius is weak | Nature rocks plus simple bone mesh |
| Glam vanity arch / shoe hazard | Velva track needs glam identity | Furniture mirror/table/rug composition |
| Attic prank trunk / sheet obstacle | Popper track needs spooky prank identity | Furniture boxes/cabinets plus cloth material |
| Playground swing gate / seesaw | Dash track needs stunt playground identity | Mini Skate ramps and rails |
| Garden hose/root hero hazard | Moko track needs jungle obstacle identity | Nature logs, paths, bushes |

## UI And Presentation Assets

| Asset need | Source approach | Runtime target | Status |
| --- | --- | --- | --- |
| Racer portraits | Approved generated character headshots | `assets/ui/racers/headshots` | Covered for first character-select pass |
| Kart thumbnails | Render from curated kart scenes | `assets/ui/karts/thumbnails` | Not started |
| Track thumbnails | Render from vertical-slice track scenes | `assets/ui/tracks/thumbnails` | Not started |
| Item icons | Figma direction, then Godot/UI vector or PNG exports | `assets/ui/items/icons` | Not started |
| Class icons | Simple UI symbols for Light, Medium, Bruiser, Light Heavy, Heavy | `assets/ui/racers/classes` | Not started |
| Logo/title treatment | Figma or in-engine title composition | `assets/ui/branding` | Not started |

## Texture And Material Pass

Use toy-readable materials first. Do not overfit to photoreal PBR until scale and gameplay readability are stable.

| Material family | Use | Source plan | Runtime target |
| --- | --- | --- | --- |
| Glossy plastic | Karts, item boxes, track toys | Approved generated albedo plus Godot shader parameters | `assets/gameplay/materials/plastic/glossy_plastic_albedo.png` |
| Plush/fabric | Tuggs, bedroom, teddy clutter | Approved generated albedo | `assets/gameplay/materials/fabric/plush_fabric_albedo.png` |
| Molded metal | Sir Clink, utensils, rails | Approved generated albedo plus Godot metal/roughness settings | `assets/gameplay/materials/metal/toy_metal_albedo.png` |
| Sand | Sandbox floor, berms, bucket areas | Approved generated albedo | `assets/gameplay/materials/sand/sandbox_sand_albedo.png` |
| Tile | Kitchen floor and sink zone | Approved generated albedo | `assets/gameplay/materials/tile/kitchen_tile_albedo.png` |
| Dirt/mud/leaf | Garden route and hazards | Approved generated albedo | `assets/gameplay/materials/garden/garden_dirt_mud_albedo.png` |
| Cardboard/dusty wood | Attic boxes and floor | Approved generated albedo | `assets/gameplay/materials/attic/attic_cardboard_wood_albedo.png` |
| Mirror/glitter/gloss | Glam Closet | Approved generated albedo plus Godot gloss shader parameters | `assets/gameplay/materials/glam/glam_mirror_glitter_albedo.png` |

## Runtime Integration Order

1. Validate one Meshy racer/kart import: Sir Clink.
2. Curate the Kitchen track base using Kenney furniture, food, utensils, toy track modules, and authored race logic.
3. Build shared item scenes: item box, boost, marble, bubble shield, jacks placeholder, invincibility star, signature token.
4. Wire curated audio for menu, race start, item feedback, and Kitchen track identity.
5. Add one more racer from a different weight class to test scale and class readability.
6. Expand to the first four launch tracks.
7. Fill CC0 texture gaps only where procedural/simple materials are not enough.
8. Use Meshy fallback only for identity gaps that remain visible after the Kenney/Godot pass.

## Verification Gates

| Gate | Requirement |
| --- | --- |
| Source license | Every imported third-party asset must have a source manifest row before runtime use |
| Godot import | Each curated GLB/GLTF opens in Godot with usable materials, scale, and orientation |
| Collision | Gameplay collision is authored or verified separately from visual mesh geometry |
| Audio | Runtime streams play on intended buses with no clipping and sensible category volume |
| Performance | Hero assets should be inspected for polygon count and texture size before broad use |
| Commit | Commit only after the table or curated import pass is verified; leave unrelated dirty files alone |
