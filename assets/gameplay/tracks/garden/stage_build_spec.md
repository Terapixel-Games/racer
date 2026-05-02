# Garden Stage Build Spec

Stage: Garden / Moko
Owner faction: The Green Claim
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as Moko's adaptive survival territory. The garden should feel intentionally overclaimed and terrain-driven, not neglected.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoutePoints`: closed loop route markers.
- `Checkpoints`: 5-7 markers, with the first marker or a clearly named lap marker acting as the lap gate.
- `ItemSockets`: 6-10 item marker sockets.
- `HazardSockets`: 4-8 hazard marker sockets.
- `ShortcutGates`: one hidden green route or root shortcut when readable.
- `Dressing`: visible props using `StagePropAuthoring` or scene instances.
- `SurfaceSegments`: at least dirt, mud/leaf, stone, and hose/wet sections.
- `AudioZones`: at least water crossing, leaf rustle, and stone hit zones.
- `GrassZones`: optional, but use if grass/foliage coverage is part of the blockout.

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
- At least 6 item sockets and 4 hazard sockets exist.
- Foliage does not block camera or hide required route direction.
- One hose/water or mud signature effect is present and testable.
- Shortcut entry is discoverable without unfair blind turns.
