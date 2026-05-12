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

**Authentication has three states**, not two:

| state | `isAuthenticated` | `isGuest` | what the user sees |
|-------|-------------------|-----------|--------------------|
| guest (fresh install OR after `signOut()`) | `true` | `true` | full tab interface, but `HomeHeader` and `AccountScreen` swap their personalized chrome for sign-in CTAs that flip `store.showLoginSheet = true` |
| authenticated | `true` | `false` | normal personalized UI |
| offline build (no backend URL) | `true` | `false` | local samples |

`isAuthenticated` is **always** true so the tab interface is always rendered; the auth distinction is `isGuest`. Don't bring back a standalone `LoginScreen` root — present it as a sheet via `showLoginSheet`.

**Signup→welcome transition is order-sensitive.** `AppStore.signUp()` stages the session and sets `showWelcomeAfterSignUp = true` *before* flipping `isAuthenticated` so SwiftUI batches both into a single render. ContentView treats `showWelcomeAfterSignUp` as the highest-priority surface — that's what keeps the welcome screen from being preempted by a one-frame flash of the tab UI. If you refactor the auth flow, preserve this ordering or the flash returns.

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

Next.js 15 App Router. Routes are split between:
- `app/login` (public)
- `app/(authed)/...` — account, overview, polls, surveys, sectors, pulse, accuracy, audiences, trendx-index, admin
- `app/business/` — **public** B2B/marketing page (no auth) backed by `GET /public/audience-stats`; refreshes every 30s. Live URL: <https://t-rend-x.vercel.app/business>
- `app/reports/{sector,survey}/[id]` — printable HTML reports auth'd via `?token=` query, linked from inside each detail page

Shared API client in [dashboard/lib/api.ts](dashboard/lib/api.ts), auth context in [dashboard/lib/auth.tsx](dashboard/lib/auth.tsx). Live updates use SSE against `/events/dashboard` on the Railway API; [LiveTicker](dashboard/components/LiveTicker.tsx) consumes `vote_cast`, `vote_milestone`, and `gift_redeemed` event types. Charts via Recharts.

Deployed URL: <https://t-rend-x.vercel.app>

### Cover-image storage

Polls and surveys carry an optional `image_url` (the iOS app's `TrendXEditorialCover` renders it via `AsyncImage`, falling back to the topic gradient when empty). Real image bytes are **not** stored in Postgres — only a CDN URL.

- Upload flow: dashboard's [`CoverImagePicker`](dashboard/components/CoverImagePicker.tsx) → client-side resize+JPEG-recompress → POST `multipart/form-data` to [`/api/upload`](dashboard/app/api/upload/route.ts) → that route validates the user's TRENDX JWT against `/profile`, calls `put()` from `@vercel/blob`, and returns `{ url }`.
- Storage: Vercel Blob, public access. Requires `BLOB_READ_WRITE_TOKEN` env var in the dashboard's Vercel project (see [.env.local.example](dashboard/.env.local.example)). Blobs are namespaced as `covers/<userId>/<timestamp>.<ext>` with `addRandomSuffix` to avoid collisions.
- Limits: `/api/upload` rejects > 5 MB raw and non-(JPEG|PNG|WebP). Backend `POST /polls/create` and `POST /surveys/create` cap `image_url` at 2048 chars so a malformed client can't store JSON in the column.
- The iOS `TrendXEditorialCover` accepts both `https://` URLs and base64 `data:` URIs (legacy avatar path), so older builds keep working.

### Retention & engagement layer (added 2026-05-11)

Three on-device hooks back this engagement loop:

- **Smart notifications inbox** — [`/me/notifications`](backend/railway-api/src/lib/notifications.ts) synthesizes 5 notification kinds (close_to_gift, pulse_pending, challenge_open, expiring_poll, reward_earned) on demand from the user's current state. No notifications table — iOS tracks read state in `UserDefaults` (`trendx_notifications_read_v1`). UI: [NotificationsInboxScreen](TRENDX/Screens/NotificationsInboxScreen.swift), bell badge in `HomeHeader`.
- **Daily bonus** — [`GET /me/daily-bonus`](backend/railway-api/src/index.ts) / [`POST /me/daily-bonus/claim`](backend/railway-api/src/index.ts), backed by `points_ledger.type = daily_bonus` (migration `20260511000000_add_daily_bonus`). Streak ladder is 5→8→12→18→25→35→50. UI: [DailyBonusCard](TRENDX/Components/DailyBonusCard.swift) on Home.
- **Member tiers** — computed client-side from points balance: Bronze (0) / Silver (300) / Gold (1000) / Diamond (3000). See [MemberTier](TRENDX/Components/MemberTier.swift) for the badge + progress card.

Other engagement screens: [WeeklyChallengeScreen](TRENDX/Screens/WeeklyChallengeScreen.swift), [GiftRedemptionSuccessSheet](TRENDX/Screens/GiftRedemptionSuccessSheet.swift) (confetti + code capsule + share), [ProfileEditScreen](TRENDX/Screens/ProfileEditScreen.swift). Confetti is a shared component: [TrendXConfetti](TRENDX/Components/TrendXConfetti.swift).

### Social-graph layer (added 2026-05-12 — Phases 0→6, see [ROADMAP.md](ROADMAP.md))

Turns TRENDX from a polling app into a social-opinion network. Three account tiers, one-way follow graph, public timeline, events with a Saudi map heatmap, verified-only polls, and gov↔citizen channels.

**Account model:**
- `AccountType` enum: `individual` / `organization` / `government` (Prisma + iOS + dashboard TS).
- `users.handle` is unique and case-folded; reserved handles (ministries, royal court, top cities, top media, Vision 2030 brands) seeded into `reserved_handles` and validated by [`lib/handle.ts`](backend/railway-api/src/lib/handle.ts). Use `validateHandle()` — don't hand-roll.
- `users.is_verified` is admin-promoted only (`POST /admin/users/:id/verify`).
- Visual identity branches on accountType — see [AccountIdentity.swift](TRENDX/Components/AccountIdentity.swift): individual → round avatar + brand gradient; organization → squircle + gold; government → squircle + Saudi-green ring + corner shield + formal banner. The full layout lives in [PublicProfileScreen](TRENDX/Screens/PublicProfileScreen.swift).

**Follow graph:**
- `user_follows` (composite PK followerId/followedId) + denormalized `followers_count` / `following_count` on users. Counters are bumped in the same transaction as INSERT/DELETE so they don't drift.
- Endpoints: `POST /users/:id/follow|unfollow`, `GET /me/following`, `/me/followers`, `/me/suggested-follows` (ranks gov > verified > sameCity > popular).
- iOS: [SuggestedFollowsCarousel](TRENDX/Components/SuggestedFollowsCarousel.swift) on Home, follow CTA on `PublicProfileScreen`, all with optimistic flips + rollback on failure.

**Timeline (الرادار):**
- [`lib/timeline.ts`](backend/railway-api/src/lib/timeline.ts) — `buildTimeline()` merges 7 sources into a cursor-paginated feed: polls from followed accounts, polls in followed topics, surveys from followed, reposts by followed, public votes by followed, recently-ended polls, featured stories.
- `GET /me/timeline?cursor=…&filter=all|accounts|sectors|results`.
- iOS: [TimelineScreen](TRENDX/Screens/TimelineScreen.swift) with 7 activity-card kinds (`poll_published`, `survey_published`, `vote_cast`, `repost`, `poll_results`, `sector_trending`, `story`). Entry card on Home labelled "الرادار".

**Stories** (editorial collections):
- `stories` table + `polls.story_id` / `surveys.story_id` foreign keys + `storyOrder`. `isPinned` and `isFeatured` flags drive prioritization in feeds.
- `POST /stories`, `GET /stories/:id`, `GET /stories?featured=…&publisher_id=…`.

**Vote visibility (opt-in):**
- `votes.is_public` defaults `false`. User explicitly opts in at vote time via a tiny chip on `PollCard` ("تصويتي خاص ↔ تصويتي ظاهر لمتابعيّ"). When public, the vote surfaces as a `vote_cast` activity to followers.

**Reposts (إعادة نشر):**
- `reposts` (composite PK userId/pollId) — toggle endpoints `POST /polls/:id/repost` and `/unrepost`. Reposts surface as their own activity kind on timeline.
- iOS: pill in `PollCard` footer, AI-violet gradient when active.

**Events + Saudi map:**
- `events` + `event_responses` tables. Status: `upcoming`/`live`/`closed`. `attending_count` is denormalized.
- `POST /events`, `GET /events/:id` (returns `viewer_status` + top-12 `city_breakdown`), `POST /events/:id/rsvp`.
- iOS: [EventDetailScreen](TRENDX/Screens/EventDetailScreen.swift) renders a Canvas-drawn Saudi outline with one heat-dot per city, sized by attendee count. ~20 Saudi cities pre-mapped to normalized coordinates in `SaudiMapHeatmap`.

**Verified-only polls + Sector takeover:**
- `polls.voter_audience` enum: `public` (default) / `verified` (only badged accounts) / `verified_citizen` (only verified citizens with full demographics). Enforced in `POST /polls/vote` with localized 403 + machine-readable `reason`.
- `sector_takeovers` table — admin-pinned (`POST /admin/sector-takeovers`) association between a verified account and a topic for a finite window with an optional featured poll. `GET /sectors/:topicId/takeover` drives the banner on the sector page.
- iOS: PollCard's "official" banner adapts its label by audience gate — "استطلاع رسمي" / "استطلاع رسمي · للحسابات الموثّقة" / "استطلاع وطني · للمواطنين الموثّقين".

**Notifications expansion:**
- `lib/notifications.ts` gains 4 new kinds: `new_from_following`, `event_started`, `national_poll`, `sector_takeover`.
- iOS `NotificationsInboxScreen` maps kinds to tints — national + takeover use Saudi-green so official notifications nest visually with the rest of the government UI.

**Demo seed:**
- [seed.ts](backend/railway-api/src/seed.ts) upserts **وزارة الإعلام** (`@moia`, government, verified, password `ChangeMe-TRENDX-Beta!`) plus full demo content: 3 polls (one of each audience tier), 1 survey, 1 event with venue/coords, 1 pinned featured story. Idempotent — re-running the seed doesn't duplicate.

## Conventions worth knowing

- **JSON casing**: the API uses `snake_case`. The iOS client converts both directions automatically; the dashboard's `lib/types.ts` already mirrors API names. Don't hand-roll case conversion in handlers — use the existing `snake` helper or DTO mappers in `lib/dto.ts`.
- **Sample data fallbacks**: iOS screens always have local samples (`Topic.samples`, `Poll.samples`, `Survey.techSamples`, `Gift.samples`). Keep these in sync conceptually when adding fields, since they're what the offline + first-run experience renders.
- **Migrations are deploy-time**: any DB change must be a new file under `prisma/migrations/` written so it can re-run safely. The schema header explains why columns get denormalized — follow that pattern rather than fixing it with a join.
- **Don't split the Hono router file** unless a section is genuinely independent; the backend README explicitly calls this out and the file is structured to be read end-to-end.
- **Pulse falls back to anonymous**: `/pulse/today/anon` is hit first so the screen renders something even with a stale token. Don't wrap every API call in `try?` — surface errors with a retry button (see `PulseTodayScreen.errorState`).

### iOS UX conventions

- **Never use `.tracking()` with positive values on Arabic text.** Positive letter-spacing disconnects the joined glyphs and makes labels look "cut." This burned us on `PollCoverView`, `SurveyDetailView` hero, and elsewhere. English-only labels are fine.
- **Sheet close buttons go on `.topBarTrailing`** (= left side of the screen in RTL). Secondary actions (Share, Save, "تعليم الكل كمقروء") go on `.topBarLeading`. If a save button already exists at the bottom of a form, **don't duplicate it** as a top toolbar item — put "إغلاق" there instead.
- **Banner messages auto-dismiss after 4s.** `AppStore.appMessage`'s `didSet` schedules the dismissal; the user can also tap to clear. Don't add long-lived banners — they should be transient.
- **Apply `.trendxRTL()` to every new top-level sheet.** Earlier commits (`5e95543`, `25dafab`, `08f8a0f`) were dedicated to fixing the consequences of forgetting this.
