# Sandbox Stage Build Spec

Stage: Sandbox / Rexx
Owner faction: The Sand Throne
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as Rexx's conquered sand territory. The blockout should be aggressive and exposed, but clean and intentionally arranged rather than dirty or ruined.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoadGridMap`: source of truth for route cells, checkpoints, start tile, and 8 generated spawns.
- `StageInteractions`: explicit `StageInteractionAuthoring` areas for `ShovelRampBoostZone` and `SandBurstSlowZone`.
- `Dressing`: named `StagePropAuthoring` markers for every visible landmark and route beat.
- `BackyardShell`: shared optimized backyard floor, horizon containment, and route-readable sandbox staging.
- `Lighting`: named throne, fossil, and route-read fills; keep exposed silhouettes readable.
- `AudioZones`: at least grit slide, fossil clack, and bucket tunnel zones where available.

Do not use legacy `RoutePoints`, `ItemSockets`, `HazardSockets`, or `RoadSegments` for this stage.

## Route Direction

Build a heavy loop around the sand ridge throne. The route should pass through an overturned bucket tunnel, climb berms, jump or pass below a fossil arch, hit a shovel ramp, and return past the tribute pile.

Make the route feel forceful without becoming unreadable. The throne should overlook the loop, but not block the camera.

## Visible Objects

Required visible landmarks:

- `SandRidgeThrone`
- `OverturnedBucketTunnel`
- `FossilArch`
- `ShovelRamp`
- `TributePile`
- `BermWalls`

Use existing sandbox/fossil/bucket assets where practical. Godot-authored visible shapes are acceptable when named as the intended object and colored as sand, bone, bucket plastic, or Rexx faction dressing.

## Hazards And Simple Behavior

- Berm hazards: raised edges or rough zones with simple collision.
- Fossil arch: static obstacle and route frame.
- Bucket tunnel: compressed visibility but camera-safe.
- Tribute pile: visual landmark outside primary path or static hazard if placed near route.
- Shovel ramp: jump or speed beat with reset-safe landing.

## Signature Effect

Implement one Sandbox effect hook:

- Preferred: `SandBurstZone` near the shovel ramp or berm, using a simple particle burst, dust-colored mesh, or audio zone.
- Acceptable alternative: `GritTrailSegment` as a surface segment that provides sand audio and visible grit feedback.

## Acceptance Checklist

- Closed route validates with 5-7 checkpoints and 8 spawns.
- Lap target is roughly 30 seconds for a competent local player.
- Stage has visible Rexx/Sand Throne landmarks, not only markers.
- No legacy item or hazard sockets exist; route pressure is authored through `StageInteractions`.
- Bucket tunnel and fossil arch are readable and camera-safe.
- One sand/grit signature effect is present and testable.
- Shovel ramp landing has reset coverage and does not throw players out of bounds unfairly.
