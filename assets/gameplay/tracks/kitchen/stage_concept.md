# Kitchen Stage Concept

Stage: Kitchen / Sir Clink  
Faction: The Kitchen Court  
Reference image: `stage_key_art.png`

## Identity

The Kitchen is the house's lawful domestic kingdom. Sir Clink's faction has turned a pristine kitchen into a sanctioned race court built from tile, utensils, counters, cabinets, gates, polished banners, and ceremonial start/finish markings.

This stage should feel controlled at first glance: clean lanes, clear borders, courtly dressing, and tournament arches. The danger comes from the kitchen's ordinary objects being repurposed as official hazards.

## Lore Purpose

The Kitchen Court believes the old game must be governed. Every race here is a legal proceeding. The stage teaches that order can protect toys from chaos, but also that law can become punishment.

Sir Clink's court uses this room to validate race law, settle border arguments, and demonstrate that sanctioned conflict is better than direct toy-breaking war.

## Visual Read

- Pristine kitchen surfaces: clean tile, bright counters, spotless sink, arranged cabinets.
- Toy-scale route language: modular road, miniature gates, banners, lane dividers, utensils used as rails.
- Faction modifications: court emblems, polished tournament arches, ranked spectator toys, legal checkpoint markers.
- Mood: ceremonial, heroic, controlled, slightly oppressive.

## Route Fantasy

The race should feel like a formal tournament that gets more dangerous as speed rises. Drivers pass through clean sanctioned lanes, cut across a cutting-board bridge, skim a sink splash zone, dodge utensil rails, and dive between cabinet-court pillars.

The best shortcuts should feel "legal but risky": narrow court-approved routes that reward precision rather than disorder.

## Hero Landmarks

- Sink gauntlet with splash hazard and metal rim turn.
- Cabinet court with vertical cabinet walls, drawer balconies, and toy spectators.
- Cutting-board bridge over a lower tile lane.
- Utensil rail section using spoon, fork, and knife silhouettes as lane edge language.
- Tournament finish gate dressed like a toy court arch.

## Hazards And Beats

- Utensil clink hazards: moving or static spoon/fork/knife obstacles.
- Sink splash zone: water-effect hazard or slick surface.
- Fruit and cup clutter: bumpable hazards near counter routes.
- Court gates: clean checkpoint arches that frame the sanctioned path.
- Shortcut: narrow cutting-board line with minimal guard rails.

## Materials And Mood

- Materials: tile, molded metal, glossy plastic, fruit skin, polished wood/cutting board.
- Lighting: bright kitchen overhead light, clean reflections, no grime.
- Palette: warm tile neutrals, silver metal, Sir Clink gold, court red accents.
- Audio mood: utensil clinks, sink splash, plate impacts, heroic toy-brass stings.

## Meshy Prompts

- "Stylized low-poly toy-scale kitchen tournament arch, molded plastic and toy metal, clean pristine kitchen court theme, no text, no logos, modular GLB-friendly shape, readable from a racing camera."
- "Toy-scale sink gauntlet landmark for an arcade kart track, pristine kitchen sink rim, splash hazard zone, heroic knight court dressing, clean materials, no characters, no text."
- "Miniature cabinet court set for toy racing, clean kitchen cabinets as castle-like walls, drawer balconies, polished toy banners without text, modular landmark pieces."

## Blender Tasks

- Split custom landmarks into modular arch, sink rim, cabinet wall, and utensil rail pieces.
- Normalize scale to existing track route metrics and snap points.
- Create simple collision helper meshes separate from visual meshes.
- Reduce decorative geometry that does not affect silhouette from race camera.
- Keep material slots clean: tile, metal, plastic, wood, accent.

## Godot Build Notes

- Author route, checkpoints, and lap triggers in Godot; do not rely on generated mesh collision.
- Keep sink, cutting-board, and utensil hazards as separate nodes for tuning.
- Use simple collision boxes/ramps for counters, rails, and bridge edges.
- Ensure all shortcut entries are readable before the turn, not hidden behind dressing.
- Budget shiny materials carefully for mobile renderer performance.

