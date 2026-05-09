import pg from "pg";

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  console.warn("[trendx] DATABASE_URL is not set; database calls will fail until configured.");
}

// Railway's internal Postgres networking doesn't use SSL.
// Only enable SSL when the connection string explicitly asks for it
// (e.g. external Neon/Supabase URLs that always require sslmode=require).
const url = process.env.DATABASE_URL ?? "";
const sslRequired =
  process.env.PGSSLMODE === "require" || /sslmode=require/i.test(url);

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: sslRequired ? { rejectUnauthorized: false } : false,
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
});

pool.on("error", (error) => {
  console.error("[trendx] postgres pool error:", error);
});

export type Row = Record<string, any>;

/**
 * Tagged-template SQL helper that mirrors Neon's API.
 * Converts `${value}` interpolations to `$1, $2, ...` parameterized queries.
 */
export async function sql<T extends Row = Row>(
  strings: TemplateStringsArray,
  ...values: unknown[]
): Promise<T[]> {
  let text = "";
  strings.forEach((part, index) => {
    text += part;
    if (index < values.length) text += `$${index + 1}`;
  });
  const result = await pool.query<T>(text, values as any[]);
  return result.rows;
}

export async function closePool(): Promise<void> {
  await pool.end();
}
