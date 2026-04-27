# Meshy Batch: Character, Kart, and Landmark Exploration

Date: 2026-04-27

Model: `meshy-6`

Output format requested: `glb`

Purpose: create exploratory 3D assets for each approved racer direction before final production cleanup.

Batch status: all 24 active `meshy-6` tasks succeeded.

## Source Images

The racer-in-kart image references are stored in:

- `docs/concepts/characters/rexx-kart.png`
- `docs/concepts/characters/moko-kart.png`
- `docs/concepts/characters/tuggs-kart.png`
- `docs/concepts/characters/popper-kart.png`
- `docs/concepts/characters/sir-clink-kart.png`
- `docs/concepts/characters/slammo-kart.png`
- `docs/concepts/characters/velva-kart.png`
- `docs/concepts/characters/dash-kart.png`

## Tasks

| Character | Asset | Meshy task ID | Source |
| --- | --- | --- | --- |
| Rexx | standalone racer | `019dcfed-9fb2-7b57-b2ef-ecdc344117a5` | text prompt |
| Rexx | racer in kart | `019dcfec-dee7-7d31-9031-096bb2b53d61` | `rexx-kart.png` |
| Rexx | Sandbox landmark set | `019dcfef-477b-7bee-8042-24eb7b5b58cf` | text prompt |
| Moko | standalone racer | `019dcff0-014c-7e85-86e7-172d40c4a9ad` | text prompt |
| Moko | racer in kart | `019dcff0-e320-7267-9bda-6798344acc6f` | `moko-kart.png` |
| Moko | Garden landmark set | `019dcff1-cd45-7f52-b8dc-47bd432ccdc0` | text prompt |
| Tuggs | standalone racer | `019dcff2-7f24-72a7-b2bf-809086a7a55e` | text prompt |
| Tuggs | racer in kart | `019dcff3-2fcd-7ded-8439-c969dd9021fd` | `tuggs-kart.png` |
| Tuggs | Bedroom landmark set | `019dcff3-ee06-7e61-ab17-b345f812f4e6` | text prompt |
| Popper | standalone racer | `019dcff4-ad87-7e19-854e-d22c8dd185ec` | text prompt |
| Popper | racer in kart | `019dcff5-4603-7e64-934a-59b85d91ca71` | `popper-kart.png` |
| Popper | Attic landmark set | `019dcff5-f843-7eef-8776-86cb15555d76` | text prompt |
| Sir Clink | standalone racer | `019dcff6-b7e4-73a2-b1f6-0174424d1bc8` | text prompt |
| Sir Clink | racer in kart | `019dcff7-8355-73cc-82d7-2461c48d4d84` | `sir-clink-kart.png` |
| Sir Clink | Kitchen landmark set | `019dcff8-3f63-7fa3-bf23-edee117e7839` | text prompt |
| Slammo | standalone racer | `019dcff8-fa3c-7027-b949-bdf09995ee52` | text prompt |
| Slammo | racer in kart | `019dcff9-abd9-7432-828c-beb153c1f35a` | `slammo-kart.png` |
| Slammo | Playroom landmark set | `019dcffa-82bd-7014-905c-7667fe01d2da` | text prompt |
| Velva | standalone racer | `019dcffb-2ac7-70f0-9b45-6ca3b1034efe` | text prompt |
| Velva | racer in kart | `019dcffc-02f1-70ba-b0bf-04bf1463c864` | `velva-kart.png` |
| Velva | Glam Closet landmark set | `019dcffc-bab8-72b9-af76-e1bef3943690` | text prompt |
| Dash | standalone racer | `019dcffd-585e-712d-b014-6d5475e96fdf` | text prompt |
| Dash | racer in kart | `019dcffe-6a43-71bb-93c0-99dac83f5907` | `dash-kart.png` |
| Dash | Outdoor Playground landmark set | `019dcfff-2860-74bf-9686-72319f5d21b4` | text prompt |

## Notes

- Early Rexx `meshy-5` tasks were started before the user approved `meshy-6`; the `meshy-6` tasks above are the active batch.
- Racer-in-kart tasks use image-to-3D from the approved local concept images.
- Standalone racers use T-pose text-to-3D prompts for later rigging evaluation.
- Landmark sets are modular track prop/setpiece prompts; race routes and collision should still be authored in Godot.
- Checked with Meshy on 2026-04-27; every active task in the table returned `SUCCEEDED` at 100% progress.
