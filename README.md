# Circuit Collapse Racer (Godot 4.x)

Arcade Ridge Racer-like multiplayer prototype powered by Nakama. Default backend: `https://nakama-qxqz.onrender.com`.

## Run the client
- Open `project.godot` in Godot 4.x.
- Ensure autoloads are active (`Config`, `NakamaService`, `Nakama`).
- Run the project (main scene `scenes/MainMenu.tscn`).
- Controls: WASD/Arrow keys to drive, Space to drift, Shift to boost. Mobile shows on-screen buttons.
- Two instances: start two editor play sessions to join the same lobby and verify countdown reset (<10s -> resets to 10).

## Multiplayer flow
- MainMenu -> Play connects to Nakama and opens Lobby.
- Lobby RPC `lobby_join_or_create` returns a room code and match id; clients join the lobby match.
- Countdown auto-starts when at least one human is present; a new joiner under 10s resets the timer to 10s.
- Race scene joins the provided race match id, spawns cars (AI fill to 8), streams inputs (20 Hz) and receives snapshots (15 Hz).
- Wasted: falling behind triggers a wasted message; Wasted screen offers return to lobby.
- Finish: when all non-wasted racers finish 2 laps, PostRace shows results and can loop back to Lobby or Menu.

## Tests (GDUnit4)
- Tests live under `tests/`.
- From Godot, run GDUnit4 test explorer for:
  - `test_room_code_generator.gd`
  - `test_lobby_countdown_reset.gd`
  - `test_late_join_state_machine.gd`
  - `test_checkpoint_validation.gd`
  - `test_wasted_timer.gd`
- Pure logic under `scripts/logic/` keeps tests scene-free.

## Nakama server runtime modules
- Lua modules live in `nakama/modules/`:
  - `main.lua` RPC registration (`lobby_join_or_create`)
  - `lobby.lua` lobby match handler with countdown/reset rules
  - `race_match.lua` race handler with AI fill, progress, wasted, snapshots
  - `room_code.lua` generator

### Local dev (Docker)
- `cd nakama`
- `docker-compose up --build`
- Modules auto-mounted into `/nakama/data/modules`.
- Point client to localhost by setting `Config.override_host = "127.0.0.1"` in the Godot editor or at runtime.

### Render deployment notes
- Ensure Nakama image copies modules into `/nakama/data/modules`:
  ```dockerfile
  COPY nakama/modules /nakama/data/modules
  ENTRYPOINT ["/bin/sh","-ecx","/nakama/nakama migrate up --database.address $DATABASE && exec /nakama/nakama --runtime.path /nakama/data/modules --logger.level INFO"]
  ```
- Rebuild and redeploy the Render service so the Lua modules are packaged.
- Console: https://nakama-qxqz.onrender.com/console/

## Known limitations
- Server-side driving physics and checkpoint layout are simplified placeholders; race logic is progression-based rather than geometry-aware.
- Snapshots are coarse; smoothing/position ordering is minimal.
- AI drivers follow simple linear progress.
