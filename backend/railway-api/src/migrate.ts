import { readdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { pool, closePool } from "./db.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const MIGRATIONS_DIR = join(__dirname, "..", "migrations");

async function run(): Promise<void> {
  if (!process.env.DATABASE_URL) {
    console.error("[migrate] DATABASE_URL is not set. Aborting.");
    process.exit(1);
  }

  const entries = (await readdir(MIGRATIONS_DIR))
    .filter((file) => file.endsWith(".sql"))
    .sort();

  if (entries.length === 0) {
    console.log("[migrate] no SQL files found, nothing to do.");
    return;
  }

  for (const file of entries) {
    const path = join(MIGRATIONS_DIR, file);
    const content = await readFile(path, "utf8");
    if (!content.trim()) continue;
    console.log(`[migrate] applying ${file}…`);
    await pool.query(content);
  }
  console.log(`[migrate] applied ${entries.length} file(s).`);
}

run()
  .catch((error) => {
    console.error("[migrate] failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await closePool();
  });
