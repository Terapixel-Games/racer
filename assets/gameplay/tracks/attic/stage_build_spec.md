# Attic Stage Build Spec

Stage: Attic / Popper
Owner faction: The Attic Pranks
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as Popper's rule-breaking attic. The stage should be deceptive and playful while staying fair: players should learn the trick, not feel randomly punished.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoutePoints`: closed loop route markers.
- `Checkpoints`: 5-7 markers, with the first marker or a clearly named lap marker acting as the lap gate.
- `ItemSockets`: 6-10 item marker sockets.
- `HazardSockets`: 4-8 hazard marker sockets.
- `ShortcutGates`: at least one hidden or prank shortcut.
- `Dressing`: visible props using `StagePropAuthoring` or scene instances.
- `SurfaceSegments`: at least wood, box/cardboard, sheet, and prank-route sections.
- `AudioZones`: at least prank squeak, box fall, and attic creak zones.

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
- At least 6 item sockets and 4 hazard sockets exist.
- At least one prank shortcut or false-gate beat is present and fair.
- Signature prank or marble effect is present and testable.
- Sheet tunnel and trunk maze do not cause camera clipping or unresolved reset gaps.
