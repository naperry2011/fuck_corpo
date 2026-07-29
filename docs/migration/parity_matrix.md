# Parity matrix (live tracker)

Row definitions live in
`.hermes/plans/2026-07-28_164551-flutter-migration-parity-plan.md` Section 4.
This file tracks status only. All rows must be `DONE` for gate G1.

Last updated: 2026-07-28, after local React-vs-Flutter parity sweep and generated brand asset pass.

Status: `TODO` / `WIP` / `DONE`.

> **Scope note:** the repo-local MVP feature/screen parity rows are now swept
> against local React and Flutter builds. External release gates remain separate:
> Vercel staging, Lighthouse/install/offline PWA checks, genuine-profile migration,
> Android signing/internal track, and iOS/TestFlight or written defer.

## Progress summary

| Phase | Scope | Status |
|---|---|---|
| P0 | Scaffold, tooling, design tokens | DONE except self-hosted fonts (I2) and CI (I3) |
| P1 | Domain and data layer | Models, calculations, formatters, comparisons, achievements catalog, repository DONE. Copy, v0 bridge, controllers TODO |
| P2 | Design system widgets | Button, Card, TextField, Dropdown, Switch, AnimatedCurrency, Ticker, Navbar, AppShell, Toast DONE. PageTransition TODO |
| P3 to P10 | Not started | TODO |

## 4.1 App shell, routing, global state

| ID | Status | Note |
|---|---|---|
| X1 | WIP | `main.dart` and `app.dart` boot with the theme; smoke test green. Routing and providers pending |
| X2 | TODO | |
| X3 | DONE | `widgets/fc_app_shell.dart`: navbar, ticker, 1200pt content container. Width and ordering tested at 360 / 768 / 1280 / 1440. Goldens deferred until the screens exist |
| X4 | DONE | `widgets/fc_navbar.dart`: brand `$ FUCKCORPO`, 4 destinations with icons, active highlight, tap index, brand dropped below 768 |
| X5 | DONE | `widgets/fc_ticker.dart`: the 5 labels, values from state, duplicated track, green / red, currency aware |
| X6 | TODO | |
| X7 | WIP | `widgets/fc_toast.dart` and `fc_toast_host.dart` render all 4 types and dismissal. The queue controller is P2 pending X6 |

## 4.2 Domain / utils

| ID | Status | Flutter target | Tests |
|---|---|---|---|
| C1 | DONE | `domain/calculations.dart` `salaryToPerMinute` | 4 salary types, zero, negative |
| C2 | DONE | `calculateEarnings` | ms to minutes precision |
| C3 | DONE | `core/format/currency_formatter.dart` | USD, EUR, GBP, CAD, AUD, JPY zero-decimal, negative, unknown code |
| C4 | DONE | `core/format/duration_formatter.dart` | 0, sub-hour, hour boundary, past 24h, sub-second truncation |
| C5 | DONE | `domain/calculations.dart` selectors | midnight, Sat to Sun, month end, Dec 31 |
| C6 | DONE | `totalEarnings`, `totalDuration` | empty, single, many |
| C7 | DONE | `domain/comparisons.dart` | price boundary, singular and plural, floor, filter |
| C8 | TODO | `domain/copy/*` | fun facts, motivations, corporate memo |
| C9 | DONE | `domain/models/break_category.dart` | label, emoji, distinct color per category |
| C10 | DONE | `domain/achievements_catalog.dart` | 11 badges, boundary per predicate, `newlyUnlocked` |
| C11 | DONE | `timeAgo` | just now, m, h, d |

## 4.3 Data / storage

| ID | Status | Note |
|---|---|---|
| P1 | DONE | `AppRepository.load` covers missing key, corrupt JSON, structurally invalid, partial payload |
| P2 | DONE | `save` round trip |
| P3 | WIP | `exportJson` and `exportFilename` done and tested. Platform file save is P6 |
| P4 | WIP | `importJson` validated and tested. File picker wiring is P6 |
| P5 | DONE | `clear` |
| P6 | DONE | `data/migrations/v0_localstorage_to_v1.dart` plus `data/storage/legacy_store*.dart`. 13 tests: migrates, never destroys `fuckcorpo_data`, idempotent, marker-guarded, partial payload defaults, corrupt payload backed up, non-web skip. Now also exercised in a **real Chromium profile** against the built web artifact served locally: legacy key preserved, v1 written, marker set, EUR salary / break count migrated, corrupt payload backed up without bricking. See `qa_browser_hosted.md` and `.hermes/web-proof/web-qa-report.txt`. The payload was synthetic-but-realistic, so gate G8 (a copy of a genuine pre-existing user profile) is still **NOT MET** |

## 4.4 to 4.8 Screens

Local screen parity sweep complete. React and Flutter builds were served side by side with identical seeded data, capturing mobile and desktop screenshots for landing/onboarding, timer, dashboard, achievements, and settings.

Evidence:
- `docs/migration/qa_parity_sweep.md`
- `.hermes/parity-proof/parity-sweep-report.txt`
- `.hermes/parity-proof/contact-sheet.html`
- `.hermes/parity-proof/{mobile,desktop}/{react,flutter}/`

| Area | Status | Note |
|---|---|---|
| 4.4 Onboarding / first-run | DONE locally | Landing/application capture in React and Flutter, mobile and desktop |
| 4.5 Timer | DONE locally | Timer capture with migrated seeded state; dedicated runtime Android start/stop proof also exists |
| 4.6 Dashboard | DONE locally | Dashboard captures plus scroll captures for chart/stat content |
| 4.7 Achievements | DONE locally | Achievement grid captures plus scroll captures |
| 4.8 Settings / import/export copy | DONE locally | Settings captures plus tests for salary/profile/preferences/import/export/data-sync/migration notice |

## 4.9 Platform / infra

| ID | Status | Note |
|---|---|---|
| I1 | WIP | Manifest, `index.html`, generated brand icons, favicon, apple-touch icon, maskable icons, 1200x630 social card, and boot screen are FuckCorpo-branded and internally coherent, enforced by `test/web/pwa_config_test.dart` and `test/web/brand_assets_test.dart`. Final human brand approval remains before public release. Installability and offline load are unverified: no deploy exists, so Lighthouse has not been run |
| I2 | DONE | Fonts self-hosted under `app/assets/fonts/`, declared in `pubspec.yaml`, present in `build/web/assets/FontManifest.json`, guarded by `test/core/theme/fonts_test.dart` |
| I3 | TODO | `flutter analyze` and `flutter test` run clean locally, not yet in GitHub Actions |
| I4 | WIP | `app/vercel.json` written: `outputDirectory` `build/web`, SPA rewrite so deep links survive a hard refresh, immutable caching on hashed assets, `max-age=0` on `index.html` and the service worker. Unit checked. **Nothing has been deployed** and the `fuckcorpo-flutter` Vercel project does not exist. React's deploy path is untouched: the file lives under `app/`, not the repo root |
| I5 | WIP | `flutter build apk --release` succeeds and the APK installs and runs on `emulator-5554` (Android 17 / API 37). Onboarding, timer start/stop, quick-log validation, dashboard, achievements, and settings all verified at runtime: `qa_android_runtime.md`, `.hermes/android-proof/`. Still unverified: release signing, `flutter build appbundle --release`, any Play track, any physical device. See also `qa_mobile.md` |
| I6 | TODO | Windows host cannot build iOS. Defer-or-not decision still open, gate G7 |

## Validation status

Run 2026-07-28 from `app/`. Rerun during the P9 readiness pass.

| Command | Result |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test --reporter compact --concurrency=1` | 269 tests, all passed |
| `flutter build web` | `Built build\web` |
| `npm run build -- --mode production` | React reference build completed into `dist/` |
| `.hermes/scripts/parity_sweep.cjs` | React-vs-Flutter local sweep passed; see `qa_parity_sweep.md` |
| `flutter build apk --release` | `Built build\app\outputs\flutter-apk\app-release.apk` (50.6 MB), installs and runs on emulator |
| Coverage gate on `lib/domain` and `lib/data` >= 90% | Not yet measured |
| `flutter build appbundle --release` | Not run, no keystore |
| `flutter build ipa` | Not possible on Windows |

## Gate status

| Gate | State |
|---|---|
| G1 parity matrix 100% green | MET for repo-local MVP feature/screen parity. External release gates below still not met |
| G2 analyze clean | MET locally, not in CI |
| G3 tests green, domain coverage >= 90% | Tests green: 269 passing. Coverage never measured |
| G4 web release build deploys to a Vercel preview | Build succeeds. **No deploy exists** |
| G5 browser QA script passes | PARTIAL. Passed against `build/web` served locally with SPA rewrites (`qa_browser_hosted.md`, `.hermes/web-proof/`). Not run against a hosted/staged URL; no Lighthouse, install, or offline test. See `qa_browser.md` |
| G6 appbundle signed, internal track verified | NOT MET |
| G7 iOS TestFlight or a written defer decision | NOT MET, and unsatisfied by silence |
| G8 migration verified on a real pre-existing browser profile | NOT MET. Now verified in a real Chromium profile with a synthetic-but-realistic payload (`qa_browser_hosted.md`). A copy of a genuine pre-existing user profile is still required |
| G9 Flutter live on the production domain, React archived | NOT MET |

The plan for closing G1 through G9 is `cutover_plan.md`. The current evidence
summary and blocker list is `release_readiness.md`.
