var DEFAULT_USERNAME_CHANGE_COST_COINS = 300;
var DEFAULT_USERNAME_CHANGE_COOLDOWN_SECONDS = 300;
var DEFAULT_USERNAME_CHANGE_MAX_PER_DAY = 3;
var ACCOUNT_COLLECTION = "account";
var MAGIC_LINK_STATUS_KEY = "magic_link_status";
var MAGIC_LINK_PENDING_KEY = "magic_link_pending";
var MAGIC_LINK_EMAIL_LOOKUP_KEY_PREFIX = "magic_link_email_lookup_";
var MAGIC_LINK_PROFILE_LOOKUP_KEY_PREFIX = "magic_link_profile_lookup_";
var MAGIC_LINK_NOTIFY_REPLAY_KEY = "magic_link_notify_replay";
var USERNAME_STATE_KEY = "username_state";
var EMAIL_MAX_LENGTH = 320;
var MAGIC_LINK_TOKEN_MAX_LENGTH = 512;
var SYSTEM_USER_ID = "00000000-0000-0000-0000-000000000000";
var DEFAULT_MAGIC_LINK_NOTIFY_MAX_SKEW_SECONDS = 600;
var MAX_MAGIC_LINK_NOTIFY_REPLAY_ENTRIES = 2048;
var ONLINE_SCHEMA_VERSION = 1;
var ONLINE_MODE_SINGLE_RACE = "single_race";
var ONLINE_MODE_TOURNAMENT = "tournament";
var ONLINE_PHASE_LOBBY = "lobby";
var ONLINE_PHASE_RACING = "racing";
var ONLINE_PHASE_COMPLETE = "complete";
var ONLINE_MAX_RACERS = 8;
var ONLINE_LOBBY_COUNTDOWN_SECONDS = 20;
var ONLINE_TOURNAMENT_ROUND_COUNT = 4;
var ONLINE_POINTS_BY_PLACE = [15, 12, 10, 8, 6, 4, 2, 1];
var ONLINE_TRACKS = [
  { id: "kitchen", displayName: "Kitchen / Sir Clink", version: "kitchen_v2_2026_04_29" },
  { id: "attic", displayName: "Attic Mayhem", version: "attic_gridmap_v1_2026_05_09" },
  { id: "bedroom", displayName: "Bedroom / Tuggs", version: "bedroom_gridmap_v1_2026_05_09" },
  { id: "garden", displayName: "Garden / Moko", version: "garden_gridmap_v1_2026_05_09" },
  { id: "glam_closet", displayName: "Glam Closet / Velva", version: "glam_closet_gridmap_v1_2026_05_09" },
  { id: "outdoor_playground", displayName: "Outdoor Playground / Dash", version: "outdoor_playground_gridmap_v1_2026_05_09" },
  { id: "playroom", displayName: "Playroom / Slammo", version: "playroom_gridmap_v1_2026_05_09" },
  { id: "sandbox", displayName: "Sandbox / Rexx", version: "sandbox_gridmap_v1_2026_05_09" },
];
var ONLINE_SESSIONS = {};
var ONLINE_ROOM_INDEX = {};

var MODULE_CONFIG = {
  gameId: "",
  leaderboardId: "",
  platformIdentityUrl: "",
  platformUsernameValidateUrl: "",
  platformAccountMagicLinkStartUrl: "",
  platformAccountMagicLinkCompleteUrl: "",
  platformAccountMergeCodeUrl: "",
  platformAccountMergeRedeemUrl: "",
  platformTelemetryEventsUrl: "",
  platformInternalKey: "",
  magicLinkNotifySecret: "",
  magicLinkNotifyRequireTimestamp: true,
  magicLinkNotifyMaxSkewSeconds: DEFAULT_MAGIC_LINK_NOTIFY_MAX_SKEW_SECONDS,
  usernameChangeCostCoins: DEFAULT_USERNAME_CHANGE_COST_COINS,
  usernameChangeCooldownSeconds: DEFAULT_USERNAME_CHANGE_COOLDOWN_SECONDS,
  usernameChangeMaxPerDay: DEFAULT_USERNAME_CHANGE_MAX_PER_DAY,
};

function InitModule(ctx, logger, nk, initializer) {
  MODULE_CONFIG = loadConfig(ctx);
  initializer.registerRpc("platform_auth_exchange", rpcPlatformAuthExchange);
  initializer.registerRpc("platform_username_validate", rpcPlatformUsernameValidate);
  initializer.registerRpc("tpx_account_magic_link_start", rpcAccountMagicLinkStart);
  initializer.registerRpc("tpx_account_magic_link_complete", rpcAccountMagicLinkComplete);
  initializer.registerRpc("tpx_account_magic_link_status", rpcAccountMagicLinkStatus);
  initializer.registerRpc("tpx_account_magic_link_notify", rpcAccountMagicLinkNotify);
  initializer.registerRpc("tpx_account_merge_code", rpcAccountMergeCode);
  initializer.registerRpc("tpx_account_merge_redeem", rpcAccountMergeRedeem);
  initializer.registerRpc("tpx_account_username_status", rpcAccountUsernameStatus);
  initializer.registerRpc("tpx_account_update_username", rpcAccountUpdateUsername);
  initializer.registerRpc("tpx_client_event_track", rpcClientEventTrack);
  initializer.registerRpc("racer_online_join_or_create", rpcRacerOnlineJoinOrCreate);
  initializer.registerRpc("racer_online_session_state", rpcRacerOnlineSessionState);
  initializer.registerMatch("racer_online_lobby", {
    matchInit: racerLobbyMatchInit,
    matchJoinAttempt: racerMatchJoinAttempt,
    matchJoin: racerLobbyMatchJoin,
    matchLeave: racerLobbyMatchLeave,
    matchLoop: racerLobbyMatchLoop,
    matchTerminate: racerMatchTerminate,
    matchSignal: racerMatchSignal,
  });
  initializer.registerMatch("racer_online_race", {
    matchInit: racerRaceMatchInit,
    matchJoinAttempt: racerMatchJoinAttempt,
    matchJoin: racerRaceMatchJoin,
    matchLeave: racerRaceMatchLeave,
    matchLoop: racerRaceMatchLoop,
    matchTerminate: racerMatchTerminate,
    matchSignal: racerMatchSignal,
  });
  logger.info("ArcadeCore Nakama template module loaded for game=%s", MODULE_CONFIG.gameId);
}

function loadConfig(ctx) {
  var env = (ctx && ctx.env) || {};
  var gameId = String(env.GAME_ID || "").trim().toLowerCase();
  return {
    gameId: gameId,
    leaderboardId: String(env.LEADERBOARD_ID || (gameId + "_high_scores")).trim().toLowerCase(),
    platformIdentityUrl: String(env.PLATFORM_IDENTITY_URL || "").trim(),
    platformUsernameValidateUrl: String(env.PLATFORM_USERNAME_VALIDATE_URL || "").trim(),
    platformAccountMagicLinkStartUrl: String(
      env.PLATFORM_ACCOUNT_MAGIC_LINK_START_URL || env.TPX_PLATFORM_MAGIC_LINK_START_URL || ""
    ).trim(),
    platformAccountMagicLinkCompleteUrl: String(
      env.PLATFORM_ACCOUNT_MAGIC_LINK_COMPLETE_URL || env.TPX_PLATFORM_MAGIC_LINK_COMPLETE_URL || ""
    ).trim(),
    platformAccountMergeCodeUrl: String(
      env.PLATFORM_ACCOUNT_MERGE_CODE_URL || env.TPX_PLATFORM_ACCOUNT_MERGE_CODE_URL || ""
    ).trim(),
    platformAccountMergeRedeemUrl: String(
      env.PLATFORM_ACCOUNT_MERGE_REDEEM_URL || env.TPX_PLATFORM_ACCOUNT_MERGE_REDEEM_URL || ""
    ).trim(),
    platformTelemetryEventsUrl: String(
      env.PLATFORM_TELEMETRY_EVENTS_URL || env.PLATFORM_TELEMETRY_URL || ""
    ).trim(),
    platformInternalKey: String(env.PLATFORM_INTERNAL_KEY || "").trim(),
    magicLinkNotifySecret: String(env.TPX_MAGIC_LINK_NOTIFY_SECRET || env.MAGIC_LINK_NOTIFY_SECRET || "").trim(),
    magicLinkNotifyRequireTimestamp: toBool(env.TPX_MAGIC_LINK_NOTIFY_REQUIRE_TIMESTAMP, true),
    magicLinkNotifyMaxSkewSeconds: Math.max(
      30,
      toInt(env.TPX_MAGIC_LINK_NOTIFY_MAX_SKEW_SECONDS, DEFAULT_MAGIC_LINK_NOTIFY_MAX_SKEW_SECONDS)
    ),
    usernameChangeCostCoins: toInt(env.USERNAME_CHANGE_COST_COINS, DEFAULT_USERNAME_CHANGE_COST_COINS),
    usernameChangeCooldownSeconds: toInt(env.USERNAME_CHANGE_COOLDOWN_SECONDS, DEFAULT_USERNAME_CHANGE_COOLDOWN_SECONDS),
    usernameChangeMaxPerDay: toInt(env.USERNAME_CHANGE_MAX_PER_DAY, DEFAULT_USERNAME_CHANGE_MAX_PER_DAY),
  };
}

function rpcPlatformAuthExchange(ctx, logger, nk, payload) {
  var data = parsePayload(payload);
  var nakamaUserId = String(data.nakama_user_id || ctx.userId || "").trim();
  if (!nakamaUserId) {
    throw new Error("nakama_user_id is required");
  }
  if (!MODULE_CONFIG.platformIdentityUrl) {
    throw new Error("PLATFORM_IDENTITY_URL is required");
  }
  var response = nk.httpRequest(
    MODULE_CONFIG.platformIdentityUrl + "/v1/auth/nakama",
    "post",
    {
      "Content-Type": "application/json",
    },
    JSON.stringify({
      game_id: MODULE_CONFIG.gameId,
      nakama_user_id: nakamaUserId,
      display_name: String(data.display_name || ctx.username || "").trim(),
    }),
    5000,
    false
  );
  if (response.code < 200 || response.code >= 300) {
    throw new Error("platform auth exchange failed");
  }
  return response.body || "{}";
}

function rpcPlatformUsernameValidate(ctx, logger, nk, payload) {
  var data = parsePayload(payload);
  var username = String(data.username || "").trim();
  if (!username) {
    throw new Error("username is required");
  }
  if (!MODULE_CONFIG.platformUsernameValidateUrl || !MODULE_CONFIG.platformInternalKey) {
    throw new Error("username validation endpoint is not configured");
  }
  var response = nk.httpRequest(
    MODULE_CONFIG.platformUsernameValidateUrl,
    "post",
    {
      "Content-Type": "application/json",
      "x-admin-key": MODULE_CONFIG.platformInternalKey,
    },
    JSON.stringify({
      game_id: MODULE_CONFIG.gameId,
      username: username,
    }),
    5000,
    false
  );
  if (response.code < 200 || response.code >= 300) {
    throw new Error("platform username moderation failed");
  }
  return response.body || "{}";
}

function rpcAccountMagicLinkStart(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);
  var data = parsePayload(payload);
  var email = sanitizeEmailAddress(data.email || "");
  if (!email) {
    throw new Error("valid email is required");
  }
  if (!MODULE_CONFIG.platformAccountMagicLinkStartUrl) {
    throw new Error("PLATFORM_ACCOUNT_MAGIC_LINK_START_URL is required");
  }
  clearMagicLinkStatus(nk, ctx.userId);
  writeMagicLinkPending(nk, ctx.userId, {
    email: email,
    startedAt: Math.floor(Date.now() / 1000),
  });
  writeMagicLinkLookupByEmail(nk, email, ctx.userId);
  var platformSession = exchangePlatformSession(ctx, nk);
  var response = httpPost(
    nk,
    MODULE_CONFIG.platformAccountMagicLinkStartUrl,
    {
      email: email,
      game_id: MODULE_CONFIG.gameId,
      nakama_user_id: ctx.userId,
    },
    {},
    platformSession
  );
  if (response.code < 200 || response.code >= 300) {
    throw new Error("failed to start magic link: " + extractHttpErrorDetail(response));
  }
  return JSON.stringify(parseHttpBodyJson(response.body) || { ok: true });
}

function rpcAccountMagicLinkComplete(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);
  var data = parsePayload(payload);
  var token = sanitizeMagicLinkToken(data.ml_token || data.magic_link_token || "");
  if (!token) {
    throw new Error("ml_token is required");
  }
  if (!MODULE_CONFIG.platformAccountMagicLinkCompleteUrl) {
    throw new Error("PLATFORM_ACCOUNT_MAGIC_LINK_COMPLETE_URL is required");
  }
  var platformSession = exchangePlatformSession(ctx, nk);
  var response = httpPost(
    nk,
    MODULE_CONFIG.platformAccountMagicLinkCompleteUrl,
    {
      ml_token: token,
    },
    {},
    platformSession
  );
  if (response.code < 200 || response.code >= 300) {
    throw new Error("failed to complete magic link: " + extractHttpErrorDetail(response));
  }
  return JSON.stringify(parseHttpBodyJson(response.body) || {});
}

function rpcAccountMagicLinkStatus(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);
  var data = parsePayload(payload);
  var clearAfterRead = data.clear_after_read === undefined ? true : !!data.clear_after_read;
  var status = readMagicLinkStatus(nk, ctx.userId);
  if (!status) {
    return JSON.stringify({
      pending: true,
      completed: false,
    });
  }
  if (clearAfterRead) {
    clearMagicLinkStatus(nk, ctx.userId);
    clearMagicLinkPending(nk, ctx.userId);
    if (status.email) {
      var statusEmail = sanitizeEmailAddress(status.email || "");
      if (statusEmail) {
        clearMagicLinkLookupByEmail(nk, statusEmail);
      }
    }
  }
  return JSON.stringify({
    pending: false,
    completed: true,
    status: status.status || "",
    email: status.email || "",
    primaryProfileId: status.primaryProfileId || "",
    secondaryProfileId: status.secondaryProfileId || "",
    completedAt: toInt(status.completedAt, 0),
    source: "platform_callback",
  });
}

function rpcAccountMagicLinkNotify(ctx, logger, nk, payload) {
  var data = {};
  try {
    data = parsePayload(payload);
  } catch (err) {
    logger.warn("magic_link_notify rejected: invalid payload err=%s", String(err || ""));
    throw err;
  }
  var expectedSecret =
    String(MODULE_CONFIG.magicLinkNotifySecret || "").trim() ||
    String((ctx && ctx.env && ctx.env.TPX_MAGIC_LINK_NOTIFY_SECRET) || "").trim();
  if (!expectedSecret) {
    logger.error("magic_link_notify rejected: notify secret is not configured (env=TPX_MAGIC_LINK_NOTIFY_SECRET)");
    throw new Error("magic link notify secret is not configured (set TPX_MAGIC_LINK_NOTIFY_SECRET)");
  }
  var providedSecret = String(data.secret || "").trim();
  if (!providedSecret || !secureEquals(providedSecret, expectedSecret)) {
    throw new Error("invalid notify secret");
  }
  var replayValidation = validateMagicLinkNotifyReplay(nk, data);
  if (!replayValidation.ok) {
    throw new Error(replayValidation.error || "invalid notify request");
  }
  var incomingEmail = "";
  var rawNotifyEmail = String(data.email || "").trim();
  if (rawNotifyEmail) {
    incomingEmail = sanitizeEmailAddress(rawNotifyEmail);
    if (!incomingEmail) {
      throw new Error("valid email is required");
    }
  }
  var resolved = resolveMagicLinkNotifyTarget(nk, data, incomingEmail);
  var userId = resolved.userId;
  if (!userId) {
    throw new Error("nakama_user_id is required");
  }
  var incomingGameId = String(data.game_id || data.gameId || "").trim().toLowerCase();
  if (incomingGameId && incomingGameId !== String(MODULE_CONFIG.gameId || "").trim().toLowerCase()) {
    throw new Error("game_id mismatch");
  }
  var status = String(data.status || data.link_status || "").trim().toLowerCase();
  if (!status) {
    throw new Error("status is required");
  }
  var row = {
    status: status,
    email: incomingEmail,
    primaryProfileId: String(data.primary_profile_id || data.primaryProfileId || "").trim(),
    secondaryProfileId: String(data.secondary_profile_id || data.secondaryProfileId || "").trim(),
    completedAt: toInt(data.completed_at || data.completedAt, Math.floor(Date.now() / 1000)),
    receivedAt: Math.floor(Date.now() / 1000),
  };
  writeMagicLinkStatus(nk, userId, row);
  clearMagicLinkPending(nk, userId);
  if (row.email) {
    clearMagicLinkLookupByEmail(nk, row.email);
  }
  return JSON.stringify({
    ok: true,
    userId: userId,
    status: row.status,
  });
}

function rpcAccountMergeCode(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);
  if (!MODULE_CONFIG.platformAccountMergeCodeUrl) {
    throw new Error("PLATFORM_ACCOUNT_MERGE_CODE_URL is required");
  }
  var platformSession = exchangePlatformSession(ctx, nk);
  var response = httpPost(
    nk,
    MODULE_CONFIG.platformAccountMergeCodeUrl,
    {},
    {},
    platformSession
  );
  if (response.code < 200 || response.code >= 300) {
    throw new Error("failed to create merge code: " + extractHttpErrorDetail(response));
  }
  var parsed = parseHttpBodyJson(response.body);
  return JSON.stringify({
    merge_code: parsed.merge_code || "",
    expires_at: parsed.expires_at || 0,
  });
}

function rpcAccountMergeRedeem(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);
  if (!MODULE_CONFIG.platformAccountMergeRedeemUrl) {
    throw new Error("PLATFORM_ACCOUNT_MERGE_REDEEM_URL is required");
  }
  var data = parsePayload(payload);
  var code = String(data.merge_code || data.code || "").trim().toUpperCase();
  if (!code) {
    throw new Error("merge_code is required");
  }
  var platformSession = exchangePlatformSession(ctx, nk);
  var response = httpPost(
    nk,
    MODULE_CONFIG.platformAccountMergeRedeemUrl,
    {
      merge_code: code,
    },
    {},
    platformSession
  );
  if (response.code < 200 || response.code >= 300) {
    throw new Error("failed to redeem merge code: " + extractHttpErrorDetail(response));
  }
  var parsed = parseHttpBodyJson(response.body);
  return JSON.stringify({
    ok: parsed.ok === true,
    status: String(parsed.status || "").trim(),
    primaryProfileId: String(parsed.primary_profile_id || parsed.primaryProfileId || "").trim(),
    secondaryProfileId: String(parsed.secondary_profile_id || parsed.secondaryProfileId || "").trim(),
    mergedAt: toInt(parsed.merged_at || parsed.mergedAt, 0),
  });
}

function rpcAccountUsernameStatus(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);
  var state = readUsernameState(nk, ctx.userId, ctx.username || "");
  return JSON.stringify(buildUsernameStatusResponse(state));
}

function rpcAccountUpdateUsername(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);
  var data = parsePayload(payload);
  var requested = String(data.username || "").trim();
  var normalized = sanitizeRequestedUsername(requested);
  if (!normalized) {
    throw new Error("username must be 3-20 characters and use letters, numbers, _ or -");
  }
  var moderation = validateUsernameModeration(nk, normalized);
  if (!moderation.allowed) {
    throw new Error("username is not allowed");
  }
  var state = readUsernameState(nk, ctx.userId, ctx.username || "");
  var now = Math.floor(Date.now() / 1000);
  var cooldownSeconds = Math.max(0, toInt(MODULE_CONFIG.usernameChangeCooldownSeconds, DEFAULT_USERNAME_CHANGE_COOLDOWN_SECONDS));
  if (cooldownSeconds > 0 && toInt(state.lastChangedAt, 0) > 0) {
    var nextAllowedAt = toInt(state.lastChangedAt, 0) + cooldownSeconds;
    if (nextAllowedAt > now) {
      throw new Error("username change cooldown active");
    }
  }
  var maxPerDay = Math.max(1, toInt(MODULE_CONFIG.usernameChangeMaxPerDay, DEFAULT_USERNAME_CHANGE_MAX_PER_DAY));
  var windowStartAt = toInt(state.changeWindowStartAt, 0);
  var windowCount = Math.max(0, toInt(state.changeWindowCount, 0));
  if (windowStartAt <= 0 || (now - windowStartAt) >= 86400) {
    windowStartAt = now;
    windowCount = 0;
  }
  if (windowCount >= maxPerDay) {
    throw new Error("username change daily limit reached");
  }
  var currentNormalized = sanitizeRequestedUsername(state.currentUsername || "");
  if (normalized === currentNormalized) {
    return JSON.stringify({
      ok: true,
      changed: false,
      username: state.currentUsername || normalized,
      coinCost: 0,
      reason: "same_username",
      usernamePolicy: buildUsernameStatusResponse(state),
    });
  }
  try {
    nk.accountUpdateId(ctx.userId, normalized, null, null, null, null, null, null);
  } catch (err) {
    var message = String(err || "");
    if (message.toLowerCase().indexOf("already") >= 0 || message.toLowerCase().indexOf("exists") >= 0) {
      throw new Error("username is already taken");
    }
    throw new Error("failed to update username");
  }
  state.currentUsername = normalized;
  state.hasUsedFreeChange = true;
  state.changeCount = Math.max(0, toInt(state.changeCount, 0)) + 1;
  state.lastChangedAt = now;
  state.changeWindowStartAt = windowStartAt;
  state.changeWindowCount = windowCount + 1;
  writeUsernameState(nk, ctx.userId, state);
  return JSON.stringify({
    ok: true,
    changed: true,
    username: normalized,
    coinCost: 0,
    usernamePolicy: buildUsernameStatusResponse(state),
  });
}

function rpcClientEventTrack(ctx, logger, nk, payload) {
  if (!ctx || !ctx.userId) {
    throw new Error("user session is required");
  }
  if (!MODULE_CONFIG.platformTelemetryEventsUrl) {
    return JSON.stringify({
      accepted: false,
      reason: "PLATFORM_TELEMETRY_EVENTS_URL is not configured"
    });
  }
  var data = parsePayload(payload);
  var eventName = normalizeEventName(data.event_name || data.eventName || "");
  if (!eventName) {
    throw new Error("event_name is required");
  }
  var eventTime = toInt(
    data.event_time || data.eventTime,
    Math.floor(Date.now() / 1000)
  );
  var properties = ensurePlainObject(data.properties, {});
  properties.nakama_user_id = String(ctx.userId || "").trim();
  properties.nakama_username = String(ctx.username || "").trim();
  properties.game_id = MODULE_CONFIG.gameId;
  var seq = toInt(data.seq, -1);
  var eventRow = {
    event_name: eventName,
    event_time: eventTime,
    properties
  };
  if (seq >= 0) {
    eventRow.seq = seq;
  }

  var platformSession = exchangePlatformSession(ctx, nk);
  var response = nk.httpRequest(
    MODULE_CONFIG.platformTelemetryEventsUrl,
    "post",
    {
      "Content-Type": "application/json",
      Authorization: "Bearer " + platformSession
    },
    JSON.stringify({
      game_id: MODULE_CONFIG.gameId,
      profile_id: String(ctx.userId || "").trim(),
      session_id: String(data.session_id || data.sessionId || "").trim(),
      events: [eventRow]
    }),
    5000,
    false
  );
  if (response.code < 200 || response.code >= 300) {
    throw new Error("platform telemetry ingest failed");
  }
  return JSON.stringify({
    accepted: true,
    event_name: eventName
  });
}

function rpcRacerOnlineJoinOrCreate(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);
  var data = parsePayload(payload);
  var mode = normalizeOnlineMode(data.mode || data.race_mode || ONLINE_MODE_SINGLE_RACE);
  var roomCode = normalizeOnlineRoomCode(data.room_code || data.roomCode || "");
  var session = null;
  if (roomCode) {
    var existingId = ONLINE_ROOM_INDEX[roomCode];
    if (!existingId || !ONLINE_SESSIONS[existingId]) {
      throw new Error("room code was not found");
    }
    session = ONLINE_SESSIONS[existingId];
    if (session.phase !== ONLINE_PHASE_LOBBY) {
      throw new Error("race already started");
    }
    if (session.mode !== mode) {
      throw new Error("room mode mismatch");
    }
  } else {
    session = findOpenOnlineSession(mode);
    if (!session) {
      session = createOnlineSession(ctx, nk, mode, data);
    }
  }
  var selectedRacerId = sanitizeOnlineId(data.selected_racer_id || data.racer_id || "Racer", "Racer");
  upsertOnlinePlayer(session, ctx.userId, selectedRacerId, data.racer_display_name || selectedRacerId, false);
  if (!session.lobbyMatchId) {
    session.lobbyMatchId = nk.matchCreate("racer_online_lobby", { session_id: session.sessionId });
  }
  return JSON.stringify(buildOnlineSessionPayload(session));
}

function rpcRacerOnlineSessionState(ctx, logger, nk, payload) {
  assertAuthenticated(ctx);
  var data = parsePayload(payload);
  var sessionId = String(data.session_id || data.sessionId || "").trim();
  var roomCode = normalizeOnlineRoomCode(data.room_code || data.roomCode || "");
  var session = sessionId ? ONLINE_SESSIONS[sessionId] : null;
  if (!session && roomCode) {
    session = ONLINE_SESSIONS[ONLINE_ROOM_INDEX[roomCode]];
  }
  if (!session) {
    throw new Error("online session was not found");
  }
  return JSON.stringify(buildOnlineSessionPayload(session));
}

function createOnlineSession(ctx, nk, mode, data) {
  var sessionId = newOnlineSessionId();
  var roomCode = newOnlineRoomCode();
  var requestedTrackId = sanitizeTrackId(data.track_id || data.trackId || "");
  var trackIds = selectOnlineTrackIds(mode, requestedTrackId);
  var session = {
    sessionId: sessionId,
    roomCode: roomCode,
    mode: mode,
    phase: ONLINE_PHASE_LOBBY,
    hostUserId: String(ctx.userId || ""),
    lobbyMatchId: "",
    raceMatchId: "",
    players: {},
    playerOrder: [],
    trackIds: trackIds,
    roundIndex: 0,
    points: {},
    results: [],
    countdown: ONLINE_LOBBY_COUNTDOWN_SECONDS,
    startedAtTick: 0,
    completedAtTick: 0,
    tournamentComplete: false,
  };
  ONLINE_SESSIONS[sessionId] = session;
  ONLINE_ROOM_INDEX[roomCode] = sessionId;
  return session;
}

function buildOnlineSessionPayload(session) {
  var trackId = currentOnlineTrackId(session);
  return {
    schema_version: ONLINE_SCHEMA_VERSION,
    session_id: session.sessionId,
    room_code: session.roomCode,
    mode: session.mode,
    phase: session.phase,
    match_id: session.lobbyMatchId || "",
    race_match_id: session.raceMatchId || "",
    round_index: session.roundIndex,
    track_id: trackId,
    track_ids: session.trackIds.slice(0),
    track: onlineTrackMetadata(trackId),
    players: onlinePlayerList(session),
    countdown: session.countdown,
    points: copyPlainObject(session.points),
    standings: sortedOnlineStandings(session.points),
    results: session.results.slice(0),
  };
}

function racerLobbyMatchInit(ctx, logger, nk, params) {
  var sessionId = String((params && (params.session_id || params.sessionId)) || "").trim();
  var session = ONLINE_SESSIONS[sessionId];
  return {
    state: { session_id: sessionId },
    tickRate: 1,
    label: session ? "racer:" + session.roomCode + ":" + session.mode : "racer:missing",
  };
}

function racerRaceMatchInit(ctx, logger, nk, params) {
  var sessionId = String((params && (params.session_id || params.sessionId)) || "").trim();
  var session = ONLINE_SESSIONS[sessionId];
  return {
    state: { session_id: sessionId },
    tickRate: 15,
    label: session ? "racer-race:" + session.roomCode + ":" + currentOnlineTrackId(session) : "racer-race:missing",
  };
}

function racerMatchJoinAttempt(ctx, logger, nk, dispatcher, tick, state, presence, metadata) {
  var session = ONLINE_SESSIONS[String(state.session_id || "")];
  return { state: state, accept: !!session };
}

function racerLobbyMatchJoin(ctx, logger, nk, dispatcher, tick, state, presences) {
  var session = ONLINE_SESSIONS[String(state.session_id || "")];
  if (!session) {
    return { state: state };
  }
  broadcastLobbyState(dispatcher, session);
  return { state: state };
}

function racerLobbyMatchLeave(ctx, logger, nk, dispatcher, tick, state, presences) {
  var session = ONLINE_SESSIONS[String(state.session_id || "")];
  if (!session) {
    return { state: state };
  }
  for (var i = 0; i < presences.length; i++) {
    var userId = String(presences[i].userId || "");
    if (session.players[userId]) {
      session.players[userId].connected = false;
    }
  }
  broadcastLobbyState(dispatcher, session);
  return { state: state };
}

function racerLobbyMatchLoop(ctx, logger, nk, dispatcher, tick, state, messages) {
  var session = ONLINE_SESSIONS[String(state.session_id || "")];
  if (!session) {
    return { state: state };
  }
  if (session.phase !== ONLINE_PHASE_LOBBY) {
    return { state: state };
  }
  var humanCount = onlineHumanPlayerCount(session);
  if (humanCount > 0) {
    session.countdown = Math.max(0, Number(session.countdown || ONLINE_LOBBY_COUNTDOWN_SECONDS) - 1);
  }
  if (session.countdown <= 0) {
    ensureOnlineCpuFill(session);
    session.phase = ONLINE_PHASE_RACING;
    session.raceMatchId = nk.matchCreate("racer_online_race", { session_id: session.sessionId });
    broadcastLobbyRaceStart(dispatcher, session);
    return { state: state };
  }
  broadcastLobbyState(dispatcher, session);
  return { state: state };
}

function racerRaceMatchJoin(ctx, logger, nk, dispatcher, tick, state, presences) {
  var session = ONLINE_SESSIONS[String(state.session_id || "")];
  if (!session) {
    return { state: state };
  }
  for (var i = 0; i < presences.length; i++) {
    var userId = String(presences[i].userId || "");
    if (session.players[userId]) {
      session.players[userId].connected = true;
    }
  }
  broadcastRaceSnapshot(dispatcher, session);
  return { state: state };
}

function racerRaceMatchLeave(ctx, logger, nk, dispatcher, tick, state, presences) {
  var session = ONLINE_SESSIONS[String(state.session_id || "")];
  if (!session) {
    return { state: state };
  }
  for (var i = 0; i < presences.length; i++) {
    var userId = String(presences[i].userId || "");
    if (session.players[userId]) {
      session.players[userId].connected = false;
    }
  }
  broadcastRaceSnapshot(dispatcher, session);
  return { state: state };
}

function racerRaceMatchLoop(ctx, logger, nk, dispatcher, tick, state, messages) {
  var session = ONLINE_SESSIONS[String(state.session_id || "")];
  if (!session) {
    return { state: state };
  }
  for (var i = 0; i < messages.length; i++) {
    handleOnlineRaceMessage(session, messages[i], tick);
  }
  if (session.phase === ONLINE_PHASE_RACING && onlineRaceIsComplete(session)) {
    finalizeOnlineRace(session, tick);
    broadcastRaceComplete(dispatcher, session);
  } else {
    broadcastRaceSnapshot(dispatcher, session);
  }
  return { state: state };
}

function racerMatchTerminate(ctx, logger, nk, dispatcher, tick, state, graceSeconds) {
  return { state: state };
}

function racerMatchSignal(ctx, logger, nk, dispatcher, tick, state, data) {
  return { state: state, data: data };
}

function handleOnlineRaceMessage(session, message, tick) {
  if (!message || Number(message.opCode || 0) !== 10) {
    return;
  }
  var sender = message.sender || {};
  var userId = String(sender.userId || "");
  var player = session.players[userId];
  if (!player || player.isCpu) {
    return;
  }
  var payload = parsePayload(message.data || "{}");
  var input = payload.input && typeof payload.input === "object" ? payload.input : payload;
  var previous = player.race || {};
  var incoming = {
    pos: numericArray(input.position, 3, previous.pos || [0, 1, 0]),
    rot: numericArray(input.rotation, 3, previous.rot || [0, 0, 0]),
    lap: Math.max(1, toInt(input.lap, previous.lap || 1)),
    checkpoint: Math.max(0, toInt(input.checkpoint, previous.checkpoint || 0)),
    checkpoints: Math.max(1, toInt(input.checkpoints, previous.checkpoints || 1)),
    progress: Math.max(0, Number(input.progress || previous.progress || 0)),
    finished: !!input.finished,
    wasted: !!input.wasted,
    finish_time: Number(input.finish_time || previous.finish_time || -1),
    updated_at_tick: tick,
  };
  if (!acceptOnlineProgress(previous, incoming)) {
    return;
  }
  if (incoming.lap > 2 || incoming.finished) {
    incoming.finished = true;
    incoming.finish_time = previous.finish_time >= 0 ? previous.finish_time : Math.max(0, tick - Number(session.startedAtTick || tick));
  }
  player.race = incoming;
}

function finalizeOnlineRace(session, tick) {
  session.phase = ONLINE_PHASE_COMPLETE;
  session.completedAtTick = tick;
  session.results = onlineResultList(session);
  session.tournamentComplete = false;
  if (session.mode === ONLINE_MODE_TOURNAMENT) {
    session.points = awardOnlinePoints(session.results, session.points);
    if (session.roundIndex + 1 >= session.trackIds.length) {
      session.tournamentComplete = true;
    } else {
      session.roundIndex += 1;
      session.phase = ONLINE_PHASE_LOBBY;
      session.countdown = ONLINE_LOBBY_COUNTDOWN_SECONDS;
      session.raceMatchId = "";
      resetOnlineRaceStates(session);
    }
  }
}

function onlineRaceIsComplete(session) {
  var humans = onlinePlayerList(session).filter(function (p) { return !p.is_cpu; });
  if (humans.length <= 0) {
    return false;
  }
  for (var i = 0; i < humans.length; i++) {
    var player = session.players[humans[i].id];
    if (!player || !player.race || (!player.race.finished && !player.race.wasted)) {
      return false;
    }
  }
  return true;
}

function broadcastLobbyState(dispatcher, session) {
  dispatcher.broadcastMessage(1, JSON.stringify(buildOnlineSessionPayload(session)), null, null, true);
}

function broadcastLobbyRaceStart(dispatcher, session) {
  var payload = buildOnlineSessionPayload(session);
  dispatcher.broadcastMessage(2, JSON.stringify(payload), null, null, true);
}

function broadcastRaceSnapshot(dispatcher, session) {
  var payload = buildOnlineSessionPayload(session);
  payload.checkpoints = maxRaceCheckpointCount(session);
  payload.racers = onlineRacerSnapshot(session);
  dispatcher.broadcastMessage(11, JSON.stringify(payload), null, null, false);
}

function broadcastRaceComplete(dispatcher, session) {
  var payload = buildOnlineSessionPayload(session);
  payload.checkpoints = maxRaceCheckpointCount(session);
  payload.racers = onlineRacerSnapshot(session);
  payload.results = session.results;
  var op = session.mode === ONLINE_MODE_TOURNAMENT && session.tournamentComplete ? 19 : 17;
  dispatcher.broadcastMessage(op, JSON.stringify(payload), null, null, true);
}

function findOpenOnlineSession(mode) {
  var keys = Object.keys(ONLINE_SESSIONS);
  for (var i = 0; i < keys.length; i++) {
    var session = ONLINE_SESSIONS[keys[i]];
    if (session && session.mode === mode && session.phase === ONLINE_PHASE_LOBBY && onlineHumanPlayerCount(session) < ONLINE_MAX_RACERS) {
      return session;
    }
  }
  return null;
}

function upsertOnlinePlayer(session, userId, racerId, displayName, isCpu) {
  var id = String(userId || "").trim();
  if (!id) {
    return;
  }
  if (!session.players[id]) {
    session.playerOrder.push(id);
  }
  session.players[id] = {
    id: id,
    userId: id,
    racerId: sanitizeOnlineId(racerId, "Racer"),
    displayName: sanitizeOnlineDisplayName(displayName || racerId || "Racer"),
    isCpu: !!isCpu,
    connected: true,
    race: session.players[id] && session.players[id].race ? session.players[id].race : defaultOnlineRaceState(),
  };
}

function ensureOnlineCpuFill(session) {
  var roster = ["Dash", "Rexx", "Tuggs", "Moko", "Velva", "Slammo", "Sir Clink", "Racer"];
  var index = 0;
  while (session.playerOrder.length < ONLINE_MAX_RACERS) {
    var id = "cpu_" + String(index + 1);
    upsertOnlinePlayer(session, id, roster[index % roster.length], roster[index % roster.length], true);
    index++;
  }
}

function defaultOnlineRaceState() {
  return {
    pos: [0, 1, 0],
    rot: [0, 0, 0],
    lap: 1,
    checkpoint: 0,
    checkpoints: 1,
    progress: 0,
    finished: false,
    wasted: false,
    finish_time: -1,
    updated_at_tick: 0,
  };
}

function resetOnlineRaceStates(session) {
  var ids = session.playerOrder || [];
  for (var i = 0; i < ids.length; i++) {
    if (session.players[ids[i]]) {
      session.players[ids[i]].race = defaultOnlineRaceState();
    }
  }
}

function onlinePlayerList(session) {
  var out = [];
  for (var i = 0; i < session.playerOrder.length; i++) {
    var player = session.players[session.playerOrder[i]];
    if (!player) {
      continue;
    }
    out.push({
      id: player.id,
      user_id: player.userId,
      name: player.displayName,
      racer_id: player.racerId,
      is_cpu: !!player.isCpu,
      connected: !!player.connected,
    });
  }
  return out;
}

function onlineRacerSnapshot(session) {
  var out = [];
  for (var i = 0; i < session.playerOrder.length; i++) {
    var player = session.players[session.playerOrder[i]];
    if (!player) {
      continue;
    }
    var race = player.race || defaultOnlineRaceState();
    out.push({
      id: player.id,
      user_id: player.userId,
      racer_id: player.racerId,
      is_cpu: !!player.isCpu,
      pos: race.pos || [0, 1, 0],
      rot: race.rot || [0, 0, 0],
      lap: toInt(race.lap, 1),
      checkpoint: toInt(race.checkpoint, 0),
      checkpoints: toInt(race.checkpoints, 1),
      progress: Number(race.progress || 0),
      finished: !!race.finished,
      wasted: !!race.wasted,
      finish_time: Number(race.finish_time || -1),
    });
  }
  return out;
}

function onlineResultList(session) {
  var results = onlineRacerSnapshot(session);
  results.sort(function (a, b) {
    if (!!a.finished !== !!b.finished) {
      return a.finished ? -1 : 1;
    }
    if (!!a.wasted !== !!b.wasted) {
      return a.wasted ? 1 : -1;
    }
    if (a.finished && b.finished && Number(a.finish_time) !== Number(b.finish_time)) {
      return Number(a.finish_time) - Number(b.finish_time);
    }
    if (Number(a.progress) === Number(b.progress)) {
      return String(a.id).localeCompare(String(b.id));
    }
    return Number(b.progress) - Number(a.progress);
  });
  return results;
}

function awardOnlinePoints(results, existingPoints) {
  var points = copyPlainObject(existingPoints || {});
  for (var i = 0; i < results.length; i++) {
    var racerId = sanitizeOnlineId(results[i].racer_id || results[i].id || "", "");
    if (!racerId) {
      continue;
    }
    points[racerId] = toInt(points[racerId], 0) + (ONLINE_POINTS_BY_PLACE[i] || 0);
  }
  return points;
}

function sortedOnlineStandings(points) {
  var out = [];
  var keys = Object.keys(points || {});
  for (var i = 0; i < keys.length; i++) {
    out.push({ racer_id: keys[i], points: toInt(points[keys[i]], 0) });
  }
  out.sort(function (a, b) {
    if (a.points === b.points) {
      return String(a.racer_id).localeCompare(String(b.racer_id));
    }
    return b.points - a.points;
  });
  return out;
}

function normalizeOnlineMode(mode) {
  var text = String(mode || "").trim().toLowerCase();
  if (text === "online_tournament" || text === ONLINE_MODE_TOURNAMENT) {
    return ONLINE_MODE_TOURNAMENT;
  }
  return ONLINE_MODE_SINGLE_RACE;
}

function normalizeOnlineRoomCode(code) {
  return String(code || "").trim().toUpperCase().replace(/[^A-Z0-9]/g, "");
}

function selectOnlineTrackIds(mode, requestedTrackId) {
  var ids = [];
  for (var i = 0; i < ONLINE_TRACKS.length; i++) {
    ids.push(ONLINE_TRACKS[i].id);
  }
  var requested = sanitizeTrackId(requestedTrackId || "");
  if (requested && ids.indexOf(requested) >= 0) {
    ids.splice(ids.indexOf(requested), 1);
    ids.unshift(requested);
  }
  if (normalizeOnlineMode(mode) === ONLINE_MODE_SINGLE_RACE) {
    return [ids[0]];
  }
  return ids.slice(0, Math.min(ONLINE_TOURNAMENT_ROUND_COUNT, ids.length));
}

function currentOnlineTrackId(session) {
  if (!session || !session.trackIds || session.trackIds.length <= 0) {
    return ONLINE_TRACKS[0].id;
  }
  var index = Math.max(0, Math.min(toInt(session.roundIndex, 0), session.trackIds.length - 1));
  return session.trackIds[index];
}

function onlineTrackMetadata(trackId) {
  var id = sanitizeTrackId(trackId || "") || ONLINE_TRACKS[0].id;
  for (var i = 0; i < ONLINE_TRACKS.length; i++) {
    if (ONLINE_TRACKS[i].id === id) {
      return {
        id: ONLINE_TRACKS[i].id,
        track_id: ONLINE_TRACKS[i].id,
        display_name: ONLINE_TRACKS[i].displayName,
        version: ONLINE_TRACKS[i].version,
      };
    }
  }
  return onlineTrackMetadata(ONLINE_TRACKS[0].id);
}

function sanitizeTrackId(value) {
  var id = String(value || "").trim().toLowerCase().replace(/[^a-z0-9_]/g, "");
  for (var i = 0; i < ONLINE_TRACKS.length; i++) {
    if (ONLINE_TRACKS[i].id === id) {
      return id;
    }
  }
  return "";
}

function sanitizeOnlineId(value, fallback) {
  var text = String(value || "").trim();
  if (!text) {
    text = String(fallback || "");
  }
  text = text.replace(/[^A-Za-z0-9 _-]/g, "").trim();
  if (text.length > 32) {
    text = text.substring(0, 32);
  }
  return text || String(fallback || "");
}

function sanitizeOnlineDisplayName(value) {
  var text = sanitizeOnlineId(value, "Racer");
  return text || "Racer";
}

function acceptOnlineProgress(previous, incoming) {
  if (previous && previous.finished) {
    return false;
  }
  if (incoming.finished) {
    return true;
  }
  return Number(incoming.progress || 0) + 0.001 >= Number((previous && previous.progress) || 0);
}

function maxRaceCheckpointCount(session) {
  var max = 1;
  var racers = onlineRacerSnapshot(session);
  for (var i = 0; i < racers.length; i++) {
    max = Math.max(max, toInt(racers[i].checkpoints, 1));
  }
  return max;
}

function onlineHumanPlayerCount(session) {
  var count = 0;
  var players = onlinePlayerList(session);
  for (var i = 0; i < players.length; i++) {
    if (!players[i].is_cpu) {
      count++;
    }
  }
  return count;
}

function newOnlineSessionId() {
  return "ors_" + Date.now().toString(36) + "_" + Math.floor(Math.random() * 0xFFFFFF).toString(36);
}

function newOnlineRoomCode() {
  var alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  for (var attempt = 0; attempt < 20; attempt++) {
    var code = "";
    for (var i = 0; i < 6; i++) {
      code += alphabet[Math.floor(Math.random() * alphabet.length)];
    }
    if (!ONLINE_ROOM_INDEX[code]) {
      return code;
    }
  }
  return "R" + Math.floor(Date.now() % 100000).toString().padStart(5, "0");
}

function numericArray(value, size, fallback) {
  var out = [];
  var source = Array.isArray(value) ? value : fallback || [];
  for (var i = 0; i < size; i++) {
    out.push(Number(source[i] || 0));
  }
  return out;
}

function copyPlainObject(value) {
  var out = {};
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return out;
  }
  var keys = Object.keys(value);
  for (var i = 0; i < keys.length; i++) {
    out[keys[i]] = value[keys[i]];
  }
  return out;
}

function exchangePlatformSession(ctx, nk) {
  if (!MODULE_CONFIG.platformIdentityUrl) {
    throw new Error("PLATFORM_IDENTITY_URL is required");
  }
  var response = nk.httpRequest(
    MODULE_CONFIG.platformIdentityUrl + "/v1/auth/nakama",
    "post",
    {
      "Content-Type": "application/json"
    },
    JSON.stringify({
      game_id: MODULE_CONFIG.gameId,
      nakama_user_id: String((ctx && ctx.userId) || "").trim(),
      display_name: String((ctx && ctx.username) || "").trim()
    }),
    5000,
    false
  );
  if (response.code < 200 || response.code >= 300) {
    throw new Error("platform auth exchange failed");
  }
  var parsed = parsePayload(response.body || "{}");
  var sessionToken = String(parsed.session_token || "").trim();
  if (!sessionToken) {
    throw new Error("platform auth exchange missing session_token");
  }
  var platformProfileId = String(parsed.player_id || parsed.playerId || "").trim();
  if (platformProfileId && ctx && ctx.userId) {
    writeMagicLinkLookupByProfile(nk, platformProfileId, ctx.userId);
  }
  return sessionToken;
}

function parsePayload(payload) {
  if (!payload) {
    return {};
  }
  if (typeof payload === "object" && !Array.isArray(payload)) {
    return payload;
  }
  if (typeof payload !== "string") {
    throw new Error("invalid JSON payload");
  }
  try {
    var parsed = JSON.parse(payload);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      throw new Error("payload must be a JSON object");
    }
    return parsed;
  } catch (_err) {
    throw new Error("invalid JSON payload");
  }
}

function toInt(value, fallback) {
  var parsed = Number(value);
  if (!isFinite(parsed)) {
    return fallback;
  }
  return Math.floor(parsed);
}

function toBool(value, fallback) {
  if (value === null || value === undefined || value === "") {
    return !!fallback;
  }
  var normalized = String(value).trim().toLowerCase();
  if (!normalized) {
    return !!fallback;
  }
  if (normalized === "1" || normalized === "true" || normalized === "yes" || normalized === "on") {
    return true;
  }
  if (normalized === "0" || normalized === "false" || normalized === "no" || normalized === "off") {
    return false;
  }
  return !!fallback;
}

function normalizeEventName(value) {
  var out = String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9._-]/g, "_");
  if (!out) {
    return "";
  }
  if (out.length > 120) {
    out = out.substring(0, 120);
  }
  return out;
}

function ensurePlainObject(value, fallback) {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value;
  }
  return fallback;
}

function assertAuthenticated(ctx) {
  if (!ctx || !ctx.userId) {
    throw new Error("User session is required.");
  }
}

function httpPost(nk, url, body, extraHeaders, bearerToken) {
  var headers = {
    "Content-Type": "application/json",
  };
  if (extraHeaders && typeof extraHeaders === "object") {
    for (var key in extraHeaders) {
      if (Object.prototype.hasOwnProperty.call(extraHeaders, key)) {
        headers[key] = extraHeaders[key];
      }
    }
  }
  if (bearerToken) {
    headers.Authorization = "Bearer " + bearerToken;
  }
  return nk.httpRequest(
    url,
    "post",
    headers,
    JSON.stringify(body || {}),
    5000,
    false
  );
}

function parseHttpBodyJson(body) {
  if (!body) {
    return {};
  }
  var parsed = JSON.parse(body);
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    return {};
  }
  return parsed;
}

function extractHttpErrorDetail(response) {
  var code = toInt(response && response.code, 0);
  var parsed = {};
  try {
    parsed = parseHttpBodyJson(response && response.body);
  } catch (_err) {
    parsed = {};
  }
  var message = "";
  if (parsed && parsed.error && parsed.error.message) {
    message = String(parsed.error.message);
  } else if (parsed && parsed.message) {
    message = String(parsed.message);
  } else if (response && response.body) {
    message = String(response.body);
  }
  message = message.trim();
  if (message.length > 220) {
    message = message.substring(0, 220) + "...";
  }
  if (message) {
    return "[" + code + "] " + message;
  }
  return "status " + code;
}

function magicLinkLookupKeyByEmail(email) {
  var normalized = sanitizeEmailAddress(email || "");
  if (!normalized) {
    return "";
  }
  var digest = stableHashHex(normalized);
  if (!digest) {
    return "";
  }
  return MAGIC_LINK_EMAIL_LOOKUP_KEY_PREFIX + digest;
}

function magicLinkLookupKeyByProfile(profileId) {
  var normalized = String(profileId || "").trim().toLowerCase();
  if (!normalized) {
    return "";
  }
  var safe = normalized.replace(/[^a-z0-9_-]/g, "_");
  if (!safe) {
    return "";
  }
  if (safe.length > 96) {
    safe = safe.substring(0, 96);
  }
  return MAGIC_LINK_PROFILE_LOOKUP_KEY_PREFIX + safe;
}

function writeMagicLinkLookupByEmail(nk, email, userId) {
  var normalizedEmail = sanitizeEmailAddress(email || "");
  if (!normalizedEmail) {
    return;
  }
  clearMagicLinkLookupByEmail(nk, normalizedEmail);
  var key = magicLinkLookupKeyByEmail(normalizedEmail);
  if (!key) {
    return;
  }
  nk.storageWrite([
    {
      collection: ACCOUNT_COLLECTION,
      key: key,
      userId: SYSTEM_USER_ID,
      value: {
        email: normalizedEmail,
        userId: String(userId || "").trim(),
        updatedAt: Math.floor(Date.now() / 1000),
      },
      permissionRead: 0,
      permissionWrite: 0,
    },
  ]);
}

function writeMagicLinkLookupByProfile(nk, profileId, userId) {
  var key = magicLinkLookupKeyByProfile(profileId);
  if (!key) {
    return;
  }
  nk.storageWrite([
    {
      collection: ACCOUNT_COLLECTION,
      key: key,
      userId: SYSTEM_USER_ID,
      value: {
        profileId: String(profileId || "").trim().toLowerCase(),
        userId: String(userId || "").trim(),
        updatedAt: Math.floor(Date.now() / 1000),
      },
      permissionRead: 0,
      permissionWrite: 0,
    },
  ]);
}

function readMagicLinkLookupByEmail(nk, email) {
  var normalized = sanitizeEmailAddress(email || "");
  if (!normalized) {
    return "";
  }
  var key = magicLinkLookupKeyByEmail(normalized);
  var byNewKey = readMagicLinkLookupUserIdByKey(nk, key);
  if (byNewKey) {
    return byNewKey;
  }
  var legacyKey = legacyMagicLinkLookupKeyByEmail(normalized);
  if (legacyKey && legacyKey !== key) {
    return readMagicLinkLookupUserIdByKey(nk, legacyKey);
  }
  return "";
}

function readMagicLinkLookupByProfile(nk, profileId) {
  var key = magicLinkLookupKeyByProfile(profileId);
  if (!key) {
    return "";
  }
  var storage = nk.storageRead([
    {
      collection: ACCOUNT_COLLECTION,
      key: key,
      userId: SYSTEM_USER_ID,
    },
  ]);
  if (storage && storage.length > 0 && storage[0].value) {
    return String(storage[0].value.userId || "").trim();
  }
  return "";
}

function clearMagicLinkLookupByEmail(nk, email) {
  var normalized = sanitizeEmailAddress(email || "");
  if (!normalized) {
    return;
  }
  var key = magicLinkLookupKeyByEmail(normalized);
  deleteMagicLinkLookupByKey(nk, key);
  var legacyKey = legacyMagicLinkLookupKeyByEmail(normalized);
  if (legacyKey && legacyKey !== key) {
    deleteMagicLinkLookupByKey(nk, legacyKey);
  }
}

function readMagicLinkStatus(nk, userId) {
  var storage = nk.storageRead([
    {
      collection: ACCOUNT_COLLECTION,
      key: MAGIC_LINK_STATUS_KEY,
      userId: userId,
    },
  ]);
  if (storage && storage.length > 0 && storage[0].value) {
    return storage[0].value;
  }
  return null;
}

function writeMagicLinkStatus(nk, userId, value) {
  nk.storageWrite([
    {
      collection: ACCOUNT_COLLECTION,
      key: MAGIC_LINK_STATUS_KEY,
      userId: userId,
      value: value || {},
      permissionRead: 0,
      permissionWrite: 0,
    },
  ]);
}

function clearMagicLinkStatus(nk, userId) {
  nk.storageDelete([
    {
      collection: ACCOUNT_COLLECTION,
      key: MAGIC_LINK_STATUS_KEY,
      userId: userId,
    },
  ]);
}

function writeMagicLinkPending(nk, userId, value) {
  nk.storageWrite([
    {
      collection: ACCOUNT_COLLECTION,
      key: MAGIC_LINK_PENDING_KEY,
      userId: userId,
      value: value || {},
      permissionRead: 0,
      permissionWrite: 0,
    },
  ]);
}

function clearMagicLinkPending(nk, userId) {
  nk.storageDelete([
    {
      collection: ACCOUNT_COLLECTION,
      key: MAGIC_LINK_PENDING_KEY,
      userId: userId,
    },
  ]);
}

function resolveMagicLinkNotifyTarget(nk, data, incomingEmail) {
  var explicit = String(data.nakama_user_id || data.nakamaUserId || "").trim();
  if (explicit && isExistingNakamaUserId(nk, explicit)) {
    return { userId: explicit, source: "explicit_nakama_user_id" };
  }
  var profileCandidates = resolveMagicLinkNotifyProfileCandidates(data);
  for (var i = 0; i < profileCandidates.length; i++) {
    var byProfile = readMagicLinkLookupByProfile(nk, profileCandidates[i]);
    var resolvedByProfile = resolveStoredNakamaUserId(nk, byProfile);
    if (resolvedByProfile) {
      return { userId: resolvedByProfile, source: "profile_lookup" };
    }
  }
  for (var j = 0; j < profileCandidates.length; j++) {
    if (isExistingNakamaUserId(nk, profileCandidates[j])) {
      return { userId: profileCandidates[j], source: "profile_field" };
    }
  }
  if (incomingEmail) {
    var byEmail = readMagicLinkLookupByEmail(nk, incomingEmail);
    var resolvedByEmail = resolveStoredNakamaUserId(nk, byEmail);
    if (resolvedByEmail) {
      return { userId: resolvedByEmail, source: "email_lookup" };
    }
  }
  return { userId: "", source: "unresolved" };
}

function resolveMagicLinkNotifyProfileCandidates(data) {
  var candidates = [
    data.profile_id,
    data.profileId,
    data.secondary_profile_id,
    data.secondaryProfileId,
    data.primary_profile_id,
    data.primaryProfileId,
  ];
  var out = [];
  var seen = {};
  for (var i = 0; i < candidates.length; i++) {
    var candidate = String(candidates[i] || "").trim();
    if (!candidate) {
      continue;
    }
    var key = candidate.toLowerCase();
    if (seen[key]) {
      continue;
    }
    seen[key] = true;
    out.push(candidate);
  }
  return out;
}

function resolveStoredNakamaUserId(nk, userId) {
  var candidate = String(userId || "").trim();
  if (!candidate) {
    return "";
  }
  if (isExistingNakamaUserId(nk, candidate)) {
    return candidate;
  }
  if (isLikelyNakamaUserId(candidate)) {
    return candidate;
  }
  return "";
}

function isLikelyNakamaUserId(value) {
  var text = String(value || "").trim();
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(text);
}

function isExistingNakamaUserId(nk, userId) {
  var candidate = String(userId || "").trim();
  if (!isLikelyNakamaUserId(candidate)) {
    return false;
  }
  try {
    var users = nk.usersGetId([candidate]);
    return !!(users && users.length > 0 && users[0] && users[0].id);
  } catch (_err) {
    return false;
  }
}

function readUsernameState(nk, userId, fallbackUsername) {
  var storage = nk.storageRead([
    {
      collection: ACCOUNT_COLLECTION,
      key: USERNAME_STATE_KEY,
      userId: userId,
    },
  ]);
  var value = null;
  if (storage && storage.length > 0 && storage[0].value) {
    value = storage[0].value;
  }
  var currentUsername = String((value && value.currentUsername) || fallbackUsername || "").trim().toLowerCase();
  return {
    currentUsername: currentUsername,
    hasUsedFreeChange: value ? !!value.hasUsedFreeChange : false,
    changeCount: value ? Math.max(0, toInt(value.changeCount, 0)) : 0,
    lastChangedAt: value ? Math.max(0, toInt(value.lastChangedAt, 0)) : 0,
    changeWindowStartAt: value ? Math.max(0, toInt(value.changeWindowStartAt, 0)) : 0,
    changeWindowCount: value ? Math.max(0, toInt(value.changeWindowCount, 0)) : 0,
  };
}

function writeUsernameState(nk, userId, state) {
  nk.storageWrite([
    {
      collection: ACCOUNT_COLLECTION,
      key: USERNAME_STATE_KEY,
      userId: userId,
      value: {
        currentUsername: String(state.currentUsername || "").trim().toLowerCase(),
        hasUsedFreeChange: !!state.hasUsedFreeChange,
        changeCount: Math.max(0, toInt(state.changeCount, 0)),
        lastChangedAt: Math.max(0, toInt(state.lastChangedAt, 0)),
        changeWindowStartAt: Math.max(0, toInt(state.changeWindowStartAt, 0)),
        changeWindowCount: Math.max(0, toInt(state.changeWindowCount, 0)),
      },
      permissionRead: 0,
      permissionWrite: 0,
    },
  ]);
}

function buildUsernameStatusResponse(state) {
  var freeChangeAvailable = !state.hasUsedFreeChange;
  return {
    username: String(state.currentUsername || "").trim().toLowerCase(),
    freeChangeAvailable: freeChangeAvailable,
    nextChangeCostCoins: freeChangeAvailable ? 0 : Math.max(0, toInt(MODULE_CONFIG.usernameChangeCostCoins, 0)),
    changeCount: Math.max(0, toInt(state.changeCount, 0)),
    lastChangedAt: Math.max(0, toInt(state.lastChangedAt, 0)),
    cooldownSeconds: Math.max(0, toInt(MODULE_CONFIG.usernameChangeCooldownSeconds, DEFAULT_USERNAME_CHANGE_COOLDOWN_SECONDS)),
    maxChangesPerDay: Math.max(1, toInt(MODULE_CONFIG.usernameChangeMaxPerDay, DEFAULT_USERNAME_CHANGE_MAX_PER_DAY)),
  };
}

function sanitizeEmailAddress(input) {
  var value = String(input || "").trim().toLowerCase();
  if (!value || value.length > EMAIL_MAX_LENGTH) {
    return "";
  }
  if (/\s/.test(value)) {
    return "";
  }
  var atIndex = value.indexOf("@");
  if (atIndex <= 0 || atIndex !== value.lastIndexOf("@") || atIndex >= value.length - 1) {
    return "";
  }
  var localPart = value.substring(0, atIndex);
  var domainPart = value.substring(atIndex + 1);
  if (!isValidEmailLocalPart(localPart)) {
    return "";
  }
  if (!isValidEmailDomainPart(domainPart)) {
    return "";
  }
  return value;
}

function isValidEmailLocalPart(localPart) {
  if (!localPart || localPart.length > 64) {
    return false;
  }
  if (localPart[0] === "." || localPart[localPart.length - 1] === "." || localPart.indexOf("..") >= 0) {
    return false;
  }
  return /^[a-z0-9!#$%&'*+/=?^_`{|}~.-]+$/.test(localPart);
}

function isValidEmailDomainPart(domainPart) {
  if (!domainPart || domainPart.length > 255) {
    return false;
  }
  if (domainPart[0] === "." || domainPart[domainPart.length - 1] === ".") {
    return false;
  }
  var labels = domainPart.split(".");
  if (labels.length < 2) {
    return false;
  }
  for (var i = 0; i < labels.length; i++) {
    var label = labels[i];
    if (!label || label.length > 63) {
      return false;
    }
    if (label[0] === "-" || label[label.length - 1] === "-") {
      return false;
    }
    if (!/^[a-z0-9-]+$/.test(label)) {
      return false;
    }
  }
  return true;
}

function sanitizeMagicLinkToken(value) {
  var token = String(value || "").trim();
  if (!token || token.length > MAGIC_LINK_TOKEN_MAX_LENGTH) {
    return "";
  }
  if (!/^[A-Za-z0-9._~+/=-]+$/.test(token)) {
    return "";
  }
  return token;
}

function sanitizeRequestedUsername(input) {
  var raw = String(input || "").trim().toLowerCase();
  if (!raw) {
    return "";
  }
  var out = "";
  for (var i = 0; i < raw.length; i++) {
    var c = raw[i];
    var isLetter = c >= "a" && c <= "z";
    var isDigit = c >= "0" && c <= "9";
    if (isLetter || isDigit || c === "_" || c === "-") {
      out += c;
    } else {
      return "";
    }
  }
  if (out.length < 3 || out.length > 20) {
    return "";
  }
  if (out[0] === "-" || out[0] === "_" || out[out.length - 1] === "-" || out[out.length - 1] === "_") {
    return "";
  }
  return out;
}

function validateUsernameModeration(nk, username) {
  if (!MODULE_CONFIG.platformUsernameValidateUrl || !MODULE_CONFIG.platformInternalKey) {
    return {
      allowed: true,
      source: "disabled",
    };
  }
  var response = nk.httpRequest(
    MODULE_CONFIG.platformUsernameValidateUrl,
    "post",
    {
      "Content-Type": "application/json",
      "x-admin-key": MODULE_CONFIG.platformInternalKey,
    },
    JSON.stringify({
      game_id: MODULE_CONFIG.gameId,
      username: username,
    }),
    5000,
    false
  );
  if (response.code < 200 || response.code >= 300) {
    return {
      allowed: false,
      source: "platform_error",
    };
  }
  var parsed = parseHttpBodyJson(response.body);
  return {
    allowed: parsed.allowed === true,
    source: "platform",
  };
}

function stableHashHex(input) {
  var text = String(input || "");
  if (!text) {
    return "";
  }
  var h1 = fnv1a32(text, 2166136261);
  var h2 = fnv1a32(text, 2166136261 ^ 0x9e3779b9);
  return toHex32(h1) + toHex32(h2);
}

function fnv1a32(text, seed) {
  var hash = seed >>> 0;
  for (var i = 0; i < text.length; i++) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619) >>> 0;
  }
  return hash >>> 0;
}

function toHex32(value) {
  var out = (value >>> 0).toString(16);
  while (out.length < 8) {
    out = "0" + out;
  }
  return out;
}

function legacyMagicLinkLookupKeyByEmail(email) {
  var normalized = sanitizeEmailAddress(email || "");
  if (!normalized) {
    return "";
  }
  var safe = normalized.replace(/[^a-z0-9_-]/g, "_");
  if (!safe) {
    return "";
  }
  if (safe.length > 96) {
    safe = safe.substring(0, 96);
  }
  return MAGIC_LINK_EMAIL_LOOKUP_KEY_PREFIX + safe;
}

function readMagicLinkLookupUserIdByKey(nk, key) {
  if (!key) {
    return "";
  }
  var storage = nk.storageRead([
    {
      collection: ACCOUNT_COLLECTION,
      key: key,
      userId: SYSTEM_USER_ID,
    },
  ]);
  if (storage && storage.length > 0 && storage[0].value) {
    return String(storage[0].value.userId || "").trim();
  }
  return "";
}

function deleteMagicLinkLookupByKey(nk, key) {
  if (!key) {
    return;
  }
  nk.storageDelete([
    {
      collection: ACCOUNT_COLLECTION,
      key: key,
      userId: SYSTEM_USER_ID,
    },
  ]);
}

function secureEquals(left, right) {
  var a = String(left || "");
  var b = String(right || "");
  var mismatch = a.length === b.length ? 0 : 1;
  var len = Math.max(a.length, b.length);
  for (var i = 0; i < len; i++) {
    var charA = i < a.length ? a.charCodeAt(i) : 0;
    var charB = i < b.length ? b.charCodeAt(i) : 0;
    mismatch |= charA ^ charB;
  }
  return mismatch === 0;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    normalizeOnlineMode: normalizeOnlineMode,
    normalizeOnlineRoomCode: normalizeOnlineRoomCode,
    selectOnlineTrackIds: selectOnlineTrackIds,
    awardOnlinePoints: awardOnlinePoints,
    sortedOnlineStandings: sortedOnlineStandings,
    acceptOnlineProgress: acceptOnlineProgress,
    onlineTrackMetadata: onlineTrackMetadata,
    ONLINE_MODE_SINGLE_RACE: ONLINE_MODE_SINGLE_RACE,
    ONLINE_MODE_TOURNAMENT: ONLINE_MODE_TOURNAMENT,
    ONLINE_POINTS_BY_PLACE: ONLINE_POINTS_BY_PLACE,
  };
}

function validateMagicLinkNotifyReplay(nk, data) {
  if (!MODULE_CONFIG.magicLinkNotifyRequireTimestamp) {
    return { ok: true };
  }
  var requestId = normalizeReplayRequestId(
    data.request_id || data.requestId || data.event_id || data.eventId || data.nonce || ""
  );
  if (!requestId) {
    return { ok: false, error: "request_id is required" };
  }
  var sentAt = toInt(data.sent_at || data.sentAt || data.timestamp || data.ts, 0);
  if (sentAt <= 0) {
    return { ok: false, error: "sent_at is required" };
  }
  var now = Math.floor(Date.now() / 1000);
  var maxSkew = Math.max(
    30,
    toInt(MODULE_CONFIG.magicLinkNotifyMaxSkewSeconds, DEFAULT_MAGIC_LINK_NOTIFY_MAX_SKEW_SECONDS)
  );
  if (Math.abs(now - sentAt) > maxSkew) {
    return { ok: false, error: "stale notify request" };
  }
  var state = readMagicLinkNotifyReplayState(nk);
  var entries = state.entries || {};
  var minAllowed = now - maxSkew;
  var keys = Object.keys(entries);
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i];
    if (toInt(entries[key], 0) < minAllowed) {
      delete entries[key];
    }
  }
  if (entries[requestId]) {
    return { ok: false, error: "duplicate notify request" };
  }
  entries[requestId] = sentAt;
  state.entries = trimReplayEntries(entries, MAX_MAGIC_LINK_NOTIFY_REPLAY_ENTRIES);
  writeMagicLinkNotifyReplayState(nk, state);
  return { ok: true };
}

function normalizeReplayRequestId(value) {
  var out = String(value || "").trim().toLowerCase();
  if (!out) {
    return "";
  }
  if (!/^[a-z0-9._:-]+$/.test(out)) {
    return "";
  }
  if (out.length > 96) {
    out = out.substring(0, 96);
  }
  return out;
}

function readMagicLinkNotifyReplayState(nk) {
  var storage = nk.storageRead([
    {
      collection: ACCOUNT_COLLECTION,
      key: MAGIC_LINK_NOTIFY_REPLAY_KEY,
      userId: SYSTEM_USER_ID,
    },
  ]);
  if (storage && storage.length > 0 && storage[0].value && storage[0].value.entries) {
    return {
      entries: storage[0].value.entries,
    };
  }
  return { entries: {} };
}

function writeMagicLinkNotifyReplayState(nk, state) {
  nk.storageWrite([
    {
      collection: ACCOUNT_COLLECTION,
      key: MAGIC_LINK_NOTIFY_REPLAY_KEY,
      userId: SYSTEM_USER_ID,
      value: {
        entries: state && state.entries ? state.entries : {},
        updatedAt: Math.floor(Date.now() / 1000),
      },
      permissionRead: 0,
      permissionWrite: 0,
    },
  ]);
}

function trimReplayEntries(entries, maxEntries) {
  var rows = [];
  var keys = Object.keys(entries || {});
  for (var i = 0; i < keys.length; i++) {
    rows.push({
      key: keys[i],
      at: toInt(entries[keys[i]], 0),
    });
  }
  rows.sort(function (a, b) {
    return b.at - a.at;
  });
  var limit = Math.max(1, toInt(maxEntries, MAX_MAGIC_LINK_NOTIFY_REPLAY_ENTRIES));
  var out = {};
  for (var j = 0; j < rows.length && j < limit; j++) {
    out[rows[j].key] = rows[j].at;
  }
  return out;
}
