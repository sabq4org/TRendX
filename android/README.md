# TRENDX — Android (Kotlin + Jetpack Compose)

Android port of the iOS TRENDX app. Talks to the same Railway backend
(`https://trendx-production.up.railway.app`) the iOS app + dashboard use,
so any user / poll / survey created on one surface shows up on the others.

## First-time setup

1. **Install Android Studio** (Hedgehog or newer):
   ```
   brew install --cask android-studio
   ```
   Open it and let the setup wizard download the Android SDK
   (Platform 35 + Build-Tools).

2. **Open this folder** (`android/`) in Android Studio.
   On first sync, AS will:
   - Generate the missing `gradle/wrapper/gradle-wrapper.jar`.
   - Download the Compose / Ktor / DataStore dependencies.
   - Build the project.

3. **Run on an emulator** (Tools → Device Manager → Create) or a real
   device. Pick `Pixel 7 / API 34` for a clean baseline.

## Pointing at a different backend

The base URL is baked in at build time via `BuildConfig.API_BASE_URL`,
defaulting to Railway production (matches iOS). Override:

```
./gradlew assembleDebug -PtrendxApiBaseUrl=http://10.0.2.2:3000
```

`10.0.2.2` is the Android emulator's loopback to the host machine —
useful for hitting a local `npm run dev` of `backend/railway-api/`.

## Project layout

Mirrors the iOS module names so the two ports stay legible side-by-side:

```
app/src/main/java/com/trendx/app/
  config/        — TrendXAPIConfig (mirrors TRENDX/Config/)
  models/        — Domain types (mirrors TRENDX/Models/)
  networking/    — Ktor client + DTOs (mirrors TRENDX/Networking/)
  repositories/  — Auth + session persistence (mirrors TRENDX/Repositories/)
  store/         — AppViewModel + TabItem (mirrors TRENDX/Stores/)
  theme/         — Compose Theme + colors + RTL setup
  ui/components/ — Shared widgets (TrendXTabBar, BetaStatusBanner, ...)
  ui/screens/    — Top-level screens (mirrors TRENDX/Screens/)
  MainActivity   — ContentView equivalent (auth-state routing)
```

## Current status (first pass)

- **Theme + RTL**: complete. Colors, typography, ambient background,
  `surfaceCard()` modifier all match iOS hex values 1-for-1.
- **Networking + Auth**: complete. Ktor client mirrors `TrendXAPIClient`,
  `AuthRepository` covers signin / signup / signout / `/profile`.
- **State**: `AppViewModel` is a thin port of `AppStore` — current user,
  topics, polls, gifts, selected tab, guest mode, login sheet,
  `showWelcomeAfterSignUp` ordering preserved.
- **Screens**: Login, SignUp, WelcomeAfterSignUp, Home (header + topics
  rail + poll feed), Polls (list), Gifts (list), Account.

## Not yet ported (queued for follow-up passes)

These iOS screens / cards exist and should land one at a time so each
keeps full polish before the next starts:

- HomeScreen extras: `DailyBonusCard`, `MemberTier`, `SuggestedFollowsCarousel`,
  `PulseHomeCard`, `WeeklyChallengeHomeCard`, Stories rail, Radar entry.
- PollsScreen filtering, search, voting flow, optimistic updates, repost,
  bookmark, share.
- Survey-taking flow + analytics.
- Pulse, DNA, Index, Prediction Accuracy intelligence screens.
- Public profile + follow graph + Timeline (الرادار).
- Events + Saudi map heatmap.
- Notifications inbox.
- Profile edit + handle availability check.
- Editorial poll cover renderer (currently shown via tinted gradient).

## Conventions

Same as the iOS app — see [`../CLAUDE.md`](../CLAUDE.md):

- **Never set positive `letterSpacing` on Arabic text.** It disconnects
  joined glyphs. Default `TextStyle` letterSpacing is `Unspecified`,
  which is correct.
- **RTL is set globally** by `TrendXTheme { ... }` (composes
  `LocalLayoutDirection.Rtl` for the whole tree). New screens don't need
  to opt in individually.
- **Sheet close buttons** go on the visually-leading edge in RTL (which
  is the screen's left). Don't duplicate a bottom save button at the top.
