# Bedroom Stage Build Spec

Stage: Bedroom / Tuggs
Owner faction: The Soft Room
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as Tuggs' protected waiting refuge. The family will return is the central belief here: every visible route section should feel cleaned, preserved, and guarded.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoutePoints`: closed loop route markers.
- `Checkpoints`: 5-7 markers, with the first marker or a clearly named lap marker acting as the lap gate.
- `ItemSockets`: 6-10 item marker sockets.
- `HazardSockets`: 4-8 hazard marker sockets.
- `ShortcutGates`: one blanket-fold or under-bed shortcut if readable.
- `Dressing`: visible props using `StagePropAuthoring` or scene instances.
- `SurfaceSegments`: at least rug/carpet, blanket, and hard toy-block sections.
- `AudioZones`: at least lamp refuge, plush thump, and blanket slide zones.

## Route Direction

Build a soft but restrictive loop that starts near the bedside-lamp beacon, climbs or skirts a bed ramp, passes through a blanket tunnel, crosses rug lanes, passes the toy triage corner, and returns past the waiting line of preserved toys.

Keep lanes warm and readable, but make barriers feel protective. Shortcuts should feel like slipping out of safety rather than random hidden paths.

## Visible Objects

Required visible landmarks:

- `BedRamp`
- `BlanketTunnel`
- `BedsideLampBeacon`
- `ToyTriageCorner`
- `WaitingLine`
- `ToyBlockBarriers`

Use existing furniture/toy props where practical. If boxes are used, color and name them as specific soft-room objects so human reviewers can read the stage intent.

## Hazards And Simple Behavior

- Blanket folds: soft walls or partial visual occluders with forgiving collision.
- Rug lanes: slow or grip-change surface segment if surface behavior exists; otherwise visual-only but named.
- Toy block barriers: static hazards with clear collision.
- Under-bed or blanket shortcut: narrow but camera-safe.

## Signature Effect

Implement one Bedroom effect hook:

- Preferred: `LampBeaconZone` using a warm visible light, subtle pulse, and `AudioZoneAuthoring`.
- Acceptable alternative: `BlanketPulseZone` with soft particle/light feedback when racers pass through the blanket tunnel.

## Acceptance Checklist

- Closed route validates with 5-7 checkpoints and 8 spawns.
- Lap target is roughly 30 seconds for a competent local player.
- Tuggs' family-will-return belief is visible through `WaitingLine`, `ToyTriageCorner`, and protected route dressing.
- At least 6 item sockets and 4 hazard sockets exist.
- Blanket tunnel has enough clearance for kart and camera.
- Signature lamp or blanket effect is present and testable.
- No route section traps the player against soft barriers without reset coverage.
