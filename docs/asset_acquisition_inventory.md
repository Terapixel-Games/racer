# Racer Asset Acquisition Inventory

Date: 2026-04-27

Goal: plan the remaining asset library before copying/importing runtime files. This is an inventory and sourcing contract, not an import pass.

Policy: CC0-first. Prefer local Kenney assets, then CC0 online sources, then Meshy/Suno/SFXR/Figma for custom work. Do not use an external asset in-game unless this file or a successor manifest records the source, license, and Godot target.

## Source Priority

| Priority | Source | License posture | Use |
| --- | --- | --- | --- |
| 1 | `C:\code\Kenney Game Assets All-in-1 3.3.0` | Local Kenney packs inspected as CC0 where used; keep per-pack `License.txt` references | Common meshes, UI, audio, track modules, props |
| 2 | ambientCG | CC0 per official license page | Carpet, tile, wood, plastic, fabric, dirt, stone, sand PBR textures |
| 3 | Poly Haven | CC0 per official license page | HDRIs, fallback PBR textures, occasional models |
| 4 | Quaternius | FAQ states models are CC0 and attribution is not required | Low-poly fallback props if Kenney lacks a clear match |
| 5 | OpenGameArt | Asset-level license required; use CC0 only unless explicitly approved | Last-resort free art/audio searches |
| 6 | Meshy | Generated project assets | Unique racer, kart, hero landmarks, signature props, jacks/star if needed |
| 7 | Suno / SFXR / Figma | Generated or authored project assets | Music, bespoke arcade SFX, design/palette concepts |

## Import Conventions

| Asset class | Source target | Curated runtime target |
| --- | --- | --- |
| Untouched Kenney files | `assets/source/kenney/<pack>/<asset>` | `assets/gameplay/<category>/<asset>` |
| Meshy downloads | `assets/source/meshy/<batch>/<task-id>` | `assets/gameplay/racers`, `assets/gameplay/karts`, `assets/gameplay/tracks` |
| Online CC0 files | `assets/source/external/<provider>/<asset>` | `assets/gameplay/<category>/<asset>` |
| Suno music | `assets/source/audio/suno/<track>` | `assets/audio/music/<track>` |
| SFXR sounds | `assets/source/audio/sfxr/<sound>` | `assets/audio/sfx/<sound>` |
| Figma exports | `assets/source/figma/<board>` | `assets/ui` or concept docs only |

Keep Godot-authored collision separate from visual meshes. Track routes, checkpoints, and competitive collision should be authored/validated in Godot rather than inherited directly from generated or vendor meshes.

## Mesh Inventory

| Need | Preferred source | License | Candidate path or URL | Owner | Status | Replacement risk | Godot target |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Modular toy road/track pieces | Kenney Toy Car Kit | CC0 | `3D assets\Toy Car Kit\Models\GLB format\track-*.glb` | All tracks | Candidate | Low | `assets/gameplay/tracks/modules` |
| Finish/start gates | Kenney Toy Car Kit | CC0 | `gate-finish.glb`, `gate.glb` | All tracks | Candidate | Low | `assets/gameplay/tracks/shared` |
| Item box | Kenney Toy Car Kit | CC0 | `item-box.glb` | Items | Candidate | Low | `assets/gameplay/items/item_box` |
| Cone / lightweight obstacle | Kenney Toy Car Kit | CC0 | `item-cone.glb` | Shared hazards | Candidate | Low | `assets/gameplay/tracks/shared` |
| Smoke puff prop | Kenney Toy Car Kit | CC0 | `smoke.glb` | Boost, impacts | Candidate | Medium; may become particle material | `assets/gameplay/fx` |
| Track supports | Kenney Toy Car Kit | CC0 | `supports*.glb` | Elevated track sections | Candidate | Low | `assets/gameplay/tracks/modules` |
| Race flags / barriers / signage | Kenney Racing Kit | CC0 verified locally | `3D assets\Racing Kit\Models\GLTF format\*` | All tracks | Candidate | Low | `assets/gameplay/tracks/shared` |
| Bedroom bed landmarks | Kenney Furniture Kit | CC0 verified locally | `bedSingle.glb`, `bedDouble.glb`, `bedBunk.glb` | Bedroom / Tuggs | Candidate | Low | `assets/gameplay/tracks/bedroom` |
| Bedroom clutter | Kenney Furniture Kit | CC0 verified locally | `books.glb`, `lampRoundTable.glb`, `rug*.glb`, `cabinetBed*.glb` | Bedroom / Tuggs | Candidate | Low | `assets/gameplay/tracks/bedroom` |
| Teddy placeholder / toy clutter | Kenney Furniture Kit | CC0 verified locally | `bear.glb` | Bedroom, Playroom | Candidate | Medium; style may need repaint | `assets/gameplay/tracks/shared_toys` |
| Kitchen furniture | Kenney Furniture Kit | CC0 verified locally | `table.glb`, `chair.glb`, `kitchenSink.glb`, `kitchenCabinet*.glb` | Kitchen / Sir Clink | Candidate | Low | `assets/gameplay/tracks/kitchen` |
| Kitchen food hazards | Kenney Food Kit | CC0 verified locally | `apple.glb`, `banana.glb`, `cup.glb`, `bowl.glb`, `cookie.glb` | Kitchen / Sir Clink | Candidate | Low | `assets/gameplay/tracks/kitchen` |
| Kitchen utensils | Kenney Food Kit | CC0 verified locally | `cooking-knife.glb`, `cooking-spoon.glb`, `cooking-fork.glb`, `cutting-board.glb` | Kitchen / Sir Clink | Candidate | Low | `assets/gameplay/tracks/kitchen` |
| Garden stones / paths | Kenney Nature Kit | CC0 verified locally | `path_stone*.glb`, `ground_pathRocks.glb`, `bridge_stone*.glb` | Garden / Moko | Candidate | Low | `assets/gameplay/tracks/garden` |
| Garden plants | Kenney Nature Kit | CC0 verified locally | `plant_bush*.glb`, `grass*.glb`, `flower_*.glb` | Garden / Moko | Candidate | Low | `assets/gameplay/tracks/garden` |
| Garden roots/logs | Kenney Nature Kit | CC0 verified locally | `log*.glb` | Garden / Moko | Candidate | Medium; custom roots may need Meshy | `assets/gameplay/tracks/garden` |
| Playground ramps / rails | Kenney Mini Skate | CC0 verified locally | `half-pipe.glb`, `rail-*.glb`, `steps.glb`, `pallet.glb`, `structure-platform.glb` | Outdoor Playground / Dash | Candidate | Low | `assets/gameplay/tracks/playground` |
| Marble projectile | Kenney Marble Kit | CC0 verified locally | `marble-low.glb`, `marble-high.glb` | Items | Candidate | Low | `assets/gameplay/items/marble` |
| Marble track hazards | Kenney Marble Kit | CC0 verified locally | `ramp-*.glb`, `funnel.glb`, `curve*.glb`, `bump*.glb` | Playroom, Attic, shared hazards | Candidate | Medium | `assets/gameplay/tracks/shared_toys` |
| Sandbox bucket tunnel | Meshy batch / fallback Meshy | Generated | task `019dcfef-477b-7bee-8042-24eb7b5b58cf` | Sandbox / Rexx | Generated, not downloaded | Low | `assets/gameplay/tracks/sandbox` |
| Sandbox shovel/fossils/bones | Meshy or Quaternius fallback | Generated or CC0 | TBD after import review | Sandbox / Rexx | Gap | Medium | `assets/gameplay/tracks/sandbox` |
| Playroom ring platform | Meshy batch + Kenney Toy Car/Furniture | Generated + CC0 | task `019dcffa-82bd-7014-905c-7667fe01d2da` | Playroom / Slammo | Generated, not downloaded | Low | `assets/gameplay/tracks/playroom` |
| Glam vanity / mirror arch | Meshy batch + Kenney Furniture | Generated + CC0 | task `019dcffc-bab8-72b9-af76-e1bef3943690`, `bathroomMirror.glb`, `table*.glb` | Glam Closet / Velva | Generated, not downloaded | Low | `assets/gameplay/tracks/glam_closet` |
| Perfume mist hazard | Godot particles + simple mesh | Project-authored | no vendor mesh needed | Glam Closet / Velva | Gap | Low | `assets/gameplay/fx/perfume_mist` |
| Attic trunk maze / boxes | Meshy batch + Kenney/Quaternius fallback | Generated + CC0 | task `019dcff5-f843-7eef-8776-86cb15555d76` | Attic / Popper | Generated, not downloaded | Medium | `assets/gameplay/tracks/attic` |
| Playground slide/swing/seesaw | Meshy batch + Mini Skate fallback | Generated + CC0 | task `019dcfff-2860-74bf-9686-72319f5d21b4` | Outdoor Playground / Dash | Generated, not downloaded | Low | `assets/gameplay/tracks/playground` |
| Boost pickup/pad | Kenney Toy Car Kit + shader | CC0 + project-authored | `track-*-bump*.glb`, `smoke.glb`, custom material | Items | Candidate | Low | `assets/gameplay/items/boost` |
| Invincibility star | Simple Godot mesh first; Meshy if weak | Project-authored or generated | TBD | Items | Gap | Low | `assets/gameplay/items/invincibility` |
| Signature token | Figma icon + simple mesh | Project-authored | TBD | Items | Gap | Medium | `assets/gameplay/items/signature_token` |
| Jacks trap | Meshy or custom low-poly | Generated or project-authored | TBD | Items | Gap | Medium | `assets/gameplay/items/jacks` |
| Bubble shield | Godot sphere + transparent shader | Project-authored | no vendor mesh needed | Items | Planned | Low | `assets/gameplay/items/bubble_shield` |

## Racer and Kart Source Assets

The active Meshy-6 batch succeeded for all eight racers, racer-in-kart models, and landmark sets. Download format should be GLB when the asset import pass begins.

| Racer | Standalone task | Racer-in-kart task | Landmark task |
| --- | --- | --- | --- |
| Rexx | `019dcfed-9fb2-7b57-b2ef-ecdc344117a5` | `019dcfec-dee7-7d31-9031-096bb2b53d61` | `019dcfef-477b-7bee-8042-24eb7b5b58cf` |
| Moko | `019dcff0-014c-7e85-86e7-172d40c4a9ad` | `019dcff0-e320-7267-9bda-6798344acc6f` | `019dcff1-cd45-7f52-b8dc-47bd432ccdc0` |
| Tuggs | `019dcff2-7f24-72a7-b2bf-809086a7a55e` | `019dcff3-2fcd-7ded-8439-c969dd9021fd` | `019dcff3-ee06-7e61-ab17-b345f812f4e6` |
| Popper | `019dcff4-ad87-7e19-854e-d22c8dd185ec` | `019dcff5-4603-7e64-934a-59b85d91ca71` | `019dcff5-f843-7eef-8776-86cb15555d76` |
| Sir Clink | `019dcff6-b7e4-73a2-b1f6-0174424d1bc8` | `019dcff7-8355-73cc-82d7-2461c48d4d84` | `019dcff8-3f63-7fa3-bf23-edee117e7839` |
| Slammo | `019dcff8-fa3c-7027-b949-bdf09995ee52` | `019dcff9-abd9-7432-828c-beb153c1f35a` | `019dcffa-82bd-7014-905c-7667fe01d2da` |
| Velva | `019dcffb-2ac7-70f0-9b45-6ca3b1034efe` | `019dcffc-02f1-70ba-b0bf-04bf1463c864` | `019dcffc-bab8-72b9-af76-e1bef3943690` |
| Dash | `019dcffd-585e-712d-b014-6d5475e96fdf` | `019dcffe-6a43-71bb-93c0-99dac83f5907` | `019dcfff-2860-74bf-9686-72319f5d21b4` |

## Track Asset Plan

| Track | Kenney base | Custom/Meshy identity | Texture targets | Audio identity |
| --- | --- | --- | --- | --- |
| Bedroom / Tuggs | Furniture Kit beds, rugs, books, lamps; Toy Car track modules | Meshy bedroom landmark set for toy chest / blanket route anchors | carpet, fabric, warm plastic, painted wood | muffled room tone, plush bumps, blanket slides |
| Playroom / Slammo | Toy Car Kit, Marble Kit, Furniture bear/books, Racing banners | Meshy playroom/ring set | foam mat, plastic blocks, toy vinyl | crowd toy chants, spring ramps, plastic block impacts |
| Glam Closet / Velva | Furniture mirrors/tables/rugs/shelves | Meshy glam vanity/closet set, project-authored perfume mist | glossy plastic, mirror shine, fabric, glitter accents | sparkle UI, soft whooshes, perfume puff |
| Garden / Moko | Nature Kit stones, bushes, flowers, logs, path rocks | Meshy garden hose/root set for hero hazards | dirt, mud, leaf, stone, water | birds/wind, mud slide, water splash, branch hits |
| Sandbox / Rexx | Toy Car track, Nature rocks/ground, possible Quaternius shovel/bucket fallback | Meshy sandbox bucket/fossil set | sand, plastic bucket, fossil stone | gritty slide, plastic scoop hits, dino stomp stinger |
| Outdoor Playground / Dash | Mini Skate ramps/rails/steps, Toy Car track | Meshy slide/swing/seesaw set | blacktop, bright molded plastic, chalk | outdoor air, chain swing, slide drop, stunt whoosh |
| Attic / Popper | Furniture boxes/cabinets/books, Marble hazards | Meshy attic trunk/box maze | dusty wood, cardboard, cloth sheet | creaks, box falls, prank squeaks, spooky toy sting |
| Kitchen / Sir Clink | Furniture table/chairs/sink/cabinets, Food Kit utensils/fruit | Meshy kitchen landmark set for toaster/sink gauntlet | tile, metal, plastic, fruit skin | utensil clinks, sink splash, plate impacts, heroic sting |

## Audio Inventory

| Need | Preferred source | Candidate path or generator | Owner | Status | Replacement risk | Godot target |
| --- | --- | --- | --- | --- | --- | --- |
| UI select/cursor | Kenney Interface Sounds / UI Audio | `Audio\Interface Sounds`, `Audio\UI Audio` | UI | Candidate | Low | `assets/audio/ui` |
| UI confirm/back | Kenney Interface Sounds / UI Audio | `Audio\Interface Sounds`, `Audio\UI Audio` | UI | Candidate | Low | `assets/audio/ui` |
| Lobby ready/countdown | Kenney Digital Audio + SFXR | `Audio\Digital Audio\Audio\powerUp*.ogg`, SFXR beep variants | UI/race flow | Candidate | Medium | `assets/audio/ui` |
| Result reveal/win/lose | Kenney Music Jingles + Suno stingers | `Audio\Music Jingles`, Suno generated stingers | Results | Candidate | Medium | `assets/audio/music/stingers` |
| Pickup/item roulette | Kenney Digital Audio | `powerUp*.ogg`, `phaseJump*.ogg` | Items | Candidate | Low | `assets/audio/items` |
| Boost start/accent | Kenney Digital Audio + SFXR | `powerUp*.ogg`, custom SFXR burst | Items | Candidate | Medium | `assets/audio/items/boost` |
| Invincibility start/end | Suno/SFXR + Kenney Digital Audio | custom bright loop/stinger; `powerUp*.ogg` placeholder | Items | Gap | Medium | `assets/audio/items/invincibility` |
| Signature charge/activate | SFXR + per-racer Suno micro-stingers | custom generated | Items/racers | Gap | High | `assets/audio/items/signature` |
| Marble fire/hit | Kenney Foley Rocks + SFXR | `Audio\Foley Sounds\Audio\Rocks\*.ogg` | Marble item | Candidate | Low | `assets/audio/items/marble` |
| Jacks deploy/hit | Kenney Impact Metal + SFXR | `Audio\Impact Sounds\Audio\impactMetal_*.ogg` | Jacks item | Candidate | Medium | `assets/audio/items/jacks` |
| Bubble shield pop | Kenney Impact Glass + SFXR | `Audio\Impact Sounds\Audio\impactGlass_*.ogg` | Bubble item | Candidate | Low | `assets/audio/items/bubble` |
| Kart bump/wall hit | Kenney Impact Generic/Plastic/Metal | `Audio\Impact Sounds\Audio\impactGeneric_*.ogg`, `impactMetal_*.ogg` | Driving | Candidate | Low | `assets/audio/driving` |
| Drift slide/whoosh | Kenney Foley Woosh + SFXR | `Audio\Foley Sounds\Audio\Woosh\woosh*.ogg` | Driving | Candidate | Low | `assets/audio/driving` |
| Kitchen impacts | Kenney Foley Plating/Swords | `platesHit*.ogg`, `hitHelmet*.ogg`, `swordSlide*.ogg` | Kitchen / Sir Clink | Candidate | Low | `assets/audio/tracks/kitchen` |
| Garden impacts | Kenney Foley Rocks/Water | `stoneHit*.ogg`, water clips if selected | Garden / Moko | Candidate | Medium | `assets/audio/tracks/garden` |
| Attic creaks/pranks | Kenney Foley + SFXR | woosh/wood impacts + custom squeaks | Attic / Popper | Gap | Medium | `assets/audio/tracks/attic` |
| Bedroom plush impacts | Kenney Impact Generic + SFXR | light generic impacts + soft custom thumps | Bedroom / Tuggs | Gap | Medium | `assets/audio/tracks/bedroom` |
| Main menu music | Suno | prompt below | Global | Gap | High | `assets/audio/music/menu` |
| Race base loop | Suno | prompt below | Global | Gap | High | `assets/audio/music/race` |
| Eight track loops | Suno | prompts below | Tracks | Gap | High | `assets/audio/music/tracks` |

## Suno Prompt Set

Use instrumental music only. Avoid direct references to copyrighted games or melodies.

| Cue | Prompt |
| --- | --- |
| Main menu | `instrumental toy kart racing theme, bright mischievous arcade energy, playful percussion, plastic toy instruments, handclaps, bouncy bass, short loopable hook, family friendly competitive chaos, no vocals` |
| Race base loop | `instrumental fast toy racing loop, upbeat arcade drums, rubbery bass, bright synth brass, playful sabotage energy, loopable 90 seconds, no vocals` |
| Bedroom / Tuggs | `instrumental cozy bedroom toy race loop, plush percussion, music box accents, warm bass, mischievous but soft, loopable, no vocals` |
| Playroom / Slammo | `instrumental toy wrestling arena race loop, chant-like brass stabs without vocals, blocky percussion, triumphant arcade energy, loopable` |
| Glam Closet / Velva | `instrumental glam closet race loop, sparkling synths, runway bass, glossy toy pop energy, competitive and stylish, loopable, no vocals` |
| Garden / Moko | `instrumental backyard jungle toy race loop, marimba, hand drums, leafy percussion, adventurous but playful, loopable, no vocals` |
| Sandbox / Rexx | `instrumental prehistoric sandbox toy race loop, stomping percussion, cartoon fossil adventure, plastic dino attitude, loopable, no vocals` |
| Outdoor Playground / Dash | `instrumental stunt playground race loop, fast breakbeat, bright whistles, skateboard arcade energy, cool and energetic, loopable, no vocals` |
| Attic / Popper | `instrumental spooky attic toy race loop, playful haunted carnival, toy piano, pizzicato strings, prank energy, loopable, no vocals` |
| Kitchen / Sir Clink | `instrumental kitchen knight toy race loop, clanging utensil percussion, heroic brass, playful domestic chaos, loopable, no vocals` |
| Victory stinger | `short instrumental toy racing victory stinger, bright brass, playful percussion, triumphant, 6 seconds, no vocals` |
| Loss stinger | `short instrumental toy racing loss stinger, comic deflated cadence, playful not sad, 5 seconds, no vocals` |
| Results reveal | `short instrumental arcade results reveal stinger, toy percussion roll, shiny final hit, 8 seconds, no vocals` |

## Figma Design Tasks

| Need | Output |
| --- | --- |
| Item icon set | Boost, invincibility, signature token, jacks, marble, bubble, item box icons |
| Track palette swatches | 8 palette strips with primary, secondary, hazard, shortcut, and UI accent colors |
| Material cards | Plastic, plush, metal, fabric, sand, tile, mud, cardboard, mirror/gloss examples |
| Audio mood board | One visual tile per track to guide Suno prompts and SFX selection |

## Online CC0 Search Backlog

Search these only after Kenney/Meshy review shows a concrete gap.

| Gap | First search source | Notes |
| --- | --- | --- |
| Carpet/fabric texture | ambientCG | Use 1K first; avoid photoreal noise overpowering toy style |
| Kitchen tile / bathroom tile | ambientCG or Poly Haven | Keep scale oversized/toy readable |
| Sand / dirt / mud | ambientCG | Use as material input; simplify color in Godot if needed |
| Bright plastic material reference | ambientCG / Poly Haven | Prefer procedural Godot material if texture looks too realistic |
| Low-poly bucket/shovel | Quaternius | Use only if Meshy sandbox output is weak |
| Low-poly cardboard/trunk/attic props | Quaternius | Use only if Furniture Kit lacks usable boxes/trunks |
| One-off CC0 audio | OpenGameArt | Only CC0 assets unless a later decision accepts attribution |

## Verification Checklist

- Before import: confirm every selected file has a source row and license.
- After import: open Godot and verify at least one asset per category imports with scale, material, and orientation intact.
- For audio: normalize target loudness by category; UI quieter than gameplay, music below SFX.
- For Meshy: inspect silhouette, polycount, material readability, and collision suitability before runtime use.
- Commit only inventory/import work that has been verified; do not include unrelated dirty workspace files.
