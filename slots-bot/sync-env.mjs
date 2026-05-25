#!/usr/bin/env node
/**
 * Đồng bộ acc1 từ slots-cli → containers-template/slots-bot/.env
 * Usage: node containers-template/slots-bot/sync-env.mjs
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, '../..');
const cliDir = path.join(repoRoot, 'utility-mezon-bot/tools/slots-cli');
const outPath = path.join(here, '.env');

function parseEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const out = {};
  for (const line of fs.readFileSync(filePath, 'utf8').split('\n')) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const i = t.indexOf('=');
    if (i <= 0) continue;
    out[t.slice(0, i).trim()] = t.slice(i + 1).trim();
  }
  return out;
}

function loadAcc1() {
  const accountsPath = path.join(cliDir, 'accounts.json');
  if (!fs.existsSync(accountsPath)) {
    console.error(`Missing ${accountsPath}`);
    process.exit(1);
  }
  const acc = JSON.parse(fs.readFileSync(accountsPath, 'utf8')).accounts?.find((a) => a.id === 'acc1');
  if (!acc?.token || String(acc.token).includes('PASTE_')) {
    console.error('acc1 missing or invalid in accounts.json');
    process.exit(1);
  }
  return acc;
}

function loadSession() {
  const sessionPath = path.join(cliDir, '.sessions/acc1.session.json');
  if (!fs.existsSync(sessionPath)) return {};
  try {
    return JSON.parse(fs.readFileSync(sessionPath, 'utf8'));
  } catch {
    return {};
  }
}

const cliEnv = parseEnvFile(path.join(cliDir, '.env'));
const acc1 = loadAcc1();
const session = loadSession();

const pick = (key, ...fallbacks) => {
  for (const v of [cliEnv[key], ...fallbacks]) {
    if (v !== undefined && v !== '') return v;
  }
  return '';
};

const lines = [
  '# Auto-sync từ utility-mezon-bot/tools/slots-cli — DO NOT COMMIT',
  `# syncedAt=${new Date().toISOString()}`,
  '',
  '# acc1 auth',
  `MEZON_TOKEN=${acc1.token}`,
  `MEZON_SESSION_ID=${session.session_id || pick('MEZON_SESSION_ID')}`,
  `MEZON_REFRESH_TOKEN=${session.refresh_token || acc1.token}`,
  `MEZON_USER_ID=${acc1.userId || session.user_id || pick('MEZON_USER_ID')}`,
  '',
  '# channel / bot',
  `CLAN_ID=${pick('CLAN_ID')}`,
  `CHANNEL_ID=${pick('CHANNEL_ID')}`,
  `CHANNEL_TYPE=${pick('CHANNEL_TYPE', '1')}`,
  `CHANNEL_PUBLIC=${pick('CHANNEL_PUBLIC', 'true')}`,
  `UTILITY_BOT_ID=${pick('UTILITY_BOT_ID')}`,
  '',
  '# ws',
  `MEZON_WS_HOST=${pick('MEZON_WS_HOST', 'sock.mezon.ai')}`,
  `MEZON_WS_PORT=${pick('MEZON_WS_PORT', '443')}`,
  `MEZON_USE_SSL=${pick('MEZON_USE_SSL', 'true')}`,
  `MEZON_WS_FORMAT=${pick('MEZON_WS_FORMAT', 'pb')}`,
  `MEZON_PERSIST_REFRESH=${pick('MEZON_PERSIST_REFRESH', 'true')}`,
  `MEZON_DEBUG_MSGS=${pick('MEZON_DEBUG_MSGS', 'false')}`,
  '',
];

fs.writeFileSync(outPath, lines.join('\n'));
console.log(`Wrote ${outPath}`);
