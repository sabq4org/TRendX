# TRENDX Beta

TRENDX is wired for a Beta deployment through a small Railway-hosted API. The iOS app never connects directly to Postgres and never stores `DATABASE_URL` or `OPENAI_API_KEY`.

## iOS Configuration

Set these build settings or `Info.plist` values before running against a real backend:

- `TRENDX_API_BASE_URL` — public URL of the Railway service (e.g. `https://trendx-api.up.railway.app`).

If this value is empty, the app uses the local fallback data and operates fully offline.

## Backend Setup (Railway)

1. Create a new Railway project.
2. Add the **Postgres** plugin — `DATABASE_URL` is injected automatically.
3. Deploy the service from `backend/railway-api/`.
4. Add service variables:
   - `JWT_SECRET` — `openssl rand -hex 32`
   - `OPENAI_API_KEY`
   - `OPENAI_MODEL` (optional, defaults to `gpt-4o-mini`)
5. The first deploy runs `npm run migrate` automatically (idempotent), creating the schema and seeding starter topics + gifts.

Full backend docs live in [`backend/railway-api/README.md`](backend/railway-api/README.md).

## Beta Acceptance Checks

- New user can sign up and reach the main app.
- Poll feed loads from the API on first launch, or local fallback loads when the API is not configured.
- User can create single choice, multiple choice, rating, and linear scale polls.
- User can vote once per poll and earn points.
- User can redeem an available gift and receive a test code.
- TRENDX AI returns suggestions and insights from the API backend, with local fallback on failures.
- `xcodebuild -scheme TRENDX -project TRENDX.xcodeproj -destination 'generic/platform=iOS Simulator' build` succeeds.
