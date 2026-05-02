# Outdoor Playground Stage Build Spec

Stage: Outdoor Playground / Dash
Owner faction: The Open Run
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as Dash's fast open-route territory. The route should be kinetic, exposed, and readable, with real visible stunt objects rather than abstract placeholder ramps.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoutePoints`: closed loop route markers.
- `Checkpoints`: 5-7 markers, with the first marker or a clearly named lap marker acting as the lap gate.
- `ItemSockets`: 6-10 item marker sockets.
- `HazardSockets`: 4-8 hazard marker sockets.
- `ShortcutGates`: at least one border-break shortcut.
- `Dressing`: visible props using `StagePropAuthoring` or scene instances.
- `SurfaceSegments`: at least blacktop/play surface, slide, ramp, and rail-adjacent sections.
- `AudioZones`: at least slide drop, swing chain, and stunt whoosh zones.

## Route Direction

Build a momentum loop that starts near a broken-border gate, climbs toward a slide drop, crosses a swing hazard, banks around a half-pipe turn, passes a rail-adjacent shortcut, and returns through chalk-marked route arrows.

The track should favor speed and commitment. Landing zones must be visible before jumps.

## Visible Objects

Required visible landmarks:

- `SlideDrop`
- `SwingGate`
- `ChalkRouteArrows`
- `RailShortcut`
- `HalfPipeBank`
- `BrokenBorderGate`

Use existing mini-skate/playground assets where practical. Godot-authored ramps should be colored and named as the intended playground object.

## Hazards And Simple Behavior

- Swing gate: moving or implied pendulum hazard; if animated, keep deterministic.
- Slide drop: speed/impact beat with safe landing.
- Rail shortcut: narrow but forgiving helper collision.
- Half-pipe bank: wide high-speed turn.
- Border-break shortcut: faster line that visibly bypasses normal borders.

## Signature Effect

Implement one Outdoor Playground effect hook:

- Preferred: `SwingGate` with a simple deterministic motion effect.
- Acceptable alternative: `SlideDropBoostZone` with speed/impact visual feedback and stunt audio.

## Acceptance Checklist

- Closed route validates with 5-7 checkpoints and 8 spawns.
- Lap target is roughly 30 seconds for a competent local player.
- Stage has visible Open Run landmarks and chalk route language.
- At least 6 item sockets and 4 hazard sockets exist.
- Jump landings and slide drop are readable and reset-safe.
- Signature swing or slide effect is present and testable.
- Thin rails do not create snaggy collision; use forgiving helper collision.
