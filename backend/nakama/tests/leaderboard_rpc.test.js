// Backend smoke tests for the pure parts of the Racer Nakama module.

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function run() {
  const backend = require("../modules/index.js");
  assert(backend.normalizeOnlineMode("online_tournament") === "tournament", "online tournament should normalize");
  assert(backend.normalizeOnlineRoomCode(" ab-12 ") === "AB12", "room code should normalize");
  const single = backend.selectOnlineTrackIds("single_race", "sandbox");
  assert(single.length === 1 && single[0] === "sandbox", "single race should select requested track");
  const tournament = backend.selectOnlineTrackIds("tournament", "attic");
  assert(tournament.length === 4 && tournament[0] === "attic", "tournament should select four tracks");
  const points = backend.awardOnlinePoints([{ racer_id: "Dash" }, { racer_id: "Rexx" }], { Rexx: 3 });
  assert(points.Dash === 15 && points.Rexx === 15, "points should accumulate by finish order");
  assert(backend.acceptOnlineProgress({ progress: 2 }, { progress: 3 }) === true, "forward progress should pass");
  assert(backend.acceptOnlineProgress({ progress: 3 }, { progress: 2 }) === false, "backward progress should fail");
  const build = backend.sanitizeRacerBuildDocument(
    {
      build_id: "Kitchen Ramp!",
      home_map_id: "home_yard_v3",
      display_name: "Kitchen Ramp",
      piece_library_version: "home_builder_v1",
      pieces: [
        { piece_id: "endpoint", cell: [0, 0, 0], yaw_steps: 0 },
        { piece_id: "straight", cell: [1, 0, 0], yaw_steps: 1 },
      ],
      navigation_status: "navigation_valid",
      race_status: "invalid",
    },
    "user-a",
    "session-a"
  );
  assert(build.build_id === "kitchen_ramp_", "build id should sanitize");
  assert(build.scope === "lobby" && build.scope_session_id === "session-a", "published builds should be lobby scoped");
  assert(backend.validateRacerBuildDocument(build).ok === true, "valid curated build should pass validation");
  const badBuild = backend.sanitizeRacerBuildDocument(
    {
      home_map_id: "unknown_map",
      piece_library_version: "remote_assets",
      pieces: [{ piece_id: "remote_mesh", cell: [0, 0, 0] }],
    },
    "user-a",
    "session-a"
  );
  assert(backend.validateRacerBuildDocument(badBuild).ok === false, "unsupported maps and libraries should fail validation");
  console.log("racer nakama online smoke tests passed");
}

if (require.main === module) {
  run();
}

module.exports = { run };
