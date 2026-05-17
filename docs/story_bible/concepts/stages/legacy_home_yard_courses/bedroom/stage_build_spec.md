# Bedroom Stage Build Spec

Stage: Bedroom / Tuggs
Owner faction: The Soft Room
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as Tuggs' protected waiting refuge. The family will return is the central belief here: every visible route section should feel cleaned, preserved, and guarded.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoadGridMap`: source of truth for route cells, checkpoints, start tile, and 8 generated spawns.
- `StageInteractions`: explicit `StageInteractionAuthoring` areas for `LampBeaconBoostZone` and `RugGripSlowZone`.
- `Dressing`: named `StagePropAuthoring` markers for every visible landmark and route beat.
- `RoomShell`: floor, side walls, rear wall, front opening treatment, and ceiling with no visible leaks.
- `Lighting`: named warm refuge and route-read lights; keep them visually supported by fixtures or the room.
- `AudioZones`: at least lamp refuge, plush thump, and blanket slide zones where available.

Do not use legacy `RoutePoints`, `ItemSockets`, `HazardSockets`, or `RoadSegments` for this stage.

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

- Preferred: `LampBeaconBoostZone` using a warm visible light, subtle pulse, and deterministic boost behavior.
- Acceptable alternative: `BlanketPulseZone` with soft particle/light feedback when racers pass through the blanket tunnel.

## Acceptance Checklist

- Closed route validates with 5-7 checkpoints and 8 spawns.
- Lap target is roughly 30 seconds for a competent local player.
- Tuggs' family-will-return belief is visible through `WaitingLine`, `ToyTriageCorner`, and protected route dressing.
- No legacy item or hazard sockets exist; route pressure is authored through `StageInteractions`.
- Blanket tunnel has enough clearance for kart and camera.
- Signature lamp or blanket effect is present and testable.
- No route section traps the player against soft barriers without reset coverage.
