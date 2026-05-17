# Garden Stage Build Spec

Stage: Garden / Moko
Owner faction: The Green Claim
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as Moko's adaptive survival territory. The garden should feel intentionally overclaimed and terrain-driven, not neglected.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoadGridMap`: source of truth for route cells, checkpoints, start tile, and 8 generated spawns.
- `StageInteractions`: explicit `StageInteractionAuthoring` areas for `HoseSplashZone` and `StoneBridgeExitBoost`.
- `Dressing`: named `StagePropAuthoring` markers for every visible landmark and route beat.
- `BackyardShell`: shared optimized backyard floor, horizon containment, and route-readable garden staging.
- `Lighting`: named canopy and route-read fills; keep foliage readable from kart height.
- `AudioZones`: at least water crossing, leaf rustle, and stone hit zones where available.
- `GrassZones`: optional, but use if grass/foliage coverage is part of the blockout.

Do not use legacy `RoutePoints`, `ItemSockets`, `HazardSockets`, or `RoadSegments` for this stage.

## Route Direction

Build a terrain loop that crosses a stone bridge, ducks under or around a root gate, runs beside a hose crossing, cuts through a flower canopy, and returns past survival markers made from toy scraps.

Shortcuts should reward reading terrain. Avoid hiding entries behind dense foliage.

## Visible Objects

Required visible landmarks:

- `RootGate`
- `StoneBridge`
- `HoseCrossing`
- `FlowerCanopy`
- `SurvivalMarkers`
- `LogHazard`

Use existing nature assets where practical. Foliage should be broad and readable, not dense enough to block the camera.

## Hazards And Simple Behavior

- Root/log hazards: static obstacle collision.
- Mud/leaf segment: slow or grip-change zone if supported; otherwise visible named surface segment.
- Hose crossing: wet/splash effect zone.
- Flower canopy: visual tunnel with generous camera clearance.
- Hidden green shortcut: visible after discovery, with clear exit.

## Signature Effect

Implement one Garden effect hook:

- Preferred: `HoseSplashZone` with water/splash feedback and an audio zone.
- Acceptable alternative: `MudSlideSegment` with surface audio and visible mud/leaf feedback.

## Acceptance Checklist

- Closed route validates with 5-7 checkpoints and 8 spawns.
- Lap target is roughly 30 seconds for a competent local player.
- Stage has visible Green Claim landmarks and survival markers.
- No legacy item or hazard sockets exist; route pressure is authored through `StageInteractions`.
- Foliage does not block camera or hide required route direction.
- One hose/water or mud signature effect is present and testable.
- Shortcut entry is discoverable without unfair blind turns.
