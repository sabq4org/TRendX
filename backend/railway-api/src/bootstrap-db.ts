/**
 * One-shot DB bootstrap that runs *before* `prisma migrate deploy`.
 *
 * Purpose: when transitioning from a hand-rolled SQL schema (the pre-Prisma
 * Beta) to a Prisma-managed schema, Prisma fails with P3005 because it sees
 * tables it didn't create. This script detects that case and resets the
 * `public` schema so Prisma can take ownership cleanly.
 *
 * After Prisma is in control (i.e. the `_prisma_migrations` table exists),
 * this script is a no-op on every subsequent deploy.
 *
 * Safety:
 * - Never resets if `_prisma_migrations` exists (Prisma already owns the DB).
 * - Never resets if `public` schema is empty.
 * - Only ever touches the `public` schema.
 */

import { Client } from "pg";

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
      console.log("[bootstrap-db] Prisma already manages this DB, skipping reset.");
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
