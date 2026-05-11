# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is a three-part monorepo for the TRENDX Beta product. The three pieces share data but are deployed independently:

- `TRENDX/` + `TRENDX.xcodeproj/` — native iOS app (SwiftUI, Arabic/RTL-first).
- `backend/railway-api/` — Hono + Node + Prisma + Postgres API, deployed on Railway. Source of truth for all persistent data and AI calls.
- `dashboard/` — Next.js 15 (App Router) publisher dashboard, deployed on Vercel. Talks to the same Railway API.

The iOS app never connects to Postgres or OpenAI directly — `DATABASE_URL` and `OPENAI_API_KEY` live only on the Railway service.

## Common commands

### iOS

```bash
# Build (the README's beta acceptance check)
xcodebuild -scheme TRENDX -project TRENDX.xcodeproj \
  -destination 'generic/platform=iOS Simulator' build
```

API base URL override: set `TRENDX_API_BASE_URL` in `Info.plist` or as a process env var. Empty/missing falls back to `https://trendx-production.up.railway.app` (see [TRENDX/Config/TrendXAPIConfig.swift](TRENDX/Config/TrendXAPIConfig.swift)). If the URL is truly absent, the app boots in offline mode against local sample data.

### Backend (`backend/railway-api/`)

```bash
npm install
cp .env.example .env      # set DATABASE_URL, JWT_SECRET, OPENAI_API_KEY
npm run migrate           # prisma migrate deploy — idempotent
npm run dev               # tsx watch, http://localhost:3000
npm run typecheck         # tsc --noEmit
npm run build             # prisma generate + tsc
npm run seed:dev          # tsx src/seed.ts (starter topics + gifts)
npm run seed:demo:dev     # demo polls/surveys/users
npm run studio            # prisma studio
```

Railway's `postdeploy` runs `bootstrap-db.js → prisma migrate deploy → seed.js` on every deploy; all migrations and seeds are written to be safely re-runnable (`IF NOT EXISTS` / `ON CONFLICT`).

### Dashboard (`dashboard/`)

```bash
npm install
npm run dev               # http://localhost:3001
npm run typecheck         # tsc --noEmit
npm run lint              # next lint
npm run build             # next build
```

Talks to `NEXT_PUBLIC_TRENDX_API` (defaults to the Railway production URL).

## Architecture

### iOS app data flow

The app is a `SwiftUI` shell whose state lives in a single `@MainActor` `AppStore` ([TRENDX/Stores/AppStore.swift](TRENDX/Stores/AppStore.swift)). It is the only `ObservableObject` injected into the view tree.

Layered access to the backend:

1. **`TrendXAPIClient`** ([TRENDX/Networking/TrendXAPIClient.swift](TRENDX/Networking/TrendXAPIClient.swift)) — generic `get`/`post` over `URLSession` with snake_case ↔ camelCase JSON conversion and custom ISO-8601 date decoding. Throws `TrendXAPIError.notConfigured` when no base URL is set.
2. **Repositories** ([TRENDX/Repositories/](TRENDX/Repositories/)) — one per domain (`Auth`, `Poll`, `Survey`, `Rewards`, `AI`). Wrap the client with typed endpoints and persist auth sessions.
3. **`AppStore`** — orchestrates repositories, holds `@Published` state, mirrors data to `UserDefaults` under keyed snapshots (`trendx_user_v1`, `trendx_polls_v1`, etc.) so the UI keeps working offline.
4. **Read-only "intelligence" endpoints** (Pulse, DNA, Index, Prediction Accuracy) call `TrendXAPIClient` directly via `store.apiClient` + `store.accessToken` — the store exposes both. See [TRENDX/Networking/TrendXIntelligenceAPI.swift](TRENDX/Networking/TrendXIntelligenceAPI.swift) and the related screens.

`isAuthenticated` is `true` when either an `AuthSession` is restored *or* the API is not configured (offline mode). That dual path is intentional — keep it when refactoring auth.

The bootstrap call (`GET /bootstrap`) returns topics + active polls + the user's votes in one shot. `AppStore.refreshBootstrap()` is also invoked on every `scenePhase == .active` transition (see `ContentView`) so dashboard-published content appears without a manual pull-to-refresh.

RTL: every top-level surface (auth shell, sheets, tab content) applies `.trendxRTL()`. New top-level sheets must do the same — recent commits (`08f8a0f`, `25dafab`, `5e95543`) were dedicated to fixing RTL alignment, so don't regress it.

### Backend (Railway API)

- **Single Hono router** in [backend/railway-api/src/index.ts](backend/railway-api/src/index.ts). The original guidance in the backend README still applies: "each handler is small enough to read top-to-bottom; resist the urge to split prematurely."
- **`src/db.ts`** — `pg.Pool` plus a tagged-template `sql` helper that mirrors the Neon API. Prisma client is also exposed for typed access; both coexist.
- **`src/auth.ts`** — Node `crypto` only (`scrypt` for password hashing, HMAC-SHA256 for JWT). No external auth dependency.
- **`src/lib/`** is where domain logic lives — `analytics`, `deep-analytics`, `pulse`, `dna`, `predictions`, `audience`, `index-metrics`, `personas`, `webhooks`, `comments`, `challenges`, `ai`, `ai-prompts`, `dto`, `snake`, `demographics`, `streak`. Most have a "cached or compute" entry point; respect that caching layer when adding new analytics — don't recompute per request.
- **`src/jobs/`** — `snapshot.ts` (append-only `analytics_snapshots` writer, can be triggered via `runSnapshotsNow` or the periodic `startSnapshotJob`) and `daily.ts`.
- **`src/events/sse.ts`** — Server-Sent Events. The dashboard's live ticker subscribes here; emit through `broadcastEvent` from handlers.
- **Migrations**: SQL under `prisma/migrations/`, applied by `prisma migrate deploy`. Schema in [backend/railway-api/prisma/schema.prisma](backend/railway-api/prisma/schema.prisma). The schema's own header documents the data-modeling principles — *read it* before touching the data layer, especially:
  - Demographics are denormalized onto each vote/response so analytics survive user updates/deletion.
  - `analytics_snapshots` and `ai_insights` are append-only JSONB — evolve their payloads instead of adding columns.
  - All point/coin changes go through `points_ledger`; the user balance must remain reconcilable.

### Dashboard

Next.js 15 App Router. Routes are split between `app/login` (public) and `app/(authed)/...` (account, overview, polls, surveys, sectors, pulse, accuracy, audiences, trendx-index, admin). Shared API client in [dashboard/lib/api.ts](dashboard/lib/api.ts), auth context in [dashboard/lib/auth.tsx](dashboard/lib/auth.tsx). Live updates use SSE against `/events` on the Railway API. Charts via Recharts.

## Conventions worth knowing

- **JSON casing**: the API uses `snake_case`. The iOS client converts both directions automatically; the dashboard's `lib/types.ts` already mirrors API names. Don't hand-roll case conversion in handlers — use the existing `snake` helper or DTO mappers in `lib/dto.ts`.
- **Sample data fallbacks**: iOS screens always have local samples (`Topic.samples`, `Poll.samples`, `Survey.techSamples`, `Gift.samples`). Keep these in sync conceptually when adding fields, since they're what the offline + first-run experience renders.
- **Migrations are deploy-time**: any DB change must be a new file under `prisma/migrations/` written so it can re-run safely. The schema header explains why columns get denormalized — follow that pattern rather than fixing it with a join.
- **Don't split the Hono router file** unless a section is genuinely independent; the backend README explicitly calls this out and the file is structured to be read end-to-end.
