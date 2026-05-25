#!/bin/sh
set -e

# Ghi session WS từ .env → .sessions/<acc>.session.json (tránh cold start trong container)
if [ -n "${MEZON_TOKEN}${MEZON_SESSION_ID}" ]; then
  ACC="${SLOTS_ACCOUNT:-acc1}"
  mkdir -p /app/.sessions
  SESSION_FILE="/app/.sessions/${ACC}.session.json"
  cat > "$SESSION_FILE" <<EOF
{
  "token": "${MEZON_TOKEN:-}",
  "session_id": "${MEZON_SESSION_ID:-}",
  "refresh_token": "${MEZON_REFRESH_TOKEN:-${MEZON_TOKEN:-}}",
  "user_id": "${MEZON_USER_ID:-}",
  "savedAt": $(date +%s)000
}
EOF
  echo "[slots-bot] session → ${SESSION_FILE}"
fi

GAME="${SLOTS_GAME:-slots1}"
ACCOUNT="${SLOTS_ACCOUNT:-acc1}"
MIN_JACKPOT="${MIN_JACKPOT:-250000}"
MIN_EV="${MIN_EV:--95}"
MAX_QUEUE="${MAX_QUEUE:-9999}"
POLL="${POLL:-3000}"
RECHECK="${RECHECK:-0}"
TOP10_EVERY="${TOP10_EVERY:-0}"
OUTPUT="${OUTPUT:-reports/acc1-slots1k.json}"
TIMEOUT="${TIMEOUT:-15000}"

mkdir -p "$(dirname "$OUTPUT")"

set -- node dist/cli.js --game "$GAME" bot \
  --account "$ACCOUNT" \
  --min-jackpot "$MIN_JACKPOT" \
  --min-ev "$MIN_EV" \
  --max-queue "$MAX_QUEUE" \
  --poll "$POLL" \
  --recheck "$RECHECK" \
  --top10-every "$TOP10_EVERY" \
  --timeout "$TIMEOUT" \
  -o "$OUTPUT"

echo "[slots-bot] $*"
exec "$@"
