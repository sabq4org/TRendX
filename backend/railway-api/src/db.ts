import pg from "pg";

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  console.warn("[trendx] DATABASE_URL is not set; database calls will fail until configured.");
}

const sslRequired =
  process.env.PGSSLMODE === "require" ||
  /sslmode=require/i.test(process.env.DATABASE_URL ?? "") ||
  process.env.NODE_ENV === "production";

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: sslRequired ? { rejectUnauthorized: false } : undefined,
  max: 10,
  idleTimeoutMillis: 30_000,
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
