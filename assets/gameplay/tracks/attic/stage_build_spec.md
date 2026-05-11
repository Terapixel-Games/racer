# Attic Stage Build Spec

Stage: Attic / Popper
Owner faction: The Attic Pranks
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as Popper's rule-breaking attic. The stage should be deceptive and playful while staying fair: players should learn the trick, not feel randomly punished.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoadGridMap`: source of truth for route cells, checkpoints, start tile, and 8 generated spawns.
- `StageInteractions`: explicit `StageInteractionAuthoring` areas for `PrankTriggerZone` and `MarbleTrapRelease`.
- `Dressing`: named `StagePropAuthoring` markers for every visible landmark and route beat.
- `RoomShell`: floor, side walls, rear wall, front opening treatment, and ceiling with no visible leaks.
- `Lighting`: named readable route and landmark lights; keep them visually supported by the room.
- `AudioZones`: at least prank squeak, box fall, and attic creak zones where available.

Do not use legacy `RoutePoints`, `ItemSockets`, `HazardSockets`, or `RoadSegments` for this stage.

## Route Direction

Build a deceptive loop through a trunk maze, sheet tunnel, box-stack switchback, false finish gate, marble trap, and string-lift or hidden-ramp shortcut.

Keep deception readable after first exposure. The route can surprise players, but it must not hide collision or camera-blocking geometry unfairly.

## Visible Objects

Required visible landmarks:

- `PrankTrunkMaze`
- `StringLiftShortcut`
- `FalseFinishGate`
- `SheetTunnel`
- `BoxStackSwitchback`
- `MarbleTrap`

Use existing furniture/box/marble props where practical. If Godot-authored props are used, give real object names and faction colors.

## Hazards And Simple Behavior

- False finish gate: visual misdirection only; do not create an unfair dead end.
- Marble trap: visible hazard socket or simple timed/rolling prop.
- Sheet tunnel: compressed visibility with safe camera clearance.
- Box switchbacks: technical turns with simple static collision.
- String-lift shortcut: moving platform or visual shortcut gate if motion is not yet implemented.

## Signature Effect

Implement one Attic effect hook:

- Preferred: `PrankTriggerZone` that pops a false gate, plays a squeak, or reveals a shortcut.
- Acceptable alternative: `MarbleTrapRelease` with a visible marble drop/roll effect.

## Acceptance Checklist

- Closed route validates with 5-7 checkpoints and 8 spawns.
- Lap target is roughly 30 seconds for a competent local player.
- Stage has visible Attic Pranks landmarks, not just boxes and markers.
- No legacy item or hazard sockets exist; route pressure is authored through `StageInteractions`.
- At least one prank shortcut or false-gate beat is present and fair.
- Signature prank or marble effect is present and testable.
- Sheet tunnel and trunk maze do not cause camera clipping or unresolved reset gaps.
