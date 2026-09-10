const fs = require('fs');
const path = require('path');

const DB_FILE = path.join(__dirname, 'data', 'habits.json');

function ensureDb() {
  const dir = path.dirname(DB_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  if (!fs.existsSync(DB_FILE)) fs.writeFileSync(DB_FILE, '[]', 'utf8');
}

function readAll() {
  ensureDb();
  const raw = fs.readFileSync(DB_FILE, 'utf8');
  return JSON.parse(raw);
}

function writeAll(habits) {
  ensureDb();
  fs.writeFileSync(DB_FILE, JSON.stringify(habits, null, 2), 'utf8');
}

module.exports = { readAll, writeAll };
