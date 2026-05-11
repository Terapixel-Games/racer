# Circuit Collapse Racer (Godot 4.x)

Arcade Ridge Racer-like multiplayer prototype powered by Nakama. Default backend: `https://nakama-qxqz.onrender.com`.

## Run the client
- Open `project.godot` in Godot 4.x.
- Ensure autoloads are active (`Config`, `NakamaService`, `Nakama`).
- Run the project (main scene `scenes/MainMenu.tscn`).
- Controls: WASD/Arrow keys to drive, Space to drift, Shift to boost. Mobile shows on-screen buttons.
- Two instances: start two editor play sessions to join the same lobby and verify countdown reset (<10s -> resets to 10).

## Multiplayer flow
- MainMenu -> Single Race or Tournament -> Level Select. The unified selector chooses both racer and track, then opens either the local race or the Nakama lobby path.
- Lobby RPC `racer_online_join_or_create` creates or joins a fresh online session with a room code, session id, lobby match id, mode, selected track ids, and current standings.
- Single race uses one validated track from `assets/gameplay/tracks/track_packages.json`; tournament uses the same lobby group across four unique tracks.
- Race scene joins the returned race match id, drives locally, and sends pose/progress input. Nakama owns session phase, finish ordering, tournament points, and canonical snapshots.
- The v1 authority model is hybrid validated: clients simulate cars, while Nakama rejects invalid session state/backward progress and broadcasts race completion/results.

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
- Active runtime modules live in `backend/nakama/modules/index.js`.
- Online race RPCs:
  - `racer_online_join_or_create`
  - `racer_online_session_state`
- Online match handlers:
  - `racer_online_lobby`
  - `racer_online_race`
- Legacy Lua modules under `nakama/modules/` are not the active online race path.

### Local dev (Docker)
- `cd backend/nakama`
- `docker-compose up --build`
- Modules auto-mounted into `/nakama/data/modules`.
- Point client to localhost by setting `Config.override_host = "127.0.0.1"` in the Godot editor or at runtime.

### Render deployment notes
- Ensure Nakama image copies `backend/nakama/modules` into `/nakama/data/modules`:
  ```dockerfile
  COPY backend/nakama/modules /nakama/data/modules
  ENTRYPOINT ["/bin/sh","-ecx","/nakama/nakama migrate up --database.address $DATABASE && exec /nakama/nakama --runtime.path /nakama/data/modules --logger.level INFO"]
  ```
- Rebuild and redeploy the Render service so the Lua modules are packaged.
- Console: https://nakama-qxqz.onrender.com/console/

## Known limitations
- Server-side driving physics and checkpoint layout are simplified placeholders; race logic is progression-based rather than geometry-aware.
- Snapshots are coarse; smoothing/position ordering is minimal.
- AI drivers follow simple linear progress.
