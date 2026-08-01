# Architecture

Last updated: 2026-07-28 | commit 34e0f62

System design for both implementations. For file-level navigation use `CODE_MAP.md`; for responsibility rules use `FEATURE_BOUNDARIES.md`.

---

## System shape

Two client-only apps, no server component in either.

```
                 fuckcorpo-design-system.md
                 fuckcorpo-features.md
                          |  (shared product/design source of truth)
          +---------------+---------------+
          |                               |
    React SPA (src/)                Flutter app (app/)
    deprecated legacy               forward implementation
          |                               |
    localStorage                    shared_preferences
    "fuckcorpo_data"                "fuckcorpo_state_v1"
    unversioned                     schemaVersion = 1
          |                               ^
          +-------- read once, at --------+
                    first boot (V0Migrator)
```

No network calls in the Flutter app at all. The React app makes one: Google Fonts CDN.

---

## Flutter architecture

### Layering

```
main.dart            boot, migration, ProviderScope
   |
app.dart             MaterialApp.router, theme mode, toast scope
   |
router.dart          go_router: /welcome gate + ShellRoute
   |
features/            screens: timer, dashboard, achievements, onboarding, settings
   |
widgets/             design-system kit (fc_*)
   |
state/               controllers, the only write path
   |
data/                repository, key-value store, migrations
   |
domain/  core/       pure business rules, tokens, formatters
```

Dependencies point downward only. `domain/` imports nothing from above it.

### State management

Riverpod 3, new-style `Notifier` / `NotifierProvider`. No provider, no bloc. `setState` appears only for trivial local UI state.

`AppController extends Notifier<AppState>`:
* `build()` returns `repository.load()` — a **synchronous** read from the warmed `shared_preferences` cache, so frame 1 renders real data instead of defaults then flashing.
* Every mutator calls `_commit()`: set state, then fire-and-forget `repository.save()`.

`keyValueStoreProvider` throws `UnimplementedError` unless overridden. `main.dart` overrides it with the live store; tests override it with an in-memory store. This is the seam that makes the whole tree testable without mocking `shared_preferences`.

Derived providers: `perMinuteRateProvider` (watches salary), `currencyProvider` (watches settings), `clockProvider` (injectable for deterministic timer tests).

### Persistence

Single JSON document under one key.

```json
{
  "schemaVersion": 1,
  "salary": { "amount": ..., "type": "annual|hourly|..." },
  "breaks": [ { "id", "category", "durationMs", "timestamp" } ],
  "settings": { "theme", "currency", "state", "industry", "soundEnabled" },
  "achievements": [ "id", ... ],
  "onboarded": true,
  "runningTimer": { "startedAt", "category" }
}
```

Parsing is defensive: `BreakRecord.tryFromJson` drops a malformed row rather than failing the entire load, so one bad record cannot brick the app.

`runningTimer` being persisted is what makes an in-flight break survive reload and navigation — the fix for BUG-008. Elapsed time is always derived from wall clock, never accumulated by a ticker.

### The v0 bridge

Runs once in `main()` before `runApp`. Decision order:

1. A v1 payload already exists → do nothing.
2. The marker `fuckcorpo_migrated_from_v0` is set → do nothing.
3. Read React's `fuckcorpo_data`, convert, write v1, set marker.
4. If the v0 payload will not parse → copy it to `fuckcorpo_data_backup`, set the marker and `fuckcorpo_v0_migration_failed`, boot to defaults, and surface a notice in Settings.

Invariant: `fuckcorpo_data` is never written and never deleted. React rollback is always possible.

On web this must bypass `shared_preferences`, which namespaces keys under `flutter.`. `legacy_store.dart` conditionally exports `legacy_store_web.dart` (raw `localStorage` via `package:web`) or `legacy_store_stub.dart` (returns null), so `package:web` never reaches a mobile build.

### Rendering and theme

One token set in `core/theme/colors.dart` drives both `buildLightTheme()` and `buildDarkTheme()`. Theme mode is read from persisted settings at boot, so light mode persists (the fix for BUG-003).

Fonts are self-hosted variable fonts in `app/assets/fonts/`, declared in `pubspec.yaml` with OFL licenses committed. No `google_fonts` package, no runtime fetch. `fonts_test.dart` fails if a declared family stops being bundled.

Charts use `fl_chart`, confined to `features/dashboard/widgets/`. The 24-hour break-pattern chart is hand-laid-out rather than delegated to `fl_chart`.

---

## React architecture (deprecated legacy)

Deprecated/frozen single-page app, `useReducer` store in `src/context/AppContext.jsx`, persisted to `localStorage` by a `useEffect` on state. It is retained for rollback and migration verification; do not add product work here. Routes are `/`, `/dashboard`, `/achievements`, `/settings`, with an onboarding gate in `App.jsx`.

Known structural weaknesses, all addressed in the port:
* No versioning on the persisted blob.
* No validation on load or import — arbitrary JSON is shallow-merged.
* Achievement criteria live inside the page component, so they are not reusable.
* Currency formatting has no seam; the default `'USD'` argument hides the fact that most call sites omit it.
* Design tokens live in CSS files with no shared module.
* Running timer is component-local state.

---

## Build and deployment posture

| | React | Flutter |
|---|---|---|
| Build | `npm run build` → `dist/` | `flutter build web` → `app/build/web` |
| PWA | `vite-plugin-pwa` + Workbox | Flutter's generated service worker |
| Icons | **manifest references 3 files that do not exist** | 4 real generated icons, any + maskable |
| Deploy config | none | `app/vercel.json` (static, SPA rewrite, cache headers) |
| Deployed | not to a known target | **no project exists yet** |
| Android | n/a | builds, **debug-signed only** |
| iOS | n/a | never built |
| CI | none | none |

`app/vercel.json` sets `buildCommand: null`, so the web bundle must be built before deploy by something outside that file. No CI currently does this.

### First-load size

Flutter web is roughly **3.7 MB gzipped** against React's **~156 kB gzipped**. That is a ~24× regression on cold load, inherent to shipping CanvasKit. The decision to accept it is still open and is recorded as such in `docs/migration/qa_browser.md`.

---

## What does not exist in either app

Leaderboards, user accounts, backend sync, and social sharing beyond clipboard are described in `fuckcorpo-features.md` but have **no implementation anywhere**. Any statement that the product has them is wrong.
