# Playroom Stage Build Spec

Stage: Playroom / Slammo
Owner faction: The Arena
Concept reference: `stage_concept.md` and `stage_key_art.png`

## Build Target

Create a playable Godot-authored stage scene that reads as Slammo's champion arena. The route should be loud, staged, and competitive, with visible arena dressing and toy-sports pageantry.

Target pacing: one competent local lap should take about 30 seconds. A 3-lap race should land near 90 seconds before lobby/results flow.

## Required Scene Structure

- `RoadGridMap`: source of truth for route cells, checkpoints, start tile, and 8 generated spawns.
- `StageInteractions`: explicit `StageInteractionAuthoring` areas for `ChampionRampBurst` and `MarbleMachineRumble`.
- `Dressing`: named `StagePropAuthoring` markers for every visible landmark and route beat.
- `RoomShell`: floor, side walls, rear wall, front opening treatment, and ceiling with no visible leaks.
- `Lighting`: named arena and champion-ramp lights; keep spectacle outside collision-critical lanes.
- `AudioZones`: at least crowd energy, marble machine, and champion ramp zones where available.

Do not use legacy `RoutePoints`, `ItemSockets`, `HazardSockets`, or `RoadSegments` for this stage.

## Route Direction

Build a title-match loop around a central toy ring platform. The route should pass block grandstands, climb a champion ramp, dodge or frame a marble machine hazard, and finish along a trophy stretch.

The stage should encourage spectacle without sacrificing readability. Keep crowd dressing outside the collision-critical lane.

## Visible Objects

Required visible landmarks:

- `ToyRingPlatform`
- `ChampionRamp`
- `BlockGrandstands`
- `MarbleMachine`
- `TrophyFinishStretch`
- `ArenaLoop`

Use existing toy car, marble, block, or furniture props where practical. Banners should use shapes/colors, not readable text.

## Hazards And Simple Behavior

- Marble machine: visible moving or timed hazard; simple release/rolling path is enough for first pass.
- Block stacks: static collision or bumpable-looking hazards.
- Champion ramp: stunt beat with safe landing.
- Arena loop: broad readable turn.
- Showboat shortcut: faster but riskier line through a ramp or grandstand edge.

## Signature Effect

Implement one Playroom effect hook:

- Preferred: `MarbleMachine` with visible moving/rolling marbles or a timed release effect.
- Acceptable alternative: `ChampionRampBurst` with particles/light/audio when racers hit the ramp.

## Acceptance Checklist

- Closed route validates with 5-7 checkpoints and 8 spawns.
- Lap target is roughly 30 seconds for a competent local player.
- Stage has visible Arena landmarks and toy-sports pageantry.
- No legacy item or hazard sockets exist; route pressure is authored through `StageInteractions`.
- Marble or ramp effect is present and testable.
- Crowd/arena dressing does not obscure route, checkpoints, or finish line.
- Showboat shortcut is readable before commitment.
