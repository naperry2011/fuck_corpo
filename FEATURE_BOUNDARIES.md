# FEATURE_BOUNDARIES

Generated: 2026-07-28 | commit 34e0f62 | by /code-map

Component responsibility boundaries. Created at this refresh because the repository now contains two implementations, which introduces boundaries that did not exist in the React-only layout.

---

## Boundary 0: React app vs Flutter app

The hardest boundary in the repo.

| | React (`src/`) | Flutter (`app/`) |
|---|---|---|
| Role | Deprecated/frozen legacy app | Forward implementation; local MVP parity complete |
| Owns | Rollback path and migration reference until cutover/archive gates pass | Product work and future user-facing behaviour |
| Shared code | **none** | **none** |
| Shared contract | The v0 JSON shape written to `localStorage` key `fuckcorpo_data` | Reads that shape once, at first boot |

Rules:
* No import edge exists or should be created between `src/` and `app/`.
* React's `fuckcorpo_data` key is **read-only from Flutter**. Never write or delete it — it is the rollback path.
* Behaviour changes during the migration window should land in **both** apps, or be explicitly recorded as a deviation in `docs/migration/deviations.md`.
* React is deprecated for product work, but must remain rollback-safe until the release/cutover gates in `docs/migration/cutover_plan.md` are approved in writing. See `docs/migration/react_deprecation.md`.

---

## Boundary 1: `domain/` is pure

`app/lib/domain/` owns all business rules: salary→rate conversion, earnings math, date-range selection, achievement unlock predicates, comparison pricing, and satirical copy generation.

Responsibilities:
* Owns: what a break is worth, when a badge unlocks, what a range contains.
* Must not: import `flutter_riverpod`, `go_router`, `shared_preferences`, or anything in `features/`, `state/`, `data/`, or `widgets/`.
* Randomness and currency are **injected**, never read from ambient state, so tests are deterministic.

This is why the domain layer carries the densest test coverage in the repo.

---

## Boundary 2: `data/` owns persistence, nothing else

`app/lib/data/` is the only layer that knows a storage key exists.

Responsibilities:
* `app_repository.dart` owns the key `fuckcorpo_state_v1` and the JSON round trip.
* `storage/key_value_store.dart` is the interface; `shared_prefs_store.dart` is the only production implementation.
* `storage/legacy_store*.dart` is the web-conditional raw-`localStorage` escape hatch, needed because `shared_preferences` namespaces web keys under `flutter.`.
* `migrations/` owns v0→v1 and any future version step.

Must not: contain business rules, or be imported directly by a screen. Screens go through `state/`.

---

## Boundary 3: `state/` is the only write path

`app/lib/state/app_controller.dart` is the single funnel for mutations. Every mutator calls `_commit()`, which sets state and then persists.

Responsibilities:
* Owns: the current `AppState`, and the guarantee that state and storage never diverge.
* `timer_controller.dart` owns start/stop semantics, the 1s minimum, and id generation.
* `toast_controller.dart` owns the toast queue and its 3.5s auto-dismiss.
* `migration_notice_controller.dart` owns the read/dismiss lifecycle of the v0 failure flag.

Must not: a screen may never call `AppRepository.save` directly.

---

## Boundary 4: `features/` renders, `dashboard_metrics` derives

Screens own layout and interaction only.

* `features/dashboard/dashboard_metrics.dart` holds every derivation (7-day series, 24-hour histogram, category counts, performance metrics) as pure functions, separate from `dashboard_screen.dart`.
* `features/achievements/earnings_statement.dart` owns the CEO-rate constants and the exact ASCII clipboard payload, separate from the screen.

Rule: if a computation can be tested without pumping a widget, it belongs beside the screen as a pure file, not inside it.

---

## Boundary 5: `widgets/` is product-agnostic, `core/theme` is token-only

* `app/lib/widgets/fc_*.dart` is the design-system kit. It knows about variants, sizes, and tokens, not about breaks, salary, or achievements.
* `app/lib/core/theme/` holds tokens only — colors, radii, shadows, spacing, typography — and is imported by everything, importing nothing.
* `app/lib/dev/widget_gallery.dart` exercises the kit and is intentionally unreachable from the app.

---

## Boundary 6: `core/format` is the single formatting seam

All currency rendering goes through `currency_formatter.dart`; all elapsed-time rendering through `duration_formatter.dart`.

This boundary exists specifically because the React app lacked it: 12 of 14 call sites omitted the currency argument, so the currency setting silently did nothing (F-003 / BUG-002), and zero-decimal currencies rendered wrongly (BUG-009).

Rule: no screen may call `NumberFormat` or `toStringAsFixed` on a money value directly.

---

## Boundary 7: web assets are test-guarded

`app/test/web/` asserts against files that are not Dart:

* `pwa_config_test.dart` → `app/web/manifest.json`, `app/web/index.html`, `app/vercel.json`
* `brand_assets_test.dart` → generated icon byte sizes
* `core/theme/fonts_test.dart` → fails if a declared font family stops being bundled

Rule: editing web config, icons, or font declarations requires running the Flutter suite. These are the least obvious test failures in the repo.

---

## Boundary 8: platform release config is out of scope for app code

Native release concerns live entirely outside `lib/` and are **not** satisfied by code parity:

* `app/android/app/build.gradle.kts` — signing config (currently debug-signed; the hard Android blocker)
* `app/ios/` — Podfile, signing, App Store metadata (none committed)
* `app/vercel.json` — hosting rules (no Vercel project exists yet)

Rule: "the Flutter app is at parity" refers to `lib/` behaviour against `src/`. It does not imply any of the above is done. Release/cutover gates are tracked separately in `docs/migration/release_readiness.md` and `docs/migration/cutover_plan.md`.

---

## Documentation Boundaries

| Directory | Owns |
|---|---|
| `docs/ai/` | Working memory, tasks, roadmap, decisions, architecture for AI-assisted sessions |
| `docs/audit/` | Point-in-time audit findings, severity-labelled (VERIFIED / STATIC-ONLY / HYPOTHESIS) |
| `docs/migration/` | React→Flutter parity tracking, QA sheets, cutover and release gates |
| Root `*.md` index files | Navigation for the current repo state |
| `fuckcorpo-design-system.md`, `fuckcorpo-features.md` | Product and design source of truth for **both** apps |

Rule: audit findings keep their original IDs and severity labels permanently. When a finding is resolved, annotate its status rather than deleting it, so the register stays traceable.
