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
  console.log("racer nakama online smoke tests passed");
}

if (require.main === module) {
  run();
}

module.exports = { run };
