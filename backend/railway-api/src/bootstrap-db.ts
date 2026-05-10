/**
 * One-shot DB bootstrap that runs *before* `prisma migrate deploy`.
 *
 * Two responsibilities:
 *
 * 1. **Pre-Prisma reset** — when transitioning from a hand-rolled SQL schema
 *    to a Prisma-managed schema, Prisma fails with P3005 because it sees
 *    tables it didn't create. We detect that case and reset the `public`
 *    schema so Prisma can take ownership cleanly.
 *
 * 2. **Stuck-migration recovery** — if a previous deploy crashed half-way
 *    through a migration (e.g. an embedded COMMIT/BEGIN that left rows in
 *    `_prisma_migrations` with `finished_at IS NULL`), `prisma migrate
 *    deploy` will refuse to do anything and the app never starts. We
 *    delete the orphan row so the migration can be re-applied. This is
 *    safe because every migration in this repo is now idempotent
 *    (CREATE TABLE IF NOT EXISTS / DO blocks for FKs).
 *
 * After Prisma is in control (i.e. the `_prisma_migrations` table exists),
 * step (1) is a no-op on every subsequent deploy. Step (2) only fires when
 * a stuck row is actually present.
 *
 * Safety:
 * - Never resets if `_prisma_migrations` exists.
 * - Never resets if `public` schema is empty.
 * - Only ever touches the `public` schema and `_prisma_migrations` rows.
 */

import { Client } from "pg";

async function recoverStuckMigrations(client: Client): Promise<void> {
  const stuck = await client.query<{
    id: string;
    migration_name: string;
    finished_at: Date | null;
    rolled_back_at: Date | null;
  }>(
    `select id, migration_name, finished_at, rolled_back_at
       from _prisma_migrations
       where finished_at is null or rolled_back_at is not null`,
  );

  if (stuck.rows.length === 0) return;

  for (const row of stuck.rows) {
    const reason = row.finished_at === null ? "unfinished" : "rolled-back";
    console.warn(
      `[bootstrap-db] removing ${reason} migration row ` +
        `${row.migration_name} (id=${row.id}) so it can be re-applied.`,
    );
  }

  await client.query(
    `delete from _prisma_migrations
       where finished_at is null or rolled_back_at is not null`,
  );
}

async function main(): Promise<void> {
  const url = process.env.DATABASE_URL;
  if (!url) {
    console.warn("[bootstrap-db] DATABASE_URL not set, skipping.");
    return;
  }

  const sslRequired =
    process.env.PGSSLMODE === "require" || /sslmode=require/i.test(url);

  const client = new Client({
    connectionString: url,
    ssl: sslRequired ? { rejectUnauthorized: false } : undefined,
  });

  await client.connect();

  try {
    const prismaTable = await client.query<{ exists: boolean }>(
      `select exists (
         select 1 from information_schema.tables
         where table_schema = 'public' and table_name = '_prisma_migrations'
       ) as exists`,
    );

    if (prismaTable.rows[0]?.exists) {
      console.log("[bootstrap-db] Prisma already manages this DB.");
      await recoverStuckMigrations(client);
      return;
    }

    const tableCount = await client.query<{ count: string }>(
      `select count(*)::text as count from information_schema.tables
       where table_schema = 'public'`,
    );
    const count = Number(tableCount.rows[0]?.count ?? "0");

    if (count === 0) {
      console.log("[bootstrap-db] public schema is empty, nothing to do.");
      return;
    }

    console.warn(
      `[bootstrap-db] detected ${count} pre-Prisma table(s) in public schema. ` +
        `Resetting schema so Prisma can take over.`,
    );
    await client.query("drop schema public cascade");
    await client.query("create schema public");
    await client.query("grant all on schema public to public");
    console.log("[bootstrap-db] schema reset complete.");
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error("[bootstrap-db] failed:", error);
  process.exit(1);
});
