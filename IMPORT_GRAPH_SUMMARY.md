# IMPORT_GRAPH_SUMMARY

Generated: 2026-07-28 | commit 34e0f62 | by /code-map

High-level dependency observations for both implementations. Not an exhaustive import list.

The two apps share **no code**. There is no import edge between `src/` and `app/`. The only coupling is a data contract: the Flutter v0 migration bridge reads the JSON shape that React writes to `localStorage`.

---

# Flutter app (`app/lib/`) — 57 Dart files

## Core Dependency Nodes

* `app/lib/state/providers.dart` — the hub. Every screen and most widgets watch `appControllerProvider`, `perMinuteRateProvider`, or `currencyProvider`. Declares `keyValueStoreProvider` as override-only (it throws `UnimplementedError` unless `main.dart` overrides it), which is what makes the whole tree testable.
* `app/lib/domain/models/app_state.dart` — the aggregate root and the persisted schema. Imported by the repository, the controller, the migrator, and every test helper. Any shape change ripples widest.
* `app/lib/core/format/currency_formatter.dart` — the single currency seam. Imported by every screen, the ticker, `AnimatedCurrency`, the corporate memo, and the earnings statement. This is the module whose absence in React caused BUG-002/BUG-009.
* `app/lib/domain/calculations.dart` — salary→rate, earnings, and half-open range filters. Imported by the timer, dashboard metrics, achievements, ticker, and providers.
* `app/lib/core/theme/*` — `colors.dart` → `fc_theme.dart` → every widget. `spacing.dart` and `typography.dart` are imported directly by most feature screens.
* `app/lib/widgets/fc_*.dart` — the design-system kit, reused across all five screens and the onboarding wizard.
* `app/lib/data/app_repository.dart` — imported by `providers.dart`, the migrator, and Settings. The only module that knows the storage key.

## Layering and Direction

Direction is consistently `main → app → router → features → widgets → domain/core`, with `state/` and `data/` as the crosscut beneath `features/`. Notably:

* `domain/` imports nothing from `features/`, `state/`, `widgets/`, or `data/`. It is pure and independently testable.
* `features/dashboard/dashboard_metrics.dart` is deliberately separated from `dashboard_screen.dart` so all chart derivations are pure functions with no Flutter dependency beyond types.
* `data/storage/legacy_store.dart` is a **conditional export shim** (`legacy_store_web.dart` on web, `legacy_store_stub.dart` elsewhere) so `package:web` never reaches a mobile build.

## Leaf / Zero-Dependency Modules

* `app/lib/core/theme/radii.dart`, `shadows.dart`, `spacing.dart`, `colors.dart`
* `app/lib/core/format/duration_formatter.dart`
* `app/lib/domain/copy/fun_facts.dart`, `app/lib/domain/comparisons.dart` (pure, injectable RNG)
* `app/lib/domain/models/break_category.dart`, `salary.dart`
* `app/lib/data/storage/key_value_store.dart` (interface only)

## Circular Dependencies

None observed. The toast system is split precisely to avoid one: `fc_toast_scope.dart` (inherited access) and `fc_toast_host.dart` (rendering) do not import the controller that feeds them.

## Dead / Unreachable by Design

* `app/lib/dev/widget_gallery.dart` — imports the whole widget kit but is imported by nothing. Not routed, mounted manually during development.

## Potential Refactor Risk Areas

* `app/lib/domain/models/app_state.dart` — persisted schema; a change requires a v2 migration, not just a code edit.
* `app/lib/state/app_controller.dart` — single write path; every mutation funnels through `_commit()`.
* `app/lib/domain/models/app_settings.dart` — carries two legacy compatibility warts: `region` serializes under the JSON key `state`, and `timezone` is `@Deprecated` but retained for import compatibility. Both are easy to "clean up" and thereby break v0 imports.
* `app/lib/features/dashboard/widgets/break_pattern_chart.dart` — 24 bars laid out by hand rather than through `fl_chart`.
* `app/test/web/*` — asserts against non-Dart artifacts (`web/manifest.json`, `web/index.html`, `vercel.json`, icon byte sizes). Editing those files without running the suite will fail tests in a non-obvious place.

## External Package Coupling

* `flutter_riverpod` — `providers.dart`, all controllers, every screen
* `go_router` — `router.dart`, `app.dart`, `fc_navbar.dart`
* `shared_preferences` — `data/storage/shared_prefs_store.dart` **only**
* `fl_chart` — `features/dashboard/widgets/` only
* `web` — `data/storage/legacy_store_web.dart` only (web-conditional)
* `uuid` — `state/timer_controller.dart` only
* `intl` — `core/format/currency_formatter.dart` only

Each third-party package is confined to a single module or folder, so any one of them can be swapped without a repo-wide edit.

---

# React app (`src/`) — reference implementation

## Core Dependency Nodes

* `src/context/AppContext.jsx` — imported by every page, `Ticker`, `Application`, and `useSound`. Sole source of app state and `perMinuteRate`.
* `src/utils/calculations.js` — imported by `AppContext`, `Timer`, `Dashboard`, `Achievements`, `Settings`, `Ticker`, `AnimatedCurrency`. Widest-reach utility module.
* `src/utils/storage.js` — imported by `AppContext` and `Settings`. Only module touching `localStorage`.
* `src/context/ToastContext.jsx` — imported by `main.jsx`, `Timer`, `Achievements`, `Settings`.
* `src/components/shared/Card.jsx`, `Button.jsx`, `PageTransition.jsx` — reused across all pages and the onboarding flow.
* `src/utils/funFacts.js` — imported by `Timer` and `Dashboard` for satirical copy.

## Leaf / Zero-Dependency Modules

* `src/components/shared/Button.jsx`, `Card.jsx`, `PageTransition.jsx` (CSS import only)
* `src/components/shared/Toast.jsx` (icons + CSS)
* `src/utils/calculations.js`, `src/utils/funFacts.js` (pure, no internal imports)

## Circular Dependencies

None observed. `ToastContext` imports the presentational `Toast` component, which does not import back into context. Direction is consistently `main → App → pages → shared/hooks → utils`.

## Potential Refactor Risk Areas

* `src/context/AppContext.jsx` (single store for salary, breaks, settings, achievements, and onboarding; any shape change touches all pages and `storage.js` defaults)
* `src/utils/calculations.js` (broadest fan-in; signature changes ripple to seven consumers)
* `src/utils/storage.js` (`defaultData` shape is duplicated implicitly by reducer assumptions in `AppContext`)
* `src/pages/Dashboard.jsx` (largest page; combines chart registration, range selection, memoized aggregation, and satirical copy)
* `src/pages/Achievements.jsx` (achievement definitions and unlock criteria live in the page rather than in `utils/`, so they are not reusable by `Dashboard` or `Ticker`)
* CSS is co-located per component with no shared token module in `src/`; design tokens live in `fuckcorpo-design-system.md` and `src/index.css`.

The Flutter port resolves the last two structurally: unlock criteria moved to `domain/achievements_catalog.dart`, and tokens moved to `core/theme/`.

## External Package Coupling

* `react-router-dom` — `main.jsx`, `App.jsx`, `Navbar.jsx`
* `chart.js` / `react-chartjs-2` — `Dashboard.jsx` only
* `lucide-react` — `Navbar`, `Toast`, `Timer`, `Application`
* `vite-plugin-pwa` / `workbox-window` — build-time only, `vite.config.js`
