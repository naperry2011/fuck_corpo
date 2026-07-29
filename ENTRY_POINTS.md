# ENTRY_POINTS

Generated: 2026-07-28 | commit 34e0f62 | by /code-map

All execution entry points. There is still no server, worker, cron job, or serverless handler in this repository. The executable surface is two client apps plus their build and asset scripts:

* React SPA (`src/`) — the reference/live app.
* Flutter app (`app/`) — web, Android, and iOS targets. Local MVP parity complete; not released.

---

# Flutter app (`app/`)

## Dart Bootstrap

Path: `app/lib/main.dart`
The only Dart entry point. Ensures the widget binding, opens `SharedPrefsStore`, runs `V0Migrator.run()` before `runApp`, then starts `ProviderScope` with `keyValueStoreProvider` overridden by the live store.
Depends on: `shared_preferences`, `flutter_riverpod`, `data/storage/shared_prefs_store.dart`, `data/migrations/v0_localstorage_to_v1.dart`, `app.dart`.

There are no flavors: no `main_dev.dart`/`main_prod.dart`, no `--flavor` config, no Gradle `productFlavors`.

## App Root

Path: `app/lib/app.dart`
`FuckCorpoApp`, a `MaterialApp.router`. Selects `themeMode` from persisted `settings.theme` (light mode survives reload) and wraps the child in `FcToastScope`.
Depends on: `core/theme/fc_theme.dart`, `state/providers.dart`, `widgets/fc_toast_scope.dart`.

## Router

Path: `app/lib/router.dart`
go_router config: `/welcome` onboarding gate plus a `ShellRoute` over the four main routes. `_ShellScaffold` feeds the ticker from live state.
Depends on: `go_router`, `widgets/fc_app_shell.dart`, all of `app/lib/features/`.

## Route Entries

| Route | Path | Responsibility | Key calls |
|---|---|---|---|
| `/` | `features/timer/timer_screen.dart` | Live timer, quick log, today's summary, recent breaks | `TimerController.start/stop`, `AppController.addBreak/deleteBreak`, toasts |
| `/dashboard` | `features/dashboard/dashboard_screen.dart` | Totals, fun fact, corporate memo, three charts, performance metrics, comparisons | `dashboard_metrics.dart` derivations, `fl_chart` renderers |
| `/achievements` | `features/achievements/achievements_screen.dart` | Badge evaluation, shareable earnings statement, executive comparison | `newlyUnlocked()`, `AppController.addAchievement`, `Clipboard.setData` |
| `/settings` | `features/settings/settings_screen.dart` | Compensation, profile, display prefs, data management, about, know-your-rights, v0 migration-failure notice, sync notice | `AppController.updateSettings/setSalary/replaceState`, `AppRepository.exportJson/importJson`, `Clipboard` |
| `/welcome` | `features/onboarding/landing_screen.dart` then `application_wizard.dart` | Hero plus the 5-step satirical job application that seeds salary and profile and sets `onboarded` | `AppController.setSalary`, `updateSettings`, `setOnboarded` |

Settings export and import are clipboard-based, not file-picker-based.

## Web Document Entry

Path: `app/web/index.html`
Custom HTML shell: OG/Twitter card meta pointing at `social/og-card.png` (1200x630), theme color `#0a1128`, apple-touch-icon, favicon, `manifest.json` link, and an inline `#fc-boot` splash removed on the `flutter-first-frame` event. Loads `flutter_bootstrap.js`.

## Android Entry

Paths: `app/android/app/src/main/AndroidManifest.xml`, `app/android/app/build.gradle.kts`
`MainActivity` LAUNCHER entry. applicationId `com.fuckcorpo.fuckcorpo`, Java 17. Stock manifest: no extra permissions, no deep links or intent filters beyond LAUNCHER.
Blocker: no release signing config. `release { signingConfig = signingConfigs.getByName("debug") }` still carries the stock template TODO, and no keystore or `key.properties` exists.

## iOS Entry

Path: `app/ios/Runner/Info.plist`
Stock Flutter scaffolding. Display name `Fuckcorpo`, SceneDelegate manifest, all orientations. Bundle id is still the unmodified `$(PRODUCT_BUNDLE_IDENTIFIER)` default.
Blocker: no Podfile committed, no signing, no App Store metadata. Never built (Windows host).

## Deploy Entry (Flutter web)

Path: `app/vercel.json`
Static deploy of `build/web` with `framework: null`, SPA rewrite `/(.*)` to `/index.html`, no-cache headers on `index.html` / `flutter_service_worker.js` / `flutter_bootstrap.js` / `manifest.json`, and 1-year immutable caching on `/assets/*`, `/canvaskit/*`, `/icons/*`.
Note: `buildCommand` is null, so `build/web` must be produced beforehand. No Vercel project exists yet.

## Asset and Font Scripts

* `app/tool/generate_brand_assets.py` — deterministic generation of all PWA icons, favicon, apple-touch-icon, and the OG card from design tokens (Pillow).
* `app/tool/fetch_fonts.sh` — fetches the three variable fonts and their OFL licenses from google/fonts into `app/assets/fonts/`.

## Build and Validation Commands

Run from `app/`:
* `flutter analyze` — static analysis
* `flutter test --reporter compact --concurrency=1` — 269 tests
* `flutter build web` — web bundle to `app/build/web`
* `flutter build apk --release` — Android APK (currently debug-signed)

---

# React app (`src/`), reference implementation

## Browser Document Entry

Path: `index.html`
HTML shell, mounts `#root`, loads fonts and the module script pointing at `src/main.jsx`. Served by the Vite dev server or from `dist/`.

## Client Bootstrap

Path: `src/main.jsx`
Creates the React root and nests providers: `BrowserRouter` > `AppProvider` > `ToastProvider` > `App`.
Depends on: `react`, `react-dom/client`, `react-router-dom`, `src/context/AppContext.jsx`, `src/context/ToastContext.jsx`, `src/index.css`.

## Route Root

Path: `src/App.jsx`
Onboarding gate and route table. Renders `Landing` when `state.onboarded` is false; otherwise `Layout` wrapping `/`, `/dashboard`, `/achievements`, `/settings`.

## Route Entries

| Route | Path | Responsibility | Key calls |
|---|---|---|---|
| `/` | `src/pages/Timer.jsx` | Break timing and manual logging | dispatch `ADD_BREAK` / `DELETE_BREAK`, `useToast`, `useSound` |
| `/dashboard` | `src/pages/Dashboard.jsx` | Aggregate stats and charts | `chart.js` registration, `react-chartjs-2`, `AnimatedCurrency` |
| `/achievements` | `src/pages/Achievements.jsx` | Badge evaluation and unlock display | dispatch `ADD_ACHIEVEMENT`, `useToast`, `useSound` |
| `/settings` | `src/pages/Settings.jsx` | Salary/settings edits, export, import, reset | `exportData`, `importData`, `clearData`; `SET_SALARY`, `UPDATE_SETTINGS`, `IMPORT_DATA`, `RESET` |
| pre-onboard | `src/pages/Landing.jsx` then `src/components/Application.jsx` | Multi-step application seeding salary/settings | dispatch `SET_SALARY`, `UPDATE_SETTINGS`, `SET_ONBOARDED` |

All route entries depend on `src/utils/calculations.js` and the shared component kit.

## Service Worker Registration

Path: `vite.config.js` (`VitePWA({ registerType: 'autoUpdate' })`)
Generates and auto-registers the Workbox service worker at build time; precaches build assets and runtime-caches Google Fonts. Depends on `vite-plugin-pwa`, `workbox-window`.

## Build and Dev Scripts

Path: `package.json` scripts
* `npm run dev` — Vite dev server
* `npm run build` — production build to `dist/` (validated as `npm run build -- --mode production`)
* `npm run preview` — serve the build
* `npm run lint` — ESLint over the repo

There is no CI configuration for either app; no `.github/` directory exists.
