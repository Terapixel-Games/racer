# Glam Closet Stage Build Spec

Stage: Glam Closet / Velva
Owner faction: The Mirror Court
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as Velva's display court. The route should be glossy, theatrical, and controlled, with clear visible objects that show rank, attention, and staged beauty.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoutePoints`: closed loop route markers.
- `Checkpoints`: 5-7 markers, with the first marker or a clearly named lap marker acting as the lap gate.
- `ItemSockets`: 6-10 item marker sockets.
- `HazardSockets`: 4-8 hazard marker sockets.
- `ShortcutGates`: one status-gate or vanity shortcut when readable.
- `Dressing`: visible props using `StagePropAuthoring` or scene instances.
- `SurfaceSegments`: at least glossy runway, mirror/pedestal, and perfume mist sections.
- `AudioZones`: at least perfume puff, sparkle whoosh, and vanity ambience zones.

## Route Direction

Build a theatrical loop that starts on a vanity runway, sweeps through a mirror arch, crosses or circles display pedestals, passes through a perfume mist zone, jumps or climbs a jewelry-box ramp, and returns through a status-gate shortcut.

Keep the route beautiful but readable. Reflections and sparkle should not obscure steering lines.

## Visible Objects

Required visible landmarks:

- `MirrorArch`
- `VanityRunway`
- `PerfumeMistZone`
- `JewelryBoxRamp`
- `DisplayPedestals`
- `StatusGate`

Use existing furniture/mirror props where practical. Fake mirror effects are acceptable; do not require expensive real-time mirror rendering for the first playable build.

## Hazards And Simple Behavior

- Perfume mist: visual obstruction or slow zone; must remain readable.
- Jewelry clutter: static or bumpable-looking obstacles.
- Pedestal edges: elevated narrow line with forgiving collision.
- Status-gate shortcut: narrow but visible before entry.
- Vanity runway: fast, glossy straight with clear borders.

## Signature Effect

Implement one Glam Closet effect hook:

- Preferred: `PerfumeMistZone` with particles/transparent visual volume and an audio zone.
- Acceptable companion: `HairDryerHeatZone` that reuses heat-distortion-style feedback near a hairdryer landmark.

## Acceptance Checklist

- Closed route validates with 5-7 checkpoints and 8 spawns.
- Lap target is roughly 30 seconds for a competent local player.
- Stage has visible Mirror Court landmarks, not just glossy surfaces.
- At least 6 item sockets and 4 hazard sockets exist.
- Mist effect is present but does not make the route unreadable.
- Signature perfume or hairdryer effect is present and testable.
- Elevated pedestal/ramp sections have camera clearance and reset coverage.
