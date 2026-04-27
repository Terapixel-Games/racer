# Meshy Asset Pipeline

## Goal
Use Meshy for first-pass 3D production inputs that follow the approved Figma package, then clean up and integrate those assets in Godot.

## Batch Order
1. Character base models
2. Kart bodies
3. Launch-track hero landmarks
4. Hazard and shortcut props
5. Item pickup props

## Character Prompt Families

### Rexx
- toy plastic dinosaur racer
- chunky molded plastic body
- aggressive toy silhouette
- kart built from bite bumper, tread wheels, fossil decals

### Moko
- plush gorilla toy racer
- jungle guardian energy
- handmade wood and vine kart body

### Tuggs
- teddy bear bruiser racer
- soft but jealous energy
- pillow-padded bruiser kart

### Popper
- jack-in-the-box clown racer
- crooked spring-loaded toy chassis
- prank menace silhouette

### Sir Clink
- molded plastic knight toy racer
- self-important heroic pose
- shield-and-lance kart motifs

### Slammo
- wrestler action toy racer
- loud championship branding
- ring-rope and belt buckle details

### Velva
- glam doll racer
- vanity toy styling
- boutique glossy kart surfaces

### Dash
- bootleg action figure stunt racer
- cheap chrome and molded vents
- playground stunt-kart silhouette

## Launch Track Landmark Batches

### Bedroom
- bedframe tunnel
- blanket drift ridge
- toy chest shortcut entrance

### Kitchen
- table and chair leg gauntlet
- sink splash zone
- toaster hazard prop

### Garden
- stepping stone lane
- hose crossing
- root bridge shortcut

### Outdoor Playground
- slide drop
- seesaw ramp
- swing hazard module

## Integration Rules
- Generate modular props, not full monolithic tracks.
- Author race routes and collisions in Godot.
- Keep prompt and version history per asset family.
- Treat Meshy output as source material for cleanup, not final untouched geometry.
