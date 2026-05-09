# TRENDX Railway API

Hono + Node + Postgres API for the TRENDX Beta. Designed to deploy as a single Railway service alongside a Railway Postgres plugin.

## Local development

```bash
cd backend/railway-api
cp .env.example .env       # then edit DATABASE_URL, JWT_SECRET, OPENAI_API_KEY
npm install
npm run migrate            # apply schema + seed (idempotent)
npm run dev                # http://localhost:3000
```

Verify with:

```bash
curl http://localhost:3000/health
```

## Deploying to Railway

1. Create a new Railway project and add the **Postgres** plugin.
2. Create a new service from this repo, root directory `backend/railway-api/`.
3. Railway auto-detects Node and runs `npm start`. The `railway.json` file:
   - Runs `npm run migrate` on every deploy (safe — migrations are idempotent).
   - Health-checks `GET /health`.
4. In the service **Variables** tab add:
   - `JWT_SECRET` — `openssl rand -hex 32`
   - `OPENAI_API_KEY` — your OpenAI key
   - `OPENAI_MODEL` — e.g. `gpt-4o-mini` (optional, defaults to `gpt-4o-mini`)
   - `DATABASE_URL` is injected automatically by the Postgres plugin.
5. Hit **Deploy**. Once the service is green, copy its public URL into the iOS app's
   `TRENDX_API_BASE_URL` build setting.

## Endpoints

All endpoints return JSON. Authenticated routes require `Authorization: Bearer <jwt>`.

| Method | Path                  | Auth | Purpose                                  |
| ------ | --------------------- | ---- | ---------------------------------------- |
| GET    | `/health`             | no   | Liveness probe                           |
| POST   | `/auth/signup`        | no   | Create account (`name`, `email`, `password`) |
| POST   | `/auth/signin`        | no   | Sign in                                  |
| GET    | `/profile`            | yes  | Fetch profile                            |
| POST   | `/profile`            | yes  | Update profile                           |
| GET    | `/bootstrap`          | yes  | Topics + active polls + user votes       |
| POST   | `/polls/create`       | yes  | Create poll + options                    |
| POST   | `/polls/vote`         | yes  | Cast a vote (idempotent per poll/user)   |
| GET    | `/gifts`              | yes  | Available gifts                          |
| GET    | `/redemptions`        | yes  | User redemption history                  |
| POST   | `/gifts/redeem`       | yes  | Redeem a gift                            |
| POST   | `/ai/compose-poll`    | yes  | OpenAI-assisted poll suggestion          |
| POST   | `/ai/poll-insight`    | yes  | Generate an insight for a poll           |

## Architecture notes

- **`src/index.ts`** — single-file Hono router. Each handler is small enough
  to read top-to-bottom; resist the urge to split prematurely.
- **`src/db.ts`** — `pg.Pool` plus a tagged-template `sql` helper that mirrors
  the Neon API (`sql\`select * from x where id = ${id}\``), so the SQL reads
  like the original Cloudflare Worker.
- **`src/auth.ts`** — Node `crypto` only: `scrypt` for password hashing,
  HMAC-SHA256 for JWT. No external auth dependency.
- **Migrations** live in `migrations/` and are applied alphabetically by
  `src/migrate.ts`. Files are pure SQL and use `IF NOT EXISTS` / `ON CONFLICT`
  so re-applying is always safe.

## Switching to a private subnet (later)

When you outgrow the public URL, lock the iOS app down by:

1. Putting the service on a Railway private network.
2. Adding a CDN/edge in front (Cloudflare in proxy mode).
3. Replacing the wildcard CORS origin with your iOS app's URL scheme.
