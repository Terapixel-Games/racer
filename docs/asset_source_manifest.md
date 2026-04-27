# Racer Asset Source Manifest

Date: 2026-04-27

Purpose: record the first sourced asset pass derived from `docs/asset_acquisition_inventory.md`.

This pass sourced local CC0 Kenney assets, downloaded the approved Meshy-6 exploratory batch as GLB files, and added the first Canva-generated sound effect exports. No ambientCG, Poly Haven, Quaternius, OpenGameArt, Suno, SFXR, or Figma exports were imported in this pass.

## Source Roots

| Source | Repo path | Notes |
| --- | --- | --- |
| Kenney meshes | `assets/source/kenney` | Curated GLB candidates plus each pack `License.txt` |
| Kenney audio | `assets/source/kenney_audio` | Curated OGG candidates plus each pack `License.txt` |
| Meshy batch | `assets/source/meshy/2026-04-27-character-track-batch` | 24 approved GLB downloads from the Meshy-6 batch |
| Canva audio | `assets/source/audio/canva` | User-generated Canva AI sound effect exports; verify final Canva terms before release |

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
| Canva audio | 22 | Jacks deploy, jacks hit, bubble pop, invincibility start/end, signature charge/activate, boost burst, drift release, marble fire/hit, item pickup/roulette, kart bump, wall scrape, heavy landing, countdown tick/go, UI confirm/back/select, and lobby ready sound effects |

Total sourced non-import files: 192.

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
- The Canva jacks deploy, jacks hit, bubble pop, invincibility start/end, signature charge/activate, boost burst, drift release, marble fire/hit, item pickup/roulette, kart bump, wall scrape, heavy landing, countdown tick/go, UI confirm/back/select, and lobby ready MP4s were converted to mono 44.1 kHz PCM WAV source files for Godot import.
- Git LFS is configured for `*.glb`, `*.png`, and `*.jpg` in `.gitattributes`; the sourced large binary files are intended to be stored through LFS.
- Godot generated `.import` sidecars for many sourced assets while the project/editor was active. These sidecars are included with the sourced files for import reproducibility.
