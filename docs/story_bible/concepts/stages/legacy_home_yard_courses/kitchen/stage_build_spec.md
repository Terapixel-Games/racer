# Kitchen Stage Build Spec

Stage: Kitchen / Sir Clink
Owner faction: The Kitchen Court
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as a lawful kitchen race court. The first playable blockout should use visible stage objects, imported props where available, and authored marker groups. Avoid marker-only or gray-box-only layouts.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoutePoints`: closed loop route markers.
- `Checkpoints`: 5-7 markers, with the first marker or a clearly named lap marker acting as the lap gate.
- `ItemSockets`: 6-10 item marker sockets.
- `HazardSockets`: 4-8 hazard marker sockets.
- `ShortcutGates`: one shortcut pair when the cutting-board bridge or sink-side bypass is present.
- `Dressing`: visible props using `StagePropAuthoring` or scene instances.
- `SurfaceSegments`: at least countertop/tile, wet sink, and metal/utensil sections.
- `AudioZones`: at least sink splash, utensil clink, and kitchen clatter zones.

## Route Direction

Build a compact ceremonial loop that starts at a court gate, runs along tile/counter space, crosses a cutting-board bridge, skims the sink gauntlet, passes utensil rails, and returns through cabinet-court pillars.

Keep the layout readable and formal. Turns may be tight, but entries must be visible early enough for a first-time player to react.

## Visible Objects

Required visible landmarks:

- `CourtStartGate`
- `SinkGauntlet`
- `CuttingBoardBridge`
- `UtensilRail`
- `CabinetCourt`
- `TournamentFinishArch`

Use existing kitchen/furniture/food assets where practical. Godot-authored visible box props are acceptable only when named, colored, and scaled to represent the intended object.

## Hazards And Simple Behavior

- Sink splash zone: visual water surface plus `AudioZoneAuthoring`; simple first pass can trigger water feedback when near named sink nodes.
- Utensil hazards: static or lightly animated visible props; collision may be simple static helpers.
- Fruit/cup clutter: bumpable-looking dressing; gameplay collision may be static until tuned.
- Cutting-board shortcut: faster, narrower line with clear guard rails and reset-safe edges.

## Signature Effect

Implement at least one working Kitchen effect hook:

- Preferred: `SinkSplashZone` plus `SinkWater`, matching current Kitchen naming so water-drop feedback can be discovered.
- Optional companion: stove or pan heat source named so runtime heat distortion can discover it using the existing heat-source convention.

## Acceptance Checklist

- Closed route validates with 5-7 checkpoints and 8 spawns.
- Lap target is roughly 30 seconds for a competent local player.
- Stage has visible Kitchen Court landmarks, not only markers.
- At least 6 item sockets and 4 hazard sockets exist.
- One shortcut exists and is readable before entry.
- Sink splash or heat distortion effect is present and testable.
- No tunnel, bridge, or sink edge causes camera clipping or missing reset coverage.
