# TRENDX Social Graph Rollout

Phased plan for the social-network expansion approved on 2026-05-11.
Built in order, each phase shippable on its own. Tracks both the
infrastructure (schema, endpoints) and the UX surfaces (iOS, dashboard).

The "wow" creative ideas Mizan picked are slotted into the phases where
they unlock the most.

## Phase 0 — Foundation (✅ shipped)

Schema + DTOs + types for the new account model. No UI surfaces yet —
this is purely infrastructure so the next phases have something to
build on.

- `AccountType` enum: `individual` / `organization` / `government`.
- New `users` columns: `account_type`, `is_verified`, `handle` (unique),
  `bio`, `banner_url`.
- New `reserved_handles` table seeded with TRENDX brand, all major
  ministries, royal court, top cities, top media outlets, Vision 2030
  initiatives.
- `lib/handle.ts`: normalize / validate (case-folded, 3..20 a-z 0-9 _,
  reserved-list aware).
- New endpoints: `GET /handles/check`, `GET /users/:idOrHandle`.
- `POST /profile` now accepts `handle`, `bio`, `banner_url`,
  `account_type` (individual/organization only — government is admin-
  promoted).
- iOS: `AccountType` enum, fields on `TrendXUser` + `UserDTO`, methods
  on `AppStore.updateProfile` and `checkHandleAvailability`.
- Dashboard: `User` type extended; new `AccountType` literal union.

## Phase 1 — Visual identity (next)

Make the three account types feel different the moment you see them.

- Profile page for each tier:
  - Individual: round avatar, brand gradient banner, casual layout.
  - Organization: squircle logo, amber accent, branded banner.
  - Government: formal green frame, Islamic-pattern banner, large
    institutional logo, "العلامة الرسمية" eyebrow.
- Inline badges (next to name everywhere): 🔵 verified individual /
  🟡 verified org / 🟢 government official.
- Polls/surveys published by `government` accounts get a left
  border-accent in green and a "استطلاع رسمي" pill in feeds.
- Account-type picker on profile edit (individual / organization).
- Saudi-green tone added to TrendXTheme palette.

## Phase 2 — Follow system

One-way social graph (Twitter-style).

- `user_follows` table (follower_id, followed_id, created_at, indexed).
- `POST /users/:id/follow`, `POST /users/:id/unfollow`.
- `GET /users/:id` returns counts + `viewer_follows` boolean.
- `GET /me/following`, `GET /me/followers`, `GET /me/suggested-follows`.
- Suggested-follow algorithm: prioritize verified accounts in the
  user's followed sectors + same city + Vision 2030 initiatives.
- iOS: profile page, follow button, "Suggested" carousel on Home and
  during signup ("هل تريد متابعة هذه الحسابات؟").
- Includes the **Handle reservation** wow (already shipped in Phase 0).

## Phase 3 — Timeline + Story mode + Opt-in vote visibility

The new central surface.

- New tab/screen: **الرادار** (replaces or augments Home).
- `Activity` shape: poll_published / survey_published / event_announced
  / mention_voted / mention_shared / sector_trending / poll_results.
- `GET /me/timeline?cursor=…` aggregates from followed accounts +
  followed topics + cross-cuts.
- Filter chips: All / Accounts / Sectors / Events / Results.
- **Opt-in vote visibility**: on vote, the user picks "أظهر تصويتي
  لمتابعيّ" or "احتفظ به خاصاً" (default = private).
- **Story mode** (wow #7): publishers can group polls/surveys/events
  into a `Story` collection — appears as a special pinned card in
  followers' timelines and a dedicated screen with sequential
  navigation.

## Phase 4 — Events + Live event dashboard + Saudi map

- `events` table: title, description, banner_image, organizer_id,
  category, type, starts_at, ends_at, location {city, venue, lat, lng},
  status, visibility, embedded_polls, rsvp_actions.
- CRUD endpoints + RSVP/predict actions.
- iOS: "الفعاليات" screen, event detail with embedded polls + RSVP +
  countdown.
- **Live event dashboard** (wow #3): when status=`live`, a Saudi map
  on the event page lights up with one dot per city as participants
  respond — auto-refresh via SSE. Organizer sees a richer version on
  the publisher dashboard.
- Dashboard: events management for publishers.

## Phase 5 — Verification & Trust

- Admin verification flow (KYC-light: name + email + supporting doc).
- iOS: "اطلب توثيق الحساب" CTA on profile for non-verified
  organization/government accounts.
- **Verified-only polls** (wow #10): poll publishers can set
  `voter_audience = "verified"` — only verified accounts can submit a
  response. Results show "نتائج من نخبة الموثّقين".
- **Sector takeover days** (wow #1): admin can pin a verified account
  to a sector for 24h. The sector page's banner becomes the account's
  banner, their featured poll auto-pins to the top, and timeline
  Activity for that day amplifies their posts in that sector.

## Phase 6 — Notifications expansion + Gov ↔ Citizen direct line

- Extend `lib/notifications.ts` with: `mention_voted`, `new_from_following`,
  `official_update`, `event_started`, `event_ended_results`.
- **Citizen ↔ Gov direct line** (wow #4):
  - Government accounts can publish "استطلاع وطني" — only verified
    citizens (with city + birth_year + gender filled) can respond.
  - Results aggregate to demographic buckets only; the ministry dash-
    board sees aggregated heatmaps but never individual votes.
  - Special UI in the citizen's app: "وزارة الصحة تسألك مباشرة" —
    different visual treatment from a regular poll.
  - A separate `gov_pulse_responses` table to keep these flows isolated
    from the public `votes` table.

## Demo narrative (after Phase 1)

> "Mizan, here's the new TRENDX. Sign in as a citizen — your timeline
> shows live polls from وزارة الصحة, نيوم, موسم الرياض. Tap وزارة
> الصحة's profile — formal green frame, official banner, official
> badge. They just published a poll — it's pinned to the top of your
> health sector. Now switch roles to publisher in the dashboard: see
> the live map, the engagement metrics, the verified-only response
> rate. That's the data you sell."

## Open questions (resolve before next phase)

- Pricing tiers locked in? (Free / Pro / Verified Org / Gov)
- Government verification process: admin-only seed for Beta, or build
  a self-serve form?
- Should `events.embedded_polls` be a many-to-many (polls can belong to
  multiple events) or one-to-many?
- Live event SSE — share `/events/dashboard` channel or dedicated
  `/events/event/:id` stream?
