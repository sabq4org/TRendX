import { PrismaClient } from "@prisma/client";

if (!process.env.DATABASE_URL) {
  console.warn(
    "[trendx] DATABASE_URL is not set; database calls will fail until configured.",
  );
}

declare global {
  // eslint-disable-next-line no-var
  var __trendxPrisma: PrismaClient | undefined;
}

/**
 * Single Prisma instance shared across the request lifecycle.
 * Reused across hot-reloads in dev (tsx watch) to avoid pool exhaustion.
 */
export const prisma: PrismaClient =
  globalThis.__trendxPrisma ??
  new PrismaClient({
    log:
      process.env.LOG_QUERIES === "1"
        ? ["query", "info", "warn", "error"]
        : ["warn", "error"],
  });

if (process.env.NODE_ENV !== "production") {
  globalThis.__trendxPrisma = prisma;
}

export async function closeDb(): Promise<void> {
  await prisma.$disconnect();
}
