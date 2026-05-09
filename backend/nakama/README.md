# Racer Nakama Backend

The active Racer online multiplayer runtime is `modules/index.js`. The current v1 flow is a fresh JS Nakama implementation for single races and same-lobby four-track tournaments; legacy Lua modules under the repo-level `nakama/modules/` directory are not part of this path.

RPCs:

- `racer_online_join_or_create`: create/join a room-code or public-fill online session.
- `racer_online_session_state`: read the current session state by `session_id` or `room_code`.

Match handlers:

- `racer_online_lobby`: lobby state, countdown, race start.
- `racer_online_race`: hybrid-validated race input, snapshots, finish ordering, results, tournament standings.

Message op codes are defined in `scripts/NetMessages.gd`; payloads include `schema_version`, `session_id`, `mode`, `round_index`, `track_id`, `track_ids`, `players`, `racers`, `progress`, `finish_time`, and tournament `points`.

Local development:

1. `cd backend/nakama`
2. Set platform env values in `local.yml` (or leave stubs for offline work).
3. `docker compose up --build`

Ports:

- API/socket: `http://localhost:7350`
- Console: `http://localhost:7351` (`admin` / `adminpassword`)

Render deployment:

- Uses `backend/nakama/Dockerfile.render`
- Uses root `render.yaml`
- `render/start.sh` runs migrations, starts Nakama, and reverse proxies console under `/console/`.
