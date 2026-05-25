#!/usr/bin/env bash
# Đẩy secrets slots-cli lên Cloudflare Worker (không commit .env)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${1:-$ROOT/slots-bot/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — run: npm run sync:env"
  exit 1
fi

KEYS=(
  MEZON_TOKEN
  MEZON_SESSION_ID
  MEZON_REFRESH_TOKEN
  MEZON_USER_ID
  CLAN_ID
  CHANNEL_ID
  CHANNEL_TYPE
  CHANNEL_PUBLIC
  UTILITY_BOT_ID
  MEZON_WS_HOST
  MEZON_WS_PORT
  MEZON_USE_SSL
  MEZON_WS_FORMAT
)

TMP="$(mktemp)"
node - "$ENV_FILE" "$TMP" "${KEYS[@]}" <<'NODE'
const fs = require('fs');
const [envPath, outPath, ...keys] = process.argv.slice(2);
const env = {};
for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
  const t = line.trim();
  if (!t || t.startsWith('#')) continue;
  const i = t.indexOf('=');
  if (i <= 0) continue;
  env[t.slice(0, i).trim()] = t.slice(i + 1).trim();
}
const bulk = {};
for (const k of keys) {
  if (env[k]) bulk[k] = env[k];
}
if (!bulk.MEZON_TOKEN) {
  console.error('MEZON_TOKEN missing in env file');
  process.exit(1);
}
fs.writeFileSync(outPath, JSON.stringify(bulk, null, 2));
console.log(`Prepared ${Object.keys(bulk).length} secrets for wrangler bulk`);
NODE

cd "$ROOT"
npx wrangler secret bulk "$TMP"
rm -f "$TMP"
echo "Done — secrets uploaded to Worker (containers-template)"
