# DATA_FLOW

Generated: 2026-07-28 | commit 34e0f62 | by /code-map

All data movement is on-device. There is no API, database, queue, or third-party data service in either implementation. The one network dependency in the React app (Google Fonts) is **removed** in the Flutter app, which self-hosts its fonts.

Two independent stores now exist. They do **not** sync with each other, and web and mobile do not sync either:

| App | Store | Key | Versioned |
|---|---|---|---|
| React | `localStorage` | `fuckcorpo_data` | no |
| Flutter | `shared_preferences` | `fuckcorpo_state_v1` | yes, `schemaVersion = 1` |

---

# Flutter app (`app/`)

## Boot Migration (v0 → v1)

Source: React's `localStorage` key `fuckcorpo_data`
Transport: `V0Migrator.run()` in `app/lib/main.dart`, **before** `runApp`. On web it reads raw unprefixed `localStorage` through `LegacyStore` (`package:web`), because `shared_preferences` namespaces web keys under `flutter.`.
Processor: `app/lib/data/migrations/v0_localstorage_to_v1.dart`
Decision order: existing v1 payload wins → migration marker wins → otherwise read and convert v0.
Storage: writes `fuckcorpo_state_v1` plus the marker `fuckcorpo_migrated_from_v0`. On parse failure it copies the payload to `fuckcorpo_data_backup`, sets the marker and `fuckcorpo_v0_migration_failed`, and boots to defaults.
Guarantee: `fuckcorpo_data` is **read-only** — never written, never deleted, so React can always be rolled back to.
Downstream Consumers: `AppController.build()`, and `migrationNoticeProvider`, which surfaces the failure notice in Settings.

---

## Onboarding Intake

Source: `app/lib/features/onboarding/application_wizard.dart` (5 steps, via `landing_screen.dart`)
Transport: `AppController.setSalary` / `updateSettings` / `setOnboarded`
Processor: `app/lib/state/app_controller.dart` `_commit()` — sets state, then writes through
Storage: `AppRepository.save` → `SharedPrefsStore.write('fuckcorpo_state_v1', json)`
Downstream Consumers: the `/welcome` router gate, every route

---

## Break Logging

Source: `app/lib/features/timer/timer_screen.dart` (timer start/stop or quick log)
Transport: `TimerController.start(category)` persists a `RunningTimer(startedAt: clock())` immediately, so an in-flight break **survives reload and navigation**. `stop()` computes `elapsed = now - startedAt` (clamped at zero) from wall clock, clears the running timer, and only creates a `BreakRecord` (uuid v4) if elapsed exceeds 1s.
Processor: `app/lib/state/timer_controller.dart` → `AppController.addBreak` / `deleteBreak` → `_commit()`
Storage: `state.breaks[]` inside the v1 payload
Downstream Consumers: `dashboard_metrics.dart`, `achievements_catalog.dart`, `FcTicker.buildItems`. A `TimerStopResult` is returned to the screen and rendered as a toast, including the "discarded, too short" case.

---

## Persistence Loop

Source: any `AppController` mutation
Transport: `_commit()` — sets state, then fire-and-forget `repository.save()`
Processor: `app/lib/data/app_repository.dart`
Storage: `shared_preferences` key `fuckcorpo_state_v1`
Downstream Consumers: `AppController.build()` on next boot, which reads **synchronously** from the warmed `shared_preferences` cache so frame 1 renders real data rather than defaults.

---

## Derived Stats and Charts

Source: `state.breaks` + `perMinuteRateProvider`
Transport: Riverpod watch into `app/lib/features/dashboard/dashboard_screen.dart`
Processor: `app/lib/features/dashboard/dashboard_metrics.dart` — pure derivations: 7-day series, 24-hour histogram plus labels, category counts, four performance metrics, memo addressee. Range filters in `app/lib/domain/calculations.dart` are half-open.
Storage: none (recomputed)
Downstream Consumers: `earnings_line_chart.dart`, `category_doughnut.dart`, `break_pattern_chart.dart`, `AnimatedCurrency`

---

## Achievement Unlocks

Source: `state.breaks` and total earnings evaluated in `achievements_screen.dart`
Transport: `newlyUnlocked(breaks, totalEarnings, held)` → `AppController.addAchievement(id)` per fresh badge (dedup guard in the controller)
Processor: `app/lib/domain/achievements_catalog.dart` (11 badges with unlock predicates)
Storage: `state.achievements[]` in the v1 payload
Downstream Consumers: Achievements UI, toast controller. The shareable statement is built by `earnings_statement.dart` and pushed to `Clipboard.setData`.

---

## Data Export / Import

Source: user action in `app/lib/features/settings/settings_screen.dart`
Transport: **clipboard**, not a file picker or share sheet (no `file_picker` / `share_plus` dependency)
Processor: `AppRepository.exportJson(state)` produces pretty JSON; `importJson` validates and throws `FormatException` on bad data so existing state survives a failed import
Storage: clipboard (export); v1 key via `AppController.replaceState` (import)
Reset: `AppState.initial` + `repository.clear()`, applied without requiring a reload
Downstream Consumers: whole app state

---

## Currency and Theme Propagation

Source: `state.settings`
Transport: `currencyProvider` watches `settings.currency`; `app.dart` watches `settings.theme`
Processor: every money figure routes through the single seam `app/lib/core/format/currency_formatter.dart`, which honours the selected currency and its fraction digits (including zero-decimal currencies)
Storage: n/a (read path)
Downstream Consumers: all screens, ticker, charts. Theme mode is read from storage at boot, so light mode persists across reloads.

---

## Asset Loading (Flutter web)

Source: `app/build/web` output only
Transport: Flutter's generated `flutter_service_worker.js`; static hosting rules in `app/vercel.json`
Processor: none at runtime
Storage: browser cache, per the `vercel.json` header rules (immutable for `/assets/*`, `/canvaskit/*`, `/icons/*`; no-cache for the shell)
Downstream Consumers: offline app loads

**No font CDN request.** Fonts are bundled from `app/assets/fonts/`, so the "no tracking" claim holds for the Flutter app in a way it does not for React.

---

# React app (`src/`) — reference implementation

## Onboarding Intake

Source: `src/components/Application.jsx` form steps (via `src/pages/Landing.jsx`)
Transport: React context dispatch (`SET_SALARY`, `UPDATE_SETTINGS`, `SET_ONBOARDED`)
Processor: reducer in `src/context/AppContext.jsx`
Storage: `localStorage` key `fuckcorpo_data` via `saveData`
Downstream Consumers: `src/App.jsx` onboarding gate, every route

---

## Break Logging

Source: `src/pages/Timer.jsx` (timer stop or manual entry)
Transport: dispatch `ADD_BREAK` / `DELETE_BREAK`
Processor: `AppContext` reducer; `src/utils/calculations.js` for rate and earnings math
Storage: `state.breaks[]` persisted to `localStorage`
Downstream Consumers: `Dashboard`, `Achievements`, `components/layout/Ticker.jsx`

Note: the in-flight timer is component-local state, so it is lost on reload or navigation.

---

## Persistence Loop

Source: `AppContext` state (any change)
Transport: `useEffect` on `state` in `src/context/AppContext.jsx`
Processor: `saveData` in `src/utils/storage.js`
Storage: `localStorage` key `fuckcorpo_data`
Downstream Consumers: `loadData` on next app boot, seeding `initialState`

---

## Derived Stats and Charts

Source: `state.breaks` + `perMinuteRate` from `AppContext`
Transport: props / `useMemo` inside `src/pages/Dashboard.jsx`
Processor: range selectors and totals in `src/utils/calculations.js`; copy from `src/utils/funFacts.js`
Storage: none (recomputed per render)
Downstream Consumers: `react-chartjs-2` Line/Bar/Doughnut, `AnimatedCurrency`

---

## Achievement Unlocks

Source: `state.breaks` evaluated in `src/pages/Achievements.jsx`
Transport: dispatch `ADD_ACHIEVEMENT` (deduplicated in the reducer)
Processor: `AppContext` reducer
Storage: `state.achievements[]` in `localStorage`
Downstream Consumers: `Achievements` UI, `ToastContext` notifications, `useSound`

---

## Data Export / Import

Source: user action in `src/pages/Settings.jsx`
Transport: `Blob` + object URL download (export); file text read (import)
Processor: `exportData` / `importData` / `clearData` in `src/utils/storage.js`
Storage: JSON file on disk (export); `localStorage` (import, then dispatch `IMPORT_DATA` / `RESET`)
Downstream Consumers: whole app state on rehydrate

---

## Asset Caching

Source: build output and `https://fonts.googleapis.com` / `fonts.gstatic.com`
Transport: generated service worker (Workbox)
Processor: `VitePWA` config in `vite.config.js` (precache glob + CacheFirst runtime rules)
Storage: Cache Storage (`google-fonts-cache`, `gstatic-fonts-cache`)
Downstream Consumers: offline app loads

Note: this outbound font request is the reason the React app's "no tracking, 100% private" claim is qualified.
