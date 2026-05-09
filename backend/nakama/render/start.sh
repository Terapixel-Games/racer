#!/bin/sh
set -eu

strip_db_scheme() {
  value="$1"
  value="${value#postgres://}"
  value="${value#postgresql://}"
  printf '%s' "$value"
}

resolve_db_address() {
  if [ -n "${DB_ADDRESS:-}" ]; then
    strip_db_scheme "${DB_ADDRESS}"
    return
  fi

  if [ -n "${DATABASE_URL:-}" ]; then
    strip_db_scheme "${DATABASE_URL}"
    return
  fi

  if [ -z "${DB_USER:-}" ] || [ -z "${DB_PASSWORD:-}" ] || [ -z "${DB_HOST:-}" ] || [ -z "${DB_NAME:-}" ]; then
    echo "Missing database config. Set DB_ADDRESS (preferred), DATABASE_URL, or DB_USER/DB_PASSWORD/DB_HOST/DB_NAME."
    exit 1
  fi

  db_port="${DB_PORT:-5432}"
  db_address="${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${db_port}/${DB_NAME}"
  db_params="${DB_PARAMS:-}"
  db_sslmode="${DB_SSLMODE:-}"

  if [ -n "$db_params" ]; then
    db_params="${db_params#\?}"
    db_address="${db_address}?${db_params}"
  elif [ -n "$db_sslmode" ]; then
    db_address="${db_address}?sslmode=${db_sslmode}"
  fi

  printf '%s' "$db_address"
}

required_vars="GAME_ID NAKAMA_SERVER_KEY NAKAMA_SESSION_ENCRYPTION_KEY NAKAMA_SESSION_REFRESH_ENCRYPTION_KEY NAKAMA_RUNTIME_HTTP_KEY"
for var_name in $required_vars; do
  eval "value=\${$var_name:-}"
  if [ -z "$value" ]; then
    echo "Missing required env var: $var_name"
    exit 1
  fi
done

if [ -z "${NAKAMA_CONSOLE_PASSWORD:-}" ]; then
  echo "Missing required env var: NAKAMA_CONSOLE_PASSWORD"
  exit 1
fi

if [ -z "${PORT:-}" ]; then
  PORT=7350
fi

DB_ADDRESS="$(resolve_db_address)"
LEADERBOARD_ID_VALUE="${LEADERBOARD_ID:-${GAME_ID}_high_scores}"
NAKAMA_SOCKET_PORT="${NAKAMA_SOCKET_PORT:-7354}"
NAKAMA_CONSOLE_PORT="${NAKAMA_CONSOLE_PORT:-7355}"

cat > /tmp/render-local.yml <<EOF
name: "${GAME_ID}-nakama"
logger:
  level: "INFO"
session:
  encryption_key: "${NAKAMA_SESSION_ENCRYPTION_KEY}"
  refresh_encryption_key: "${NAKAMA_SESSION_REFRESH_ENCRYPTION_KEY}"
  token_expiry_sec: 7200
  refresh_token_expiry_sec: 604800
socket:
  server_key: "${NAKAMA_SERVER_KEY}"
  port: ${NAKAMA_SOCKET_PORT}
console:
  port: ${NAKAMA_CONSOLE_PORT}
  username: "${NAKAMA_CONSOLE_USERNAME:-admin}"
  password: "${NAKAMA_CONSOLE_PASSWORD}"
runtime:
  path: "/nakama/data/modules"
  js_entrypoint: "index.js"
  http_key: "${NAKAMA_RUNTIME_HTTP_KEY}"
  env:
    - "GAME_ID=${GAME_ID}"
    - "LEADERBOARD_ID=${LEADERBOARD_ID_VALUE}"
    - "PLATFORM_IDENTITY_URL=${PLATFORM_IDENTITY_URL:-}"
    - "PLATFORM_USERNAME_VALIDATE_URL=${PLATFORM_USERNAME_VALIDATE_URL:-}"
    - "PLATFORM_ACCOUNT_MAGIC_LINK_START_URL=${PLATFORM_ACCOUNT_MAGIC_LINK_START_URL:-}"
    - "PLATFORM_ACCOUNT_MAGIC_LINK_COMPLETE_URL=${PLATFORM_ACCOUNT_MAGIC_LINK_COMPLETE_URL:-}"
    - "PLATFORM_ACCOUNT_MERGE_CODE_URL=${PLATFORM_ACCOUNT_MERGE_CODE_URL:-}"
    - "PLATFORM_ACCOUNT_MERGE_REDEEM_URL=${PLATFORM_ACCOUNT_MERGE_REDEEM_URL:-}"
    - "PLATFORM_TELEMETRY_EVENTS_URL=${PLATFORM_TELEMETRY_EVENTS_URL:-}"
    - "PLATFORM_INTERNAL_KEY=${PLATFORM_INTERNAL_KEY:-}"
    - "TPX_MAGIC_LINK_NOTIFY_SECRET=${TPX_MAGIC_LINK_NOTIFY_SECRET:-}"
    - "USERNAME_CHANGE_COST_COINS=${USERNAME_CHANGE_COST_COINS:-300}"
    - "USERNAME_CHANGE_COOLDOWN_SECONDS=${USERNAME_CHANGE_COOLDOWN_SECONDS:-300}"
    - "USERNAME_CHANGE_MAX_PER_DAY=${USERNAME_CHANGE_MAX_PER_DAY:-3}"
EOF

echo "Running Nakama migrations..."
/nakama/nakama migrate up --database.address "${DB_ADDRESS}"

echo "Starting Nakama (socket=${NAKAMA_SOCKET_PORT}, console=${NAKAMA_CONSOLE_PORT})..."
/nakama/nakama \
  --config /tmp/render-local.yml \
  --database.address "${DB_ADDRESS}" \
  --socket.port "${NAKAMA_SOCKET_PORT}" \
  --console.port "${NAKAMA_CONSOLE_PORT}" &

echo "Starting nginx proxy on ${PORT}..."
export PORT
export NAKAMA_SOCKET_PORT
export NAKAMA_CONSOLE_PORT
envsubst '${PORT} ${NAKAMA_SOCKET_PORT} ${NAKAMA_CONSOLE_PORT}' \
  < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

exec nginx -g "daemon off;"
