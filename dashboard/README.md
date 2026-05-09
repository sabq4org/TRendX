# TRENDX Publisher Dashboard

The web command center for publishers and analysts. Built with Next.js 15
(App Router), Tailwind CSS, Recharts, and Server-Sent Events for live updates.

## Local development

```bash
cd dashboard
npm install
npm run dev
```

The app runs at http://localhost:3001 and talks to the Railway API at
`NEXT_PUBLIC_TRENDX_API` (defaults to `https://trendx-production.up.railway.app`).

## Deploy on Vercel

1. Sign in to https://vercel.com → "Add New Project".
2. Import `sabq4org/TRendX` from GitHub.
3. **Root Directory**: `dashboard`.
4. Framework: `Next.js` (auto-detected).
5. Add environment variable (optional):
   - `NEXT_PUBLIC_TRENDX_API` = `https://trendx-production.up.railway.app`
6. Click Deploy.

The first deploy takes ~2–3 minutes. Vercel auto-redeploys on every `main`
push.

## Pages

- `/login` — sign in with the same `/auth/signin` Railway endpoint.
- `/overview` — KPIs, recent activity feed, live ticker (SSE).
- `/polls` — poll list with totals.
- `/polls/[id]` — full Poll Performance dashboard with 6 chart types.
- `/surveys` — survey list.
- `/surveys/[id]` — Survey Intelligence (per-question, correlations, AI report).
- `/sectors` — topic list.
- `/sectors/[id]` — Sector Intelligence Report.
- `/account` — profile + tier + sign out.
