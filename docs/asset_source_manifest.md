# Racer Asset Source Manifest

Date: 2026-04-27

Purpose: record the first sourced asset pass derived from `docs/asset_acquisition_inventory.md`.

This pass sourced local CC0 Kenney assets and downloaded the approved Meshy-6 exploratory batch as GLB files. No ambientCG, Poly Haven, Quaternius, OpenGameArt, Suno, SFXR, or Figma exports were imported in this pass.

## Source Roots

| Source | Repo path | Notes |
| --- | --- | --- |
| Kenney meshes | `assets/source/kenney` | Curated GLB candidates plus each pack `License.txt` |
| Kenney audio | `assets/source/kenney_audio` | Curated OGG candidates plus each pack `License.txt` |
| Meshy batch | `assets/source/meshy/2026-04-27-character-track-batch` | 24 approved GLB downloads from the Meshy-6 batch |

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

Total sourced non-import files: 170.

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
- Git LFS is configured for `*.glb`, `*.png`, and `*.jpg` in `.gitattributes`; the sourced large binary files are intended to be stored through LFS.
- Godot generated `.import` sidecars for many sourced assets while the project/editor was active. These sidecars are included with the sourced files for import reproducibility.

