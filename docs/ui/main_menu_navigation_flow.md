# Main Menu Navigation Flow

This document is the working contract for the racer menu flow.

## Metadata Keys

| Key | Owner | Values / Shape | Purpose |
|---|---|---|---|
| `nav_flow_mode` | UI navigation | `single_race`, `tournament`, or empty | Carries the high-level flow between main menu, character select, level select, race, and endings. |
| `selected_racer_id` | Character select | Racer roster id | Locked-in player character. Card selection writes this immediately. |
| `race_flow` | Multiplayer routing | `single_multiplayer`, `tournament_multiplayer` | Tells lobby/matchmaking what kind of multiplayer session the player requested. |
| `race_mode` | Race runtime | `local_single`, `local_tournament` | Tells `Race.tscn` whether to run one local race or a tournament round. |
| `track_id` | Track selection / tournament | Track catalog id | Current track to spawn. |
| `track_recipe` | Track selection / tournament | Track metadata dictionary | Runtime track metadata for current race. |
| `tournament_track_ids` | Tournament setup | Array of track ids | The four-track local tournament route. |
| `tournament_round_index` | Tournament runtime | Zero-based int | Current tournament round. |
| `tournament_points` | Tournament runtime | Dictionary keyed by racer id | Cumulative tournament score. |
| `tournament_standings` | Tournament runtime | Sorted array | Current sorted standings for results and endings. |
| `placeholder_ending_id` | Placeholder endings | String | Temporary ending identifier until final cinematics exist. |

## Screen Flow

### Single Race Local

1. `MainMenu.tscn`
2. Player chooses `Single Race`.
3. Main menu writes `nav_flow_mode = "single_race"`.
4. Route to `CharacterSelect.tscn`.
5. Character card selection writes `selected_racer_id`.
6. Player chooses `Local`.
7. Route to `LevelSelect.tscn`.
8. Level select writes `race_mode = "local_single"`, `track_id`, `track_recipe`, and `race_match_id`.
9. Route to `Race.tscn`.

### Single Race Multiplayer

1. `MainMenu.tscn`
2. Player chooses `Single Race`.
3. Character select locks `selected_racer_id`.
4. Player chooses `Multiplayer`.
5. Character select writes `race_flow = "single_multiplayer"`.
6. Route to `Lobby.tscn`.

### Tournament Local

1. `MainMenu.tscn`
2. Player chooses `Tournament`.
3. Main menu writes `nav_flow_mode = "tournament"`.
4. Route to `CharacterSelect.tscn`.
5. Character card selection writes `selected_racer_id`.
6. Player chooses `Local`.
7. Character select randomly selects up to four unique tracks.
8. Character select writes tournament state and first round track metadata.
9. Route to `Race.tscn`.
10. Race results award points and show `Next Race` until the final round.
11. Final round shows `Finish Tournament`.
12. Finish routes to a temporary win or shared front-door loss placeholder.

### Tournament Multiplayer

1. `MainMenu.tscn`
2. Player chooses `Tournament`.
3. Character select locks `selected_racer_id`.
4. Player chooses `Multiplayer`.
5. Character select writes `race_flow = "tournament_multiplayer"`.
6. Route to `Lobby.tscn`.

Backend sequencing for multiplayer tournaments is future work. The UI only writes intent metadata for now.

## Back Behavior

| Screen | Back Target | Metadata Behavior |
|---|---|---|
| Main menu | None | Root screen. |
| Character select | Main menu | Clears `nav_flow_mode`. |
| Level select from single race | Character select | Preserves `nav_flow_mode = "single_race"`. |
| Local race results, single race | Level select | Keeps single-race flow. |
| Local race results, tournament | Main menu secondary action | Leaves tournament metadata available until a new flow starts. |
| Placeholder ending | Main menu | Clears `nav_flow_mode`. |

## UI Notes

- The main menu owns the race vignette background and chooses a random preview track on load.
- Character select is the mode confirmation surface. There is no separate local/multiplayer menu scene.
- Racer selection is immediate lock-in; `Local` and `Multiplayer` use the currently selected card.
- Placeholder ending scenes are flow targets only. Final cinematic production can replace their scene paths later without changing the upstream navigation contract.
