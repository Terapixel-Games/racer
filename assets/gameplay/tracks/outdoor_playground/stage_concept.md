# Outdoor Playground Stage Concept

Stage: Outdoor Playground / Dash  
Faction: The Open Run  
Reference image: `stage_key_art.png`

## Identity

The Outdoor Playground is the open-route faction's proving ground. Dash rejects waiting, display, and fixed borders, so this stage is built from ramps, rails, slides, swings, chalk markings, and border-breaking shortcuts.

The stage should feel fast, exposed, and kinetic. It is clean and bright, not abandoned or decayed.

## Lore Purpose

The Open Run argues that toys should stop waiting to be chosen. Movement itself is the answer. Dash's faction opens routes others try to close.

The stage teaches the cost of freedom: open roads create possibility, but they do not protect toys who cannot keep up.

## Visual Read

- Pristine outdoor play surfaces: clean slide, swing, rails, chalk marks, bright molded plastic.
- Toy-scale route language: half-pipes, ramps, rail lines, drop routes, open-air jumps.
- Faction modifications: broken-border gates, route arrows, improvised ramp connectors.
- Mood: fast, risky, cool, exposed, defiant.

## Route Fantasy

The race should feel like momentum is everything. Drivers take slide drops, thread swing hazards, hit half-pipe bank turns, launch open-air jumps, and choose risky rail-adjacent shortcuts.

Shortcuts should feel like rule-breaking: routes that ignore borders and reward commitment.

## Hero Landmarks

- Slide drop into a high-speed straight.
- Swing hazard with moving or implied pendulum risk.
- Chalk route arrows across the surface.
- Rail grind or rail-adjacent section.
- Broken-border gate connecting two areas.

## Hazards And Beats

- Swing crossing: timing hazard or visual pressure.
- Slide drop: speed boost and landing control.
- Half-pipe bank: wide stunt turn.
- Rail section: narrow shortcut line.
- Shortcut: border-break ramp over a blocked route.

## Materials And Mood

- Materials: blacktop or clean outdoor surface, molded plastic, metal chains/rails, chalk, painted wood.
- Lighting: bright outdoor light, crisp shadows.
- Palette: sky blue, bright yellow/red plastic, chalk white, Dash blue accents.
- Audio mood: outdoor air, chain swing, slide drop, stunt whoosh, fast breakbeat.

## Meshy Prompts

- "Stylized toy-scale outdoor playground slide drop for an arcade kart track, bright clean molded plastic, open-route faction, readable driving path, no humans, no text, modular GLB-friendly."
- "Toy racing swing gate hazard, clean outdoor playground, metal chains and plastic seat, readable pass-through route, no logos, no people."
- "Broken-border stunt gate with chalk arrows and rail ramps, toy kart racing playground, fast open route, low-poly game asset."

## Blender Tasks

- Separate slide, swing gate, rail ramps, half-pipe pieces, and chalk-arrow decals.
- Keep moving-hazard pieces pivot-ready for Godot animation.
- Create simple collision for slide and half-pipe curves.
- Ensure chain/swing details are readable without excessive geometry.
- Prepare modular ramp connections to existing track pieces.

## Godot Build Notes

- Animate swing hazard as separate node if used interactively.
- Tune slide drop landing to avoid camera clipping and reset problems.
- Use decals or simple planes for chalk arrows.
- Keep open-air jumps readable with clear landing zones.
- Do not overuse thin rails as collision; provide forgiving helper collision.

