# CODE_MAP

Generated: 2026-07-28 | commit 34e0f62 | by /code-map

Feature-oriented index of the repository. Descriptive only.

## Repository Shape

Two implementations of the same product:

| | React app (deprecated legacy) | Flutter app (forward) |
|---|---|---|
| Location | `src/`, `index.html`, `vite.config.js` | `app/` |
| Status | Deprecated/frozen. Retained for rollback and real-profile migration verification until cutover/archive gates pass. | Forward implementation. Local MVP parity complete; public release/cutover gates still open. |
| Stack | React 19, Vite 7, react-router-dom 7, Chart.js, vite-plugin-pwa | Flutter (Dart SDK ^3.12.2), Riverpod 3, go_router 17, fl_chart 1 |
| Tests | none | 30 files, 269 tests, all passing |
| Storage | `localStorage` key `fuckcorpo_data` | `shared_preferences` key `fuckcorpo_state_v1` |

Parity scope is the planned local MVP. React is now deprecated/frozen, but it remains the rollback and migration reference until release/cutover gates pass. Release/cutover parity (staging deploy, real-profile migration, Android signing, iOS/defer decision, owner approval) is a separate open track. See `docs/migration/react_deprecation.md`, `docs/migration/release_readiness.md`, and `FEATURE_BOUNDARIES.md`.

Neither app has a backend. All state is client-side.

---

# Part 1: Flutter app (`app/`)

57 Dart files under `app/lib/`. Most carry a doc comment naming their React counterpart and the BUG-/D- IDs they resolve.

## App Shell and Routing (UI)

`main.dart` (binding init, store open, v0 migration, `ProviderScope`), `app.dart` (`MaterialApp.router`, theme mode, toast scope), `router.dart` (go_router), `widgets/fc_app_shell.dart`, `fc_navbar.dart`, `fc_ticker.dart`.

Routes: `/` Timer, `/dashboard`, `/achievements`, `/settings`, `/welcome` Landing. The `/welcome` gate is driven by `state.onboarded`.

## Global State and Persistence (Service)

`state/providers.dart` (store, repository, clock, controller, per-minute rate, currency), `state/app_controller.dart` (`Notifier<AppState>`, write-through on every mutation), `data/app_repository.dart` (load/save/clear/export/import), `data/storage/key_value_store.dart`, `shared_prefs_store.dart`.

State: `AppState { schemaVersion, salary, breaks[], settings, achievements[], onboarded, runningTimer? }`, `currentSchemaVersion = 1`.

Storage keys:
* `fuckcorpo_state_v1` — v1 payload
* `fuckcorpo_data` — React v0 payload, read-only; never written or deleted
* `fuckcorpo_data_backup` — preserved copy of an unparseable v0 payload
* `fuckcorpo_migrated_from_v0` — one-shot migration marker
* `fuckcorpo_v0_migration_failed` — drives the Settings failure notice

`shared_preferences` namespaces web keys under `flutter.`, hence the raw-`localStorage` escape hatch below.

## v0 Migration Bridge (Service)

`data/migrations/v0_localstorage_to_v1.dart` (`V0Migrator`, `V0MigrationStatus`), `data/storage/legacy_store.dart` (conditional export shim) with `legacy_store_web.dart` (raw `localStorage` via `package:web`) and `legacy_store_stub.dart`, `state/migration_notice_controller.dart`.

Runs once in `main()` before `runApp`. Precedence: existing v1 payload > migration marker > read `fuckcorpo_data`. Parse failure backs the payload up and boots to defaults with a Settings notice.

## Domain Layer

`domain/calculations.dart` (salary to per-minute, earnings, half-open date ranges, time ago), `comparisons.dart` (priced-item catalog), `achievements_catalog.dart` (11 badges, `newlyUnlocked()`), `copy/fun_facts.dart`, `copy/corporate_memo.dart` (injectable RNG / currency), `domain/models/` (`app_state`, `app_settings`, `salary`, `break_record`, `break_category`, `running_timer`).

Notes: `BreakCategory` owns label, emoji, chart color. `AppSettings.region` serializes under the legacy JSON key `state`; `timezone` is `@Deprecated`, kept for import compatibility. `BreakRecord.tryFromJson` drops malformed rows rather than failing the whole load.

## Feature Screens (Page)

* Timer: `features/timer/timer_screen.dart`, `widgets/category_chip_row.dart`, `break_list_item.dart`
* Dashboard: `features/dashboard/dashboard_screen.dart`, `dashboard_metrics.dart` (pure derivations), `widgets/earnings_line_chart.dart`, `category_doughnut.dart`, `break_pattern_chart.dart`
* Achievements: `features/achievements/achievements_screen.dart`, `earnings_statement.dart` (CEO-rate constants, ASCII clipboard payload)
* Onboarding: `features/onboarding/landing_screen.dart`, `application_wizard.dart` (5-step satirical application)
* Settings: `features/settings/settings_screen.dart` (compensation, profile, display, data management, about, know-your-rights, migration notice, sync notice)

Timer control lives in `state/timer_controller.dart`. The running timer is persisted (`RunningTimer.startedAt`), so elapsed time derives from wall clock and survives reload and navigation. Breaks under 1s are discarded.

## Design System (UI)

`core/theme/` (`colors`, `fc_theme`, `radii`, `shadows`, `spacing` with 8pt scale and breakpoints, `typography`), `core/format/` (`currency_formatter.dart` single currency seam, `duration_formatter.dart`), `widgets/` (`fc_button` 4 variants x 3 sizes, `fc_card`, `fc_dropdown`, `fc_text_field`, `fc_switch`, `animated_currency` easeOutExpo 1500ms, `fc_toast`, `fc_toast_host`, `fc_toast_scope`).

Fonts are self-hosted variable fonts in `app/assets/fonts/` (Playfair Display, Work Sans, Roboto Mono) with OFL licenses committed. No `google_fonts` package, no runtime font fetch.

Dev-only: `app/lib/dev/widget_gallery.dart` is not routed and not reachable; it is mounted manually during development.

## Web / PWA / Deploy (Infra)

`app/web/index.html` (OG/Twitter meta, theme color, inline `#fc-boot` splash removed on `flutter-first-frame`), `app/web/manifest.json` (4 icons, any + maskable, standalone, `#0a1128`), `app/web/icons/`, `favicon.png`, `social/og-card.png` (real generated assets), `app/vercel.json` (static deploy of `build/web`, SPA rewrite, cache headers; `buildCommand: null`), `app/tool/generate_brand_assets.py`, `app/tool/fetch_fonts.sh`.

## Native Platforms (Infra)

* `app/android/app/build.gradle.kts` — applicationId `com.fuckcorpo.fuckcorpo`, Java 17. No release signing config: release still uses debug signing, and no keystore or `key.properties` exists. Hard blocker for an Android release build.
* `app/android/app/src/main/AndroidManifest.xml` — stock; no extra permissions, no deep links.
* `app/ios/Runner/Info.plist` — stock scaffolding; bundle id still the Xcode default variable. No Podfile, signing, or App Store metadata.
* Android launcher icons are still stock Flutter `ic_launcher` mipmaps. Web branding complete; native branding is not.

## Tests

`app/test/` — 30 files, 269 tests, all passing. Notable: `test/web/pwa_config_test.dart` validates `manifest.json`, `index.html`, `vercel.json`; `test/web/brand_assets_test.dart` pins generated icon sizes; `test/core/theme/fonts_test.dart` fails if a declared font stops being bundled. Helpers in `app/test/helpers/`.

---

# Part 2: React app (`src/`), deprecated legacy implementation

React 19 + Vite 7 SPA, `react-router-dom` v7, `vite-plugin-pwa`, Chart.js via `react-chartjs-2`, `lucide-react`. No backend, no test suite, no TypeScript. Deprecated/frozen: do not add product work here unless explicitly required by `docs/migration/react_deprecation.md`.

## App Shell and Routing (UI)

`src/main.jsx` (root render, provider nesting, `BrowserRouter`), `src/App.jsx` (route table, onboarding gate), `src/components/layout/Layout.jsx`, `Navbar.jsx`, `Ticker.jsx`; `src/index.css`, `src/App.css`, layout CSS, `index.html`.

Entry: `index.html` to `src/main.jsx`. Routes mirror the Flutter app; when `state.onboarded` is false, `App.jsx` renders `Landing` instead of the outlet.

## Global State and Persistence (Service)

`src/context/AppContext.jsx` (`useReducer` store, `useApp`, derived `perMinuteRate`), `src/utils/storage.js` (`loadData`, `saveData`, `exportData`, `importData`, `clearData`).

State `{ salary, breaks[], settings, achievements[], onboarded }`, unversioned. Actions: `SET_SALARY`, `ADD_BREAK`, `DELETE_BREAK`, `UPDATE_SETTINGS`, `ADD_ACHIEVEMENT`, `SET_ONBOARDED`, `IMPORT_DATA`, `RESET`. Integrations: `localStorage` key `fuckcorpo_data`, `Intl.DateTimeFormat`.

## Pages

* Onboarding: `src/pages/Landing.jsx`, `src/components/Application.jsx` (multi-step satirical job application) — writes `SET_SALARY`, `UPDATE_SETTINGS`, `SET_ONBOARDED`
* Timer: `src/pages/Timer.jsx` with `src/hooks/useSound.js` — dispatches `ADD_BREAK` / `DELETE_BREAK`, toasts via `ToastContext`. Running timer is component-local, so it does not survive reload (the Flutter port fixes this)
* Dashboard: `src/pages/Dashboard.jsx` with `AnimatedCurrency`, `useCountUp`, `chart.js` / `react-chartjs-2` (Line, Bar, Doughnut)
* Achievements: `src/pages/Achievements.jsx` — dispatches `ADD_ACHIEVEMENT`; unlock criteria computed in-page from `state.breaks`
* Settings: `src/pages/Settings.jsx` — export to JSON file, import, clear via `src/utils/storage.js`

Each page has a co-located `.css` file.

## Shared UI Kit and Domain (UI / Other)

`src/components/shared/Button.jsx`, `Card.jsx`, `Toast.jsx`, `PageTransition.jsx`, `AnimatedCurrency.jsx`, `src/context/ToastContext.jsx`, `src/hooks/useCountUp.js`.

`src/utils/calculations.js` (per-minute rate, earnings, currency/duration formatting, date ranges, totals, comparisons), `src/utils/funFacts.js` (satirical copy plus `getCorporateMemo`).

## PWA / Build / Tooling (Infra)

`vite.config.js` (React plugin, `VitePWA` manifest, Workbox precache and Google Fonts runtime caching), `package.json` (`dev`, `build`, `lint`, `preview`), `eslint.config.js`, `public/favicon.svg`, `public/vite.svg`.

Known gap: the React PWA manifest references `/icon-192.png` and `/icon-512.png`, which are not present in `public/`. The Flutter app does not share this gap.

---

## Specifications and Docs (not executable)

`fuckcorpo-design-system.md`, `fuckcorpo-features.md`, `CLAUDE.md`, `README.md`, `llms.txt`, `docs/ai/` (memory, tasks, roadmap, decisions, architecture), `docs/audit/`, `docs/migration/` (parity matrix, QA sweeps, cutover plan, release readiness), `image.png`.

Leaderboards, accounts, and backend sync described in the specs have no implementation in either app.
