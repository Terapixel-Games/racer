# Racer Asset Source Manifest

Date: 2026-04-27

Purpose: record the first sourced asset pass derived from `docs/asset_acquisition_inventory.md`.

This pass sourced local CC0 Kenney assets, downloaded the approved Meshy-6 exploratory batch as GLB files, added Canva-generated sound effect exports, added the first Suno music exports, and created approved generated material textures. No ambientCG, Poly Haven, Quaternius, OpenGameArt, SFXR, or Figma exports were imported in this pass.

## Source Roots

| Source | Repo path | Notes |
| --- | --- | --- |
| Kenney meshes | `assets/source/kenney` | Curated GLB candidates plus each pack `License.txt` |
| Kenney audio | `assets/source/kenney_audio` | Curated OGG candidates plus each pack `License.txt` |
| Meshy batch | `assets/source/meshy/2026-04-27-character-track-batch` | 24 approved GLB downloads from the Meshy-6 batch |
| Canva audio | `assets/source/audio/canva` | User-generated Canva AI sound effect exports; verify final Canva terms before release |
| Suno music | `assets/source/audio/suno` | User-generated Suno music exports; verify final Suno terms before release |
| Generated material textures | `assets/source/generated/textures/toy_materials_2026-04-27` | Approved AI-generated toy material contact sheet plus cropped 1K albedo textures |
| Generated character headshots | `assets/source/generated/ui/character_headshots_2026-04-27` | Approved AI-generated character-select contact sheet plus cropped UI portraits |

## Sourced Counts

Counts below exclude Godot `.import` sidecars.

| Group | Count | Contents |
| --- | ---: | --- |
| Kenney `toy_car_kit` | 21 | gates, item box, cone, smoke, supports, toy road/track modules |
| Kenney `racing_kit` | 15 | barriers, flags, pylons, rails, ramp, light, billboard |
| Kenney `furniture_kit` | 24 | beds, rugs, books, lamps, cabinets, bear, tables, chairs, sink, mirror, bath, toilet, plant |
| Kenney `food_kit` | 12 | fruit, cup, bowl, cookie, utensils, cutting board, bottle, can |
| Kenney `nature_kit` | 17 | stones, paths, bridge pieces, bushes, grass, flowers, logs |
| Kenney `mini_skate` | 11 | half-pipe, rails, steps, pallet, platforms, obstacle box |
| Kenney `marble_kit` | 11 | marbles, ramps, funnel, curves, bumps |
| Kenney audio | 27 | UI, digital powerups, foley, impacts |
| Meshy GLBs | 24 | 8 racers, 8 racers-in-karts, 8 landmark sets |
| Canva audio | 42 | Jacks deploy, jacks hit, bubble pop, invincibility start/end, signature charge/activate, boost burst, drift release, marble fire/hit, item pickup/roulette, kart bump, wall scrape, heavy landing, countdown tick/go, UI confirm/back/select, lobby ready, results reveal, victory/lose stingers, attic creak, attic prank squeak, bedroom plush thump, kitchen clatter, and track identity sound effects |
| Suno music | 9 | Main menu theme, race base loop, and 7 room-track loops; sandbox loop still outstanding |
| Generated material textures | 17 | 1 approved contact sheet, 8 source albedo crops, and 8 runtime albedo copies |
| Generated character headshots | 17 | 1 approved contact sheet, 8 source portrait crops, and 8 runtime character-select portraits |

Total sourced non-import files: 255.

## Canva Audio Layout

| File | Original source | Format | Intended use |
| --- | --- | --- | --- |
| `assets/source/audio/canva/items/jacks/jacks_deploy_canva_01.wav` | `C:\Users\john_\Downloads\jacks_deploy_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Jacks trap deploy sound |
| `assets/source/audio/canva/items/jacks/jacks_hit_canva_01.wav` | `C:\Users\john_\Downloads\jacks_hit_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Jacks trap hit sound |
| `assets/source/audio/canva/items/bubble/bubble_pop_canva_01.wav` | `C:\Users\john_\Downloads\bubble_pop_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Bubble shield pop sound |
| `assets/source/audio/canva/items/invincibility/invincibility_start_canva_01.wav` | `C:\Users\john_\Downloads\invincibility_start_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Invincibility activation sound |
| `assets/source/audio/canva/items/invincibility/invincibility_end_canva_01.wav` | `C:\Users\john_\Downloads\invincibility_end_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Invincibility end sound |
| `assets/source/audio/canva/items/signature/signature_charge_canva_01.wav` | `C:\Users\john_\Downloads\signature_charge_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Signature move charge sound |
| `assets/source/audio/canva/items/signature/signature_activate_canva_01.wav` | `C:\Users\john_\Downloads\signature_activate_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Signature move activation sound |
| `assets/source/audio/canva/driving/boost/boost_burst_canva_01.wav` | `C:\Users\john_\Downloads\boost_burst_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Boost burst driving sound |
| `assets/source/audio/canva/driving/drift/drift_release_canva_01.wav` | `C:\Users\john_\Downloads\drift_release_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Drift release driving sound |
| `assets/source/audio/canva/items/marble/marble_fire_canva_01.wav` | `C:\Users\john_\Downloads\marble_fire_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Marble projectile fire sound |
| `assets/source/audio/canva/items/marble/marble_hit_canva_01.wav` | `C:\Users\john_\Downloads\marble_hit_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Marble projectile hit sound |
| `assets/source/audio/canva/items/pickup/item_pickup_canva_01.wav` | `C:\Users\john_\Downloads\item_pickup_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Item pickup sound |
| `assets/source/audio/canva/items/pickup/item_roulette_canva_01.wav` | `C:\Users\john_\Downloads\item_roulette_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Item roulette sound |
| `assets/source/audio/canva/driving/impact/kart_bump_canva_01.wav` | `C:\Users\john_\Downloads\kart_bump_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Kart bump driving sound |
| `assets/source/audio/canva/driving/impact/wall_scrape_canva_01.wav` | `C:\Users\john_\Downloads\wall_scrape_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Wall scrape driving sound |
| `assets/source/audio/canva/driving/impact/heavy_landing_canva_01.wav` | `C:\Users\john_\Downloads\heavy_landing_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Heavy landing driving sound |
| `assets/source/audio/canva/ui/race_start/countdown_tick_canva_01.wav` | `C:\Users\john_\Downloads\countdown_tick_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Race countdown tick sound |
| `assets/source/audio/canva/ui/race_start/countdown_go_canva_01.wav` | `C:\Users\john_\Downloads\countdown_go_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Race countdown go sound |
| `assets/source/audio/canva/ui/menu/ui_confirm_canva_01.wav` | `C:\Users\john_\Downloads\ui_confirm_canva_01.mp4` | Mono 44.1 kHz PCM WAV | UI confirm sound |
| `assets/source/audio/canva/ui/menu/ui_back_canva_01.wav` | `C:\Users\john_\Downloads\ui_back_canva_01.mp4` | Mono 44.1 kHz PCM WAV | UI back sound |
| `assets/source/audio/canva/ui/menu/ui_select_canva_01.wav` | `C:\Users\john_\Downloads\ui_select_canva_01.mp4` | Mono 44.1 kHz PCM WAV | UI select sound |
| `assets/source/audio/canva/ui/lobby/lobby_ready_canva_01.wav` | `C:\Users\john_\Downloads\lobby_ready_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Lobby ready sound |
| `assets/source/audio/canva/ui/results/results_reveal_canva_01.wav` | `C:\Users\john_\Downloads\results_reveal_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Results reveal sound |
| `assets/source/audio/canva/ui/results/victory_stinger_canva_01.wav` | `C:\Users\john_\Downloads\victory_stinger_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Victory stinger sound |
| `assets/source/audio/canva/ui/results/lose_stinger_canva_01.wav` | `C:\Users\john_\Downloads\lose_stinger_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Lose stinger sound |
| `assets/source/audio/canva/tracks/attic/attic_creak_canva_01.mp3` | `C:\Users\john_\Downloads\attic_creak_canva_01.mp3` | Stereo 48 kHz MP3 | Attic creak track accent |
| `assets/source/audio/canva/tracks/attic/attic_prank_squeak_canva_01.wav` | `C:\Users\john_\Downloads\attic_prank_squeak_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Attic prank squeak track accent |
| `assets/source/audio/canva/tracks/bedroom/bedroom_plush_thump_canva_01.wav` | `C:\Users\john_\Downloads\bedroom_plush_thump_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Bedroom plush thump track accent |
| `assets/source/audio/canva/tracks/bedroom/bedroom_blanket_slide_canva_01.mp3` | `C:\Users\john_\Downloads\bedroom_blanket_slide_canva_01.mp3` | Stereo 24 kHz MP3 | Bedroom blanket slide track accent |
| `assets/source/audio/canva/tracks/garden/garden_stone_hit_canva_01.mp3` | `C:\Users\john_\Downloads\garden_stone_hit_canva_01.mp3` | Stereo 24 kHz MP3 | Garden stone hit track accent |
| `assets/source/audio/canva/tracks/garden/garden_mud_splat_canva_01.wav` | `C:\Users\john_\Downloads\garden_mud_splat_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Garden mud splat track accent |
| `assets/source/audio/canva/tracks/playroom/playroom_block_crash_canva_01.mp3` | `C:\Users\john_\Downloads\playroom_block_crash_canva_01.mp3` | Stereo 44.1 kHz MP3 | Playroom block crash track accent |
| `assets/source/audio/canva/tracks/playroom/playroom_spring_ramp_canva_01.mp3` | `C:\Users\john_\Downloads\playroom_spring_ramp_canva_01.mp3` | Stereo 44.1 kHz MP3 | Playroom spring ramp track accent |
| `assets/source/audio/canva/tracks/glam_closet/glam_sparkle_whoosh_canva_01.mp3` | `C:\Users\john_\Downloads\glam_sparkle_whoosh_canva_01.mp3` | Stereo 44.1 kHz MP3 | Glam closet sparkle whoosh track accent |
| `assets/source/audio/canva/tracks/glam_closet/glam_perfume_puff_canva_01.mp3` | `C:\Users\john_\Downloads\glam_perfume_puff_canva_01.mp3` | Stereo 44.1 kHz MP3 | Glam closet perfume puff track accent |
| `assets/source/audio/canva/tracks/kitchen/kitchen_clatter_canva_01.mp3` | `C:\Users\john_\Downloads\kitchen_clatter_canva_01.mp3` | Stereo 24 kHz MP3 | Kitchen clatter track accent |
| `assets/source/audio/canva/tracks/kitchen/kitchen_sink_splash_canva_01.mp3` | `C:\Users\john_\Downloads\kitchen_sink_splash_canva_01.mp3` | Stereo 24 kHz MP3 | Kitchen sink splash track accent |
| `assets/source/audio/canva/tracks/kitchen/kitchen_utensil_clink_canva_01.wav` | `C:\Users\john_\Downloads\kitchen_utensil_clink_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Kitchen utensil clink track accent |
| `assets/source/audio/canva/tracks/sandbox/sandbox_grit_slide_canva_01.wav` | `C:\Users\john_\Downloads\sandbox_grit_slide_canva_01.mp4` | Mono 44.1 kHz PCM WAV | Sandbox grit slide track accent |
| `assets/source/audio/canva/tracks/sandbox/sandbox_bucket_bonk_canva_01.mp3` | `C:\Users\john_\Downloads\sandbox_bucket_bonk_canva_01.mp3` | Stereo 24 kHz MP3 | Sandbox bucket bonk track accent |
| `assets/source/audio/canva/tracks/playground/playground_chain_swing_canva_01.mp3` | `C:\Users\john_\Downloads\playground_chain_swing_canva_01.mp3` | Mono 44.1 kHz MP3 | Playground chain swing track accent |
| `assets/source/audio/canva/tracks/playground/playground_slide_drop_canva_01.mp3` | `C:\Users\john_\Downloads\playground_slide_drop_canva_01.mp3` | Stereo 48 kHz MP3 | Playground slide drop track accent |

## Suno Music Layout

| File | Original source | Format | Duration | Intended use |
| --- | --- | --- | ---: | --- |
| `assets/source/audio/suno/menu/main_menu_theme_suno_01.mp3` | `C:\Users\john_\Downloads\main_menu_theme_suno_01.mp3` | Stereo 48 kHz MP3 | 64.92s | Main menu music |
| `assets/source/audio/suno/race/race_base_loop_suno_01.mp3` | `C:\Users\john_\Downloads\race_base_loop_suno_01.mp3` | Stereo 48 kHz MP3 | 22.08s | Race base loop |
| `assets/source/audio/suno/tracks/bedroom/bedroom_loop_suno_01.mp3` | `C:\Users\john_\Downloads\bedroom_loop_suno_01.mp3` | Stereo 48 kHz MP3 | 52.92s | Bedroom track loop |
| `assets/source/audio/suno/tracks/playroom/playroom_loop_suno_01.mp3` | `C:\Users\john_\Downloads\playroom_loop_suno_01.mp3` | Stereo 48 kHz MP3 | 44.52s | Playroom track loop |
| `assets/source/audio/suno/tracks/glam_closet/glam_closet_loop_suno_01.mp3` | `C:\Users\john_\Downloads\glam_closet_loop_suno_01.mp3` | Stereo 48 kHz MP3 | 66.55s | Glam closet track loop |
| `assets/source/audio/suno/tracks/garden/garden_loop_suno_01.mp3` | `C:\Users\john_\Downloads\garden_loop_suno_01.mp3` | Stereo 48 kHz MP3 | 121.15s | Garden track loop |
| `assets/source/audio/suno/tracks/playground/playground_loop_suno_01.mp3` | `C:\Users\john_\Downloads\playground_loop_suno_01.mp3` | Stereo 48 kHz MP3 | 44.28s | Playground track loop |
| `assets/source/audio/suno/tracks/attic/attic_loop_suno_01.mp3` | `C:\Users\john_\Downloads\attic_loop_suno_01.mp3` | Stereo 48 kHz MP3 | 73.34s | Attic track loop |
| `assets/source/audio/suno/tracks/kitchen/kitchen_loop_suno_01.mp3` | `C:\Users\john_\Downloads\kitchen_loop_suno_01.mp3` | Stereo 48 kHz MP3 | 59.28s | Kitchen track loop |

## Generated Material Texture Layout

Approved source sheet: `assets/source/generated/textures/toy_materials_2026-04-27/toy_material_contact_sheet_01.png` from `C:\Users\john_\.codex\generated_images\019dcd65-2de2-74f3-b09a-e0432c85ec72\ig_046583879f9b057b0169f01052c1188190aa4450a61a4b1aba.png`.

| Material | Source albedo | Runtime albedo | Dimensions |
| --- | --- | --- | --- |
| Glossy plastic | `assets/source/generated/textures/toy_materials_2026-04-27/glossy_plastic_albedo.png` | `assets/gameplay/materials/plastic/glossy_plastic_albedo.png` | 1024x1024 |
| Plush fabric | `assets/source/generated/textures/toy_materials_2026-04-27/plush_fabric_albedo.png` | `assets/gameplay/materials/fabric/plush_fabric_albedo.png` | 1024x1024 |
| Toy metal | `assets/source/generated/textures/toy_materials_2026-04-27/toy_metal_albedo.png` | `assets/gameplay/materials/metal/toy_metal_albedo.png` | 1024x1024 |
| Sandbox sand | `assets/source/generated/textures/toy_materials_2026-04-27/sandbox_sand_albedo.png` | `assets/gameplay/materials/sand/sandbox_sand_albedo.png` | 1024x1024 |
| Kitchen tile | `assets/source/generated/textures/toy_materials_2026-04-27/kitchen_tile_albedo.png` | `assets/gameplay/materials/tile/kitchen_tile_albedo.png` | 1024x1024 |
| Garden dirt mud | `assets/source/generated/textures/toy_materials_2026-04-27/garden_dirt_mud_albedo.png` | `assets/gameplay/materials/garden/garden_dirt_mud_albedo.png` | 1024x1024 |
| Attic cardboard wood | `assets/source/generated/textures/toy_materials_2026-04-27/attic_cardboard_wood_albedo.png` | `assets/gameplay/materials/attic/attic_cardboard_wood_albedo.png` | 1024x1024 |
| Glam mirror glitter | `assets/source/generated/textures/toy_materials_2026-04-27/glam_mirror_glitter_albedo.png` | `assets/gameplay/materials/glam/glam_mirror_glitter_albedo.png` | 1024x1024 |

## Generated Character Headshot Layout

Approved source sheet: `assets/source/generated/ui/character_headshots_2026-04-27/character_headshot_contact_sheet_01.png` from `C:\Users\john_\.codex\generated_images\019dcd65-2de2-74f3-b09a-e0432c85ec72\ig_046583879f9b057b0169f01d40b5d88190a8e7ef8e0c4b2bd4.png`.

| Racer | Source portrait | Runtime portrait | Dimensions |
| --- | --- | --- | --- |
| Rexx | `assets/source/generated/ui/character_headshots_2026-04-27/rexx_headshot.png` | `assets/ui/racers/headshots/rexx_headshot.png` | 512x512 |
| Moko | `assets/source/generated/ui/character_headshots_2026-04-27/moko_headshot.png` | `assets/ui/racers/headshots/moko_headshot.png` | 512x512 |
| Tuggs | `assets/source/generated/ui/character_headshots_2026-04-27/tuggs_headshot.png` | `assets/ui/racers/headshots/tuggs_headshot.png` | 512x512 |
| Popper | `assets/source/generated/ui/character_headshots_2026-04-27/popper_headshot.png` | `assets/ui/racers/headshots/popper_headshot.png` | 512x512 |
| Sir Clink | `assets/source/generated/ui/character_headshots_2026-04-27/sir_clink_headshot.png` | `assets/ui/racers/headshots/sir_clink_headshot.png` | 512x512 |
| Slammo | `assets/source/generated/ui/character_headshots_2026-04-27/slammo_headshot.png` | `assets/ui/racers/headshots/slammo_headshot.png` | 512x512 |
| Velva | `assets/source/generated/ui/character_headshots_2026-04-27/velva_headshot.png` | `assets/ui/racers/headshots/velva_headshot.png` | 512x512 |
| Dash | `assets/source/generated/ui/character_headshots_2026-04-27/dash_headshot.png` | `assets/ui/racers/headshots/dash_headshot.png` | 512x512 |

## Meshy Layout

Each racer folder contains:

- `racer.glb`
- `racer_in_kart.glb`
- `landmark_set.glb`
- `racer_in_kart_base_color.png` where Meshy provided a separate texture

Folders:

- `rexx`
- `moko`
- `tuggs`
- `popper`
- `sir_clink`
- `slammo`
- `velva`
- `dash`

Task IDs remain recorded in `docs/meshy_batches/2026-04-27-character-track-batch.md`.

## Verification Notes

- Representative Kenney source paths were checked before copying.
- Kenney source pack license files were copied with each sourced pack.
- Meshy downloads used the GLB format specified by the inventory.
- The Canva jacks deploy, jacks hit, bubble pop, invincibility start/end, signature charge/activate, boost burst, drift release, marble fire/hit, item pickup/roulette, kart bump, wall scrape, heavy landing, countdown tick/go, UI confirm/back/select, lobby ready, results reveal, victory/lose stinger, attic prank squeak, bedroom plush thump, garden mud splat, sandbox grit slide, and kitchen utensil clink MP4s were converted to mono 44.1 kHz PCM WAV source files for Godot import.
- The Canva attic creak, kitchen clatter, garden stone hit, playroom block crash, playroom spring ramp, glam sparkle whoosh, glam perfume puff, sandbox bucket bonk, playground chain swing, playground slide drop, kitchen sink splash, and bedroom blanket slide exports were kept as MP3 by request and copied without transcoding.
- The Suno music exports were kept as MP3 source files and verified with ffmpeg. `sandbox_loop_suno_01.mp3` was not present in Downloads during this import pass.
- The generated material texture contact sheet was approved by the user, copied into source assets, cropped into eight material albedos, resized to 1024x1024 PNGs, and copied to runtime material folders.
- The generated character headshot contact sheet was approved by the user, copied into source assets, cropped into eight square portraits, resized to 512x512 PNGs, and copied to runtime UI folders.
- Git LFS is configured for `*.glb`, `*.png`, and `*.jpg` in `.gitattributes`; the sourced large binary files are intended to be stored through LFS.
- Godot generated `.import` sidecars for many sourced assets while the project/editor was active. These sidecars are included with the sourced files for import reproducibility.
