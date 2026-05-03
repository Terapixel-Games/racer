# Generic Front Door Loss

Character: Selected player character  
Environment: Front door / house exterior  
Runtime Target: 4-6 seconds  
Tone: Comedic, fast, lightly humiliating, arcade-cartoon timing

## Purpose

This is the shared losing ending for story cups and track packs. Character-specific endings are reserved for first-place wins. If the player does not place first, the game plays this reusable loss vignette with the selected player character.

## Cinematic Setup

The camera faces a cozy front door from just outside the house. The selected player character bursts out through the doorway in a quick comedic tumble or shove, skids to a stop on the porch or walkway, then looks back as the door slams shut. The slam lands as the final punctuation beat.

The scene should feel like a punchline, not a punishment. Keep the timing snappy and readable on mobile: clear silhouette, simple camera move, strong door-slam audio, and one short character reaction.

## Story Logic

| Condition | Ending |
|---|---|
| Player places first | Play the selected character's win cinematic. |
| Player places second or lower | Play `generic_front_door_loss`. |
| Race result is missing or invalid | Fall back to `generic_front_door_loss`. |

## Beat Sheet

| Beat | Time | Action | Camera | Audio |
|---|---:|---|---|---|
| LOSS_001 | 00:00.00 | Front door cracks open or bursts open. | Locked or slight push-in on door. | Door latch, quick impact setup. |
| LOSS_002 | 00:00.60 | Selected character flies/tumbles/slides out. | Follow character slightly, keep door visible. | Comedic whoosh, slide, small character exertion. |
| LOSS_003 | 00:02.00 | Character stops outside and reacts back toward the door. | Settle into medium shot. | Short groan, gasp, or muttered reaction. |
| LOSS_004 | 00:03.20 | Door slams shut hard. | Tiny shake on slam, then hold. | Big door slam, quick silence after. |
| LOSS_005 | 00:04.20 | Character blinks, dusts off, or gives a defeated look. | Hold for readable final pose. | Optional sting or tiny VO tag. |

## Voice-Over Cue Sheet

| Cue | Time | Speaker | Emotion | Line | Direction | File |
|---|---:|---|---|---|---|---|
| VO_001 | 00:02.10 | Player Character | Stunned | "Okay. That felt personal." | Short, dry, recovering from impact. | generic_front_door_loss_vo_001.wav |
| VO_002 | 00:04.30 | Player Character | Deflated | "I was leaving anyway." | Small comedic save after the door slam. | generic_front_door_loss_vo_002.wav |

## Alternate Lines

### VO_001 Alternatives

| Alt | Line | Direction |
|---|---|---|
| A | "Yep. Door still works." | Deadpan, slightly dazed. |
| B | "I meant to do that." | False confidence, quick recovery. |
| C | "Ow. Fair enough." | Soft defeat, no bitterness. |

### VO_002 Alternatives

| Alt | Line | Direction |
|---|---|---|
| A | "Best two out of three?" | Hopeful, tiny beat after slam. |
| B | "Next cup. Different door." | Determined but still funny. |
| C | "Nobody saw that, right?" | Embarrassed, quick glance at camera. |

## Director Notes

- Keep the read short enough to fit after the physical gag.
- The slam should be the biggest beat; VO should not cover it unless intentionally mixed under.
- Delivery should be character-neutral for v1 so the same script can work across all playable racers.
- Avoid mean-spirited embarrassment. The character should bounce back quickly.

## Implementation Notes

- Runtime id: `generic_front_door_loss`
- Ending type: shared loss vignette
- Character source: selected player character
- Trigger: player placement is not first
- Recommended system: ArcadeCore vignette framework with a racer-local front-door set
- Door, floor, porch, and exterior cards can be shared across every character.
- Character-specific loss barks can be added later without changing the resolver.
