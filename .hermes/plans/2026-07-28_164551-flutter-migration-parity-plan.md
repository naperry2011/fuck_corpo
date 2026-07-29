# FuckCorpo: React/Vite PWA to Flutter Migration Plan (Parity-Gated)

Date: 2026-07-28
Repo: `C:\Users\Ziggy\Dropbox\GitHub\fuck_corpo`
Branch at authoring: `zali-init` (commit `34e0f62`)
Status: PLANNING ONLY. No code is written by this document.

---

## 0. The one rule

**The React app is not deprecated until the Flutter app reaches 100% parity with what React ships today.**

Parity means: every screen, every visible number, every interaction, every persisted field, and every satirical string that exists in `src/` today exists in Flutter and behaves the same or better. Parity is measured against the *shipped React behavior*, not against `fuckcorpo-features.md`.

Nothing from the promised-feature backlog (leaderboards, accounts, shareable images, automatic tracking, streaks) enters the Flutter codebase before the parity gate closes. That backlog is Phase 8+ and is scoped separately in Section 10.

### Deprecation gate checklist (all must be true)

| # | Gate condition | Evidence required |
|---|---|---|
| G1 | Parity matrix (Section 4) is 100% green | Signed-off matrix, no "partial" rows |
| G2 | `flutter analyze` clean, zero warnings | CI log |
| G3 | `flutter test` green, coverage on domain layer >= 90% | CI log + coverage report |
| G4 | `flutter build web --release` succeeds and deploys to a Vercel preview | Preview URL |
| G5 | Side-by-side browser QA script passes (Section 8.4) | Signed QA sheet |
| G6 | `flutter build appbundle --release` succeeds; internal-track install verified | Play Console internal testing link |
| G7 | iOS: either TestFlight build verified on a Mac, or explicitly deferred with a written decision | Section 7.3 |
| G8 | localStorage-to-Flutter web migration verified on a real pre-existing browser profile | Recorded QA run |
| G9 | Flutter web is live on the production domain and the React deployment is archived, not deleted, for 30 days | Vercel project state |

Only after G1 through G9 does the React app get archived. Archive means: tag the last React commit `react-final`, move `src/`, `index.html`, `vite.config.js`, `package.json` into `legacy/react/`, and keep the Vercel deployment as a non-aliased project for 30 days.

---

## 1. What exists today (the migration surface)

Stack: React 19 + Vite 7 SPA, `react-router-dom` v7, `vite-plugin-pwa`, Chart.js via `react-chartjs-2`, `lucide-react`. No backend, no tests, no TypeScript. ~4,600 lines. All state client-side in `localStorage` key `fuckcorpo_data`.

### Screens (4 routes + 1 gate)

| Route | File | Purpose |
|---|---|---|
| gate | `src/pages/Landing.jsx` + `src/components/Application.jsx` | 5-step satirical job application onboarding; renders instead of the router when `state.onboarded === false` |
| `/` | `src/pages/Timer.jsx` | Live timer, quick log, today summary, recent breaks list |
| `/dashboard` | `src/pages/Dashboard.jsx` | Running totals, fun fact rotator, corporate memo, 3 charts, performance metrics, comparisons |
| `/achievements` | `src/pages/Achievements.jsx` | 11 badges, earnings statement, CEO comparison |
| `/settings` | `src/pages/Settings.jsx` | Salary, profile, theme, sound, export/import/clear, about, know-your-rights |

### Persistent state shape (`src/utils/storage.js`)

```
{
  salary:   { amount: 0, type: 'annual', currency: 'USD' },
  breaks:   [ { id, category, duration /* ms */, timestamp /* ISO */ } ],
  settings: { theme, currency, timezone, industry, state, soundEnabled },
  achievements: [ '<id>' ],
  onboarded: false
}
```

### Domain logic worth porting exactly

- `salaryToPerMinute` with constants 8h/day, 5d/week, 52w/year (124,800 work minutes/year).
- `calculateEarnings(durationMs, perMinuteRate)`.
- `formatCurrency`, `formatDuration` (HH:MM:SS or MM:SS).
- Date range selectors: today, week (Sunday start), month, year.
- `getComparisons` with 7 priced items.
- `getCorporateMemo`, `getRandomFact`, `getRandomMotivation` in `src/utils/funFacts.js`.
- 11 achievement definitions with predicate functions in `Achievements.jsx:11-23`.
- `CEO_RATE_PER_MINUTE = 83.33`.
- Ticker items: `$EARN`, `$TIME`, `$LIFE`, `$SESS`, `$RATE`.

### Known defects carried by React (do NOT replicate)

The audit (`docs/audit/findings.md`, `docs/audit/bugs.md`) lists 11 bugs. Migration policy per bug:

| Bug | React behavior | Flutter policy |
|---|---|---|
| BUG-001 PWA icons missing | Install prompt broken | **Fix during migration.** Flutter web needs real icons anyway. |
| BUG-002 currency ignored | Everything renders USD | **Fix.** Currency is a single formatter in the Flutter domain layer. Parity target is "intended behavior", noted as an intentional deviation. |
| BUG-003 light theme not restored | Reverts to dark on reload | **Fix.** ThemeMode is read from storage at app boot. |
| BUG-004 unvalidated import | Bad JSON bricks the app | **Fix.** Typed model with validated `fromJson` + rejection path. |
| BUG-005 category colors mismatch | 3 of 5 wedges gray | **Fix.** Single `BreakCategory` enum owns label, emoji, color. |
| BUG-006 dead reducer branches | RESET/IMPORT unreachable | **Fix.** Not ported at all; Flutter has explicit repository methods. |
| BUG-007 shallow settings merge | Defaults dropped | **Fix.** Typed model with per-field defaults. |
| BUG-008 running timer lost on reload | Silent data loss | **Fix.** Persist `{running, startedAt, category}`; rehydrate from wall clock. |
| BUG-009 JPY two decimals | Invalid formatting | **Fix.** `NumberFormat.simpleCurrency` derives decimals. |
| BUG-010 timezone dead field | Collected, unused | **Carry the field, keep it unused**, marked deprecated in the model. Removing it would break import of existing exports. |
| BUG-011 onboarding re-renders | Perf only | N/A in Flutter. |

**Deviation register.** Every "Fix" above is a deliberate divergence from shipped React behavior. Each one is recorded in `docs/migration/deviations.md` with a one-line justification so that parity sign-off is not blocked by "Flutter behaves differently here". Deviations that *improve* correctness pass the gate. Deviations that *change* satirical copy, layout, or numbers do not.

---

## 2. Migration strategy

Rewrite, not port. There is no shared runtime between React and Flutter, no incremental strangler pattern available, and the app is small enough (4,600 lines, no backend) that a clean rewrite behind a parity gate is lower risk than a hybrid.

The two apps live side by side in one repo until the gate closes:

```
fuck_corpo/
  src/                 <- React, untouched during migration
  app/                 <- new Flutter app
  docs/migration/      <- parity matrix, QA sheets, deviations
```

React stays deployable and on the production domain the entire time. Flutter web deploys to a separate Vercel project (`fuckcorpo-flutter`) with its own preview domain until G9.

### Phase order

| Phase | Scope | Exit criteria |
|---|---|---|
| P0 | Scaffold, tooling, CI, design tokens | `flutter analyze` + `flutter test` green on an empty app; theme demo screen renders all tokens |
| P1 | Domain + data layer (models, calculations, repository, storage) | Unit tests green, >= 90% coverage on `lib/domain/` |
| P2 | Design system widgets (Button, Card, Toast, PageTransition, AnimatedCurrency, Ticker, Navbar/Shell) | Widget tests + a widget gallery screen |
| P3 | Timer screen | Parity matrix rows T1-T5 green |
| P4 | Dashboard screen (charts) | Rows D1-D9 green |
| P5 | Achievements screen | Rows A1-A4 green |
| P6 | Settings screen + data portability | Rows S1-S8 green |
| P7 | Onboarding (Landing + 5-step Application) | Rows O1-O7 green |
| P8 | Web migration bridge, PWA config, platform QA, release readiness | G2-G9 |
| P9 | Cutover and React archive | G9 |
| P10+ | Promised-feature expansion (Section 10) | Out of parity scope |

Domain and data before UI is deliberate. Every screen depends on the same calculation layer, and that layer is the only part of the React app with real logic worth encoding as tests.

---

## 3. Target repo and app structure

```
fuck_corpo/
├─ app/                                   # Flutter app root (pubspec.yaml here)
│  ├─ lib/
│  │  ├─ main.dart                        # bootstrap: storage init, migration, runApp
│  │  ├─ app.dart                         # MaterialApp.router, ThemeData wiring
│  │  ├─ router.dart                      # go_router config + onboarding redirect
│  │  │
│  │  ├─ core/
│  │  │  ├─ theme/
│  │  │  │  ├─ colors.dart                # FcColors: navy, slate, green, red, gold, gray, mutedGold
│  │  │  │  ├─ typography.dart            # Playfair Display / Work Sans / Roboto Mono TextTheme
│  │  │  │  ├─ spacing.dart               # FcSpacing 8pt scale
│  │  │  │  ├─ radii.dart, shadows.dart
│  │  │  │  ├─ fc_theme.dart              # buildDarkTheme() / buildLightTheme()
│  │  │  │  └─ breakpoints.dart           # 320 / 768 / 1024 / 1440
│  │  │  ├─ format/
│  │  │  │  ├─ currency_formatter.dart    # the single currency seam (fixes BUG-002/009)
│  │  │  │  └─ duration_formatter.dart
│  │  │  └─ audio/
│  │  │     └─ sound_service.dart         # chaChing / achievementSound
│  │  │
│  │  ├─ domain/
│  │  │  ├─ models/
│  │  │  │  ├─ break_record.dart          # id, category, duration, timestamp
│  │  │  │  ├─ break_category.dart        # enum: value,label,emoji,color (fixes BUG-005)
│  │  │  │  ├─ salary.dart                # amount, SalaryType, currency
│  │  │  │  ├─ app_settings.dart          # theme, currency, timezone, industry, region, soundEnabled
│  │  │  │  ├─ achievement.dart           # id, name, desc, icon, predicate
│  │  │  │  ├─ running_timer.dart         # running, startedAt, category (fixes BUG-008)
│  │  │  │  └─ app_state.dart             # aggregate root + toJson/fromJson + schemaVersion
│  │  │  ├─ calculations.dart             # port of src/utils/calculations.js
│  │  │  ├─ comparisons.dart              # 7 priced items + emoji, single owner
│  │  │  ├─ achievements_catalog.dart     # the 11 badges
│  │  │  └─ copy/
│  │  │     ├─ fun_facts.dart             # FUN_FACTS, TIMER_MOTIVATIONS
│  │  │     └─ corporate_memo.dart        # getCorporateMemo port
│  │  │
│  │  ├─ data/
│  │  │  ├─ storage/
│  │  │  │  ├─ key_value_store.dart       # abstract interface
│  │  │  │  ├─ shared_prefs_store.dart    # default impl (all platforms)
│  │  │  │  └─ legacy_web_store.dart      # reads raw localStorage 'fuckcorpo_data' (web only)
│  │  │  ├─ app_repository.dart           # load/save/export/import/clear + validation
│  │  │  └─ migrations/
│  │  │     ├─ migrator.dart              # schemaVersion dispatch
│  │  │     └─ v0_localstorage_to_v1.dart # the React->Flutter bridge
│  │  │
│  │  ├─ state/
│  │  │  ├─ app_controller.dart           # single source of truth (Riverpod Notifier)
│  │  │  ├─ providers.dart                # perMinuteRate, currency, derived selectors
│  │  │  ├─ timer_controller.dart         # live timer, wall-clock based
│  │  │  └─ toast_controller.dart
│  │  │
│  │  ├─ features/
│  │  │  ├─ onboarding/
│  │  │  │  ├─ landing_screen.dart
│  │  │  │  └─ application_wizard.dart    # + step widgets in steps/
│  │  │  ├─ timer/timer_screen.dart       # + widgets/
│  │  │  ├─ dashboard/dashboard_screen.dart
│  │  │  ├─ achievements/achievements_screen.dart
│  │  │  └─ settings/settings_screen.dart
│  │  │
│  │  └─ widgets/                          # the shared UI kit
│  │     ├─ fc_button.dart                # primary/secondary/danger/ghost x sm/md/lg
│  │     ├─ fc_card.dart                  # + elevated variant
│  │     ├─ fc_toast.dart, fc_toast_host.dart
│  │     ├─ fc_page_transition.dart
│  │     ├─ animated_currency.dart        # count-up
│  │     ├─ fc_ticker.dart                # infinite marquee
│  │     ├─ fc_navbar.dart                # desktop rail + mobile bottom bar
│  │     ├─ fc_app_shell.dart             # Navbar + Ticker + outlet
│  │     └─ fc_text_field.dart, fc_dropdown.dart, fc_switch.dart
│  │
│  ├─ assets/
│  │  ├─ fonts/                            # SELF-HOSTED Playfair, Work Sans, Roboto Mono
│  │  └─ icons/
│  ├─ test/                                # unit + widget tests mirroring lib/
│  ├─ integration_test/                    # end-to-end flows
│  ├─ web/                                 # index.html, manifest.json, icons
│  ├─ android/  ios/
│  └─ pubspec.yaml
├─ docs/migration/
│  ├─ parity_matrix.md
│  ├─ deviations.md
│  ├─ qa_browser.md  qa_mobile.md
│  └─ storage_schema_v1.md
├─ src/  index.html  vite.config.js  package.json   # React, frozen
└─ vercel.json
```

### Dependency choices

| Need | Package | Why |
|---|---|---|
| State | `flutter_riverpod` | Closest analogue to the single-reducer context store; testable without widgets |
| Routing | `go_router` | Declarative routes + a `redirect` that maps exactly to the `onboarded` gate |
| Storage | `shared_preferences` | Works on web (localStorage-backed), Android, iOS with one API |
| Raw web storage | `web` package (`package:web`) | Needed only to read the legacy `fuckcorpo_data` key on web |
| Charts | `fl_chart` | Line, bar (horizontal), pie/doughnut all supported; matches the three Chart.js charts |
| Formatting | `intl` | `NumberFormat.simpleCurrency` and `DateFormat` replace `Intl.NumberFormat` |
| IDs | `uuid` | Replaces `crypto.randomUUID()` |
| Sound | `just_audio` OR generated WAV bytes | React synthesizes tones with WebAudio; see Section 6.6 |
| File IO | `file_picker` + `file_saver` | Export/import JSON on web, Android, iOS |
| Clipboard | `flutter/services` `Clipboard` | Earnings statement copy |
| Icons | `lucide_icons` (or hand-picked `Icons.*`) | Navbar parity with lucide-react |

Self-hosting the fonts is required, not optional: it fixes F-013 (the "no tracking" credibility gap) and is the normal Flutter pattern anyway.

---

## 4. Parity matrix

Legend for the Status column when this document is used as a live tracker: `TODO` / `WIP` / `DONE`. All rows must be `DONE` for G1.

### 4.1 App shell, routing, global state

| ID | React source | Behavior to preserve | Flutter target | Tests | Status |
|---|---|---|---|---|---|
| X1 | `src/main.jsx` | Provider nesting, browser router | `lib/main.dart`, `lib/app.dart` | smoke widget test | TODO |
| X2 | `src/App.jsx` | 4 routes + onboarding gate on `state.onboarded` | `lib/router.dart` with `redirect` | router unit test: not-onboarded -> Landing; onboarded -> Timer | TODO |
| X3 | `components/layout/Layout.jsx` | Navbar + Ticker + content, 1200px max width | `widgets/fc_app_shell.dart` | golden at 320/768/1024/1440 | TODO |
| X4 | `components/layout/Navbar.jsx` | Brand `$ FUCKCORPO`, 4 links w/ icons, active state | `widgets/fc_navbar.dart` | widget test: active highlight per route | TODO |
| X5 | `components/layout/Ticker.jsx` | 5 items ($EARN/$TIME/$LIFE/$SESS/$RATE), duplicated for seamless scroll, green/red | `widgets/fc_ticker.dart` | widget test: 5 labels, values from state | TODO |
| X6 | `context/AppContext.jsx` | 8 actions, persist on every change, derived `perMinuteRate` | `state/app_controller.dart` + `providers.dart` | unit tests per action; persist-on-change test | TODO |
| X7 | `context/ToastContext.jsx` | `addToast(msg, type)`, types success/info/achievement | `state/toast_controller.dart` + `fc_toast_host.dart` | widget test per type | TODO |

### 4.2 Domain / utils

| ID | React source | Behavior | Flutter target | Tests | Status |
|---|---|---|---|---|---|
| C1 | `calculations.js:9-26` | `salaryToPerMinute` for annual/hourly/monthly/weekly | `domain/calculations.dart` | 4 salary types + zero + negative | TODO |
| C2 | `calculations.js:28-31` | `calculateEarnings` | same | ms->minutes precision test | TODO |
| C3 | `calculations.js:33-40` | `formatCurrency` | `core/format/currency_formatter.dart` | USD, EUR, GBP, CAD, AUD, **JPY zero-decimal** | TODO |
| C4 | `calculations.js:42-50` | `formatDuration` HH:MM:SS / MM:SS | `core/format/duration_formatter.dart` | <1h, >=1h, 0, >24h | TODO |
| C5 | `calculations.js:52-92` | today / week (Sun start) / month / year selectors | `domain/calculations.dart` | boundary tests: midnight, Sat->Sun, month end, Dec 31 | TODO |
| C6 | `calculations.js:94-100` | `totalEarnings`, `totalDuration` | same | empty list, single, many | TODO |
| C7 | `calculations.js:103-122` | 7 comparison items + `getComparisons` filter count>0 | `domain/comparisons.dart` (emoji lives here too) | price boundaries, singular/plural label | TODO |
| C8 | `funFacts.js` | FUN_FACTS, TIMER_MOTIVATIONS, `getCorporateMemo`, random getters | `domain/copy/*` | memo branch coverage; string-for-string equality with a fixtures file | TODO |
| C9 | `Timer.jsx:20-26` + `Dashboard.jsx:59-65` | 5 categories | `domain/models/break_category.dart` (single owner) | every category has label+emoji+color | TODO |
| C10 | `Achievements.jsx:11-23` | 11 badges + predicates | `domain/achievements_catalog.dart` | one test per badge predicate at the boundary | TODO |
| C11 | `Timer.jsx:32-41` | `timeAgo` | `domain/calculations.dart` | just now / m / h / d | TODO |

### 4.3 Data / storage

| ID | React source | Behavior | Flutter target | Tests | Status |
|---|---|---|---|---|---|
| P1 | `storage.js:18-26` | `loadData` w/ defaults | `data/app_repository.dart#load` | missing key, corrupt JSON, partial payload | TODO |
| P2 | `storage.js:28-34` | `saveData` | `#save` | round trip | TODO |
| P3 | `storage.js:36-45` | export to `fuckcorpo-export-YYYY-MM-DD.json` | `#export` + `file_saver` | filename format, payload shape | TODO |
| P4 | `storage.js:47-55` | import JSON | `#import` **with validation** | valid, malformed, `{"breaks":"x"}` rejected | TODO |
| P5 | `storage.js:57-59` | clear | `#clear` | state returns to defaults without reload | TODO |
| P6 | (new) | legacy localStorage read on web | `data/migrations/v0_localstorage_to_v1.dart` | v0 payload -> v1 model, idempotent | TODO |

### 4.4 Timer screen

| ID | React source | Behavior | Flutter target | Tests | Status |
|---|---|---|---|---|---|
| T1 | `Timer.jsx:131-171` | Category chip row (disabled while running), live clock, live earnings, START/STOP button, status + motivation text while running | `features/timer/timer_screen.dart` + `widgets/` | widget: chips disabled while running; earnings tick | TODO |
| T2 | `Timer.jsx:63-93` | 100ms tick, discard <1000ms, `ADD_BREAK`, toast with earnings, cha-ching | `state/timer_controller.dart` | fake-clock test; sub-second discard **now shows a toast** (deviation) | TODO |
| T3 | `Timer.jsx:174-224` | Quick log: minutes 1-480, category, date, submits at 12:00 local | timer_screen quick log card | invalid input rejected; timestamp is noon local | TODO |
| T4 | `Timer.jsx:226-243` | Today summary: 3 cards (count, duration, earnings) | same | matches selector output | TODO |
| T5 | `Timer.jsx:245-274` | Recent breaks: newest 10, emoji, category, timeAgo, duration, earnings, delete | same | 11 breaks -> 10 shown, newest first; delete dispatch | TODO |
| T6 | (fix BUG-008) | timer survives navigation and reload | `running_timer.dart` persisted | reload while running -> elapsed correct | TODO |

### 4.5 Dashboard screen

| ID | React source | Behavior | Flutter target | Tests | Status |
|---|---|---|---|---|---|
| D1 | `Dashboard.jsx:173-187` | Empty state: CONFIDENTIAL + title + "No data yet" card | `dashboard_screen.dart` | empty state golden | TODO |
| D2 | `:311-317` | Header: CONFIDENTIAL, "YOUR QUARTERLY EARNINGS REPORT", subtitle | same | text present | TODO |
| D3 | `:319-333` | 5 totals: today/week/month/year + featured lifetime, animated count-up | `animated_currency.dart` | animation completes to exact value | TODO |
| D4 | `:335-343` | MARKET ANALYSIS rotating fun fact, 10s, fade 400ms | same | timer-driven rotation test | TODO |
| D5 | `:345-357` | INTERNAL CORRESPONDENCE memo: To Employee #`(n+1000)` padded 5, From, Subject, body | same | employee number formatting | TODO |
| D6 | `:359-367` | EARNINGS OVER TIME: 7-day line, green fill, tension 0.3, currency ticks | `fl_chart` LineChart | data-shape unit test on the 7-day builder | TODO |
| D7 | `:369-389` | BREAK PATTERNS: horizontal bar, 24 hour buckets, 12h AM/PM labels | `fl_chart` BarChart w/ horizontal | 24 buckets, label format | TODO |
| D8 | `:369-389` | CATEGORY BREAKDOWN doughnut, per-category brand colors, navy border, bottom legend | `fl_chart` PieChart w/ centerSpaceRadius | **all 5 categories distinct** (fixes BUG-005) | TODO |
| D9 | `:391-434` | PERFORMANCE METRICS (4 cards) + YOUR EARNINGS CAN BUY (comparison cards w/ emoji) | same | derived values match selectors | TODO |

### 4.6 Achievements screen

| ID | React source | Behavior | Flutter target | Tests | Status |
|---|---|---|---|---|---|
| A1 | `Achievements.jsx:99-128` | Header w/ `n / 11 unlocked`, badge grid, locked shows lock icon | `achievements_screen.dart` | unlocked count, locked rendering | TODO |
| A2 | `:39-50` | Unlock evaluation on state change, dispatch once, toast + sound once per session | `state/app_controller.dart` (moved out of the screen) | no duplicate toast on rebuild | TODO |
| A3 | `:130-174` + `:68-94` | Earnings statement card + exact ASCII clipboard payload | same | **string-for-string** ASCII fixture test | TODO |
| A4 | `:176-209` | CEO comparison at 83.33/min, multiplier, footnote | same | multiplier math, zero-earnings branch | TODO |

### 4.7 Settings screen

| ID | React source | Behavior | Flutter target | Tests | Status |
|---|---|---|---|---|---|
| S1 | `Settings.jsx:132-177` | Compensation: amount + 4 salary types, live per-minute preview | `settings_screen.dart` | preview updates on type change | TODO |
| S2 | `:179-234` | Profile: 6 currencies, 9 industries, free-text region | same | save dispatch payload | TODO |
| S3 | `:236-275` | Theme toggle + Sound toggle | same | theme applies **and persists** (fixes BUG-003) | TODO |
| S4 | `:277-317` | Export / Import with success and error states | `app_repository` + `file_picker`/`file_saver` | import success + invalid file surfaces error | TODO |
| S5 | `:319-345` | Clear All Data with two-step confirm | same | confirm required; **no page reload** (fixes BUG-006) | TODO |
| S6 | `:350-369` | About card: v1.0.0, board of directors, shareholder value | same | text present | TODO |
| S7 | `:371-386` | Know Your Rights OSHA paragraph + disclaimer | same | text present | TODO |
| S8 | (fix BUG-002) | currency applies app-wide | `currency_formatter` bound to settings | EUR selected -> ticker/timer/dashboard all EUR | TODO |

### 4.8 Onboarding

| ID | React source | Behavior | Flutter target | Tests | Status |
|---|---|---|---|---|---|
| O1 | `Landing.jsx` hero | `$POOP +420.69%`, QUARTERLY EARNINGS REPORT, tagline, subtitle | `landing_screen.dart` | text present | TODO |
| O2 | `Landing.jsx` features | 3 feature cards w/ tickers `$FLUSH`, `$STATS`, `$BADGE` | same | 3 cards | TODO |
| O3 | `Application.jsx:132-137` | STEP n OF 5 + progress bar width `n/5` | `application_wizard.dart` | progress per step | TODO |
| O4 | `:139-174` | Step 1 cover | `steps/step1_cover.dart` | renders, advances | TODO |
| O5 | `:175-331` | Step 2 applicant info, Step 3 skills assessment | `steps/step2_*`, `steps/step3_*` | validation, back/next | TODO |
| O6 | `:332-359` | Step 4 background check animation (timed) | `steps/step4_background_check.dart` | completes and auto-advances | TODO |
| O7 | `:360-...` | Step 5 offer letter: salary entry, then SET_SALARY + UPDATE_SETTINGS + SET_ONBOARDED | `steps/step5_offer.dart` | after submit, router redirects to Timer and state persists | TODO |

### 4.9 Platform / infra

| ID | React source | Behavior | Flutter target | Validation | Status |
|---|---|---|---|---|---|
| I1 | `vite.config.js` VitePWA | installable PWA, offline precache | `web/manifest.json` + Flutter service worker | Lighthouse installable = pass (fixes BUG-001) | TODO |
| I2 | `index.css:2` Google Fonts | 3 font families | `assets/fonts/` self-hosted | no third-party request in the network tab | TODO |
| I3 | (none) | no tests / no CI | `flutter analyze` + `flutter test` in GitHub Actions | CI green on PR | TODO |
| I4 | Vercel static SPA | production hosting | Vercel via `flutter build web` | Section 5 | TODO |
| I5 | (none) | Android app | `flutter build appbundle` | Section 7.1 | TODO |
| I6 | (none) | iOS app | `flutter build ipa` | Section 7.3 (Windows caveat) | TODO |

---

## 5. Web deployment to Vercel from Flutter web

Vercel has no native Flutter runtime. Two viable approaches; recommendation is **A**.

### Option A (recommended): build in CI, deploy prebuilt output

GitHub Actions installs the Flutter SDK, runs `flutter build web --release`, and deploys `app/build/web` to Vercel with the Vercel CLI (`vercel deploy --prebuilt` or `--prod` against a static output dir). Vercel's build step does nothing. Fast, cache-friendly, no SDK download inside Vercel's build container, and the same artifact that CI tested is the artifact that ships.

### Option B: install Flutter inside the Vercel build

`vercel.json` build command clones the Flutter SDK, runs the build, and points `outputDirectory` at `build/web`. Simpler to set up, but every deploy pays a multi-minute SDK download and it is fragile against Vercel image changes. Use only as a fallback.

### Configuration checklist

1. Create a **second Vercel project** `fuckcorpo-flutter` pointed at the same repo. The existing React project keeps the production domain until G9.
2. Root `vercel.json`:
   - `outputDirectory` for the Flutter project points at the built web output.
   - SPA rewrite: all paths to `/index.html` so deep links (`/dashboard`, `/settings`) work on refresh. This is mandatory; Flutter web with path URL strategy 404s without it.
   - Headers: long `Cache-Control: immutable` on hashed assets, `no-cache` on `index.html` and `flutter_service_worker.js` so updates are picked up.
3. Renderer: build with the default (CanvasKit for desktop, HTML/skwasm strategy per Flutter version). Evaluate `--wasm` only after parity; it changes browser support and bundle size.
4. URL strategy: use path URLs (no `#`) to match React's current URLs exactly. Verify `/dashboard` loads on hard refresh.
5. Base href stays `/`, matching the current PWA `scope` and `start_url`.
6. Preview deploys on every PR. Parity QA (Section 8.4) runs against a preview URL, never localhost only.
7. Cutover (G9): move the production domain alias from the React project to the Flutter project. Keep the React project deployed and reachable at its `.vercel.app` URL for 30 days.
8. Rollback: re-point the domain alias back to the React project. One command, no rebuild.

### PWA / installability

- `web/manifest.json` must carry name `FuckCorpo`, `theme_color` and `background_color` `#0a1128`, `display: standalone`, `orientation: portrait`, `scope: /`, `start_url: /`.
- Generate and commit **real** icons: 192, 512, 512-maskable, plus `apple-touch-icon`. This is the single fix for BUG-001 and it must not regress in Flutter.
- Flutter's generated service worker handles precache. Verify offline load after first visit.
- Validation: Chrome DevTools > Application > Manifest shows no icon errors, and the install prompt appears. Lighthouse PWA category has no installability failure.

---

## 6. Design system translation

Source of truth: `fuckcorpo-design-system.md` plus the actual `:root` block in `src/index.css`.

### 6.1 Color tokens

| CSS var | Value | Flutter |
|---|---|---|
| `--color-navy` | `#0a1128` | `FcColors.navy` -> `scaffoldBackgroundColor`, `ColorScheme.surface` |
| `--color-slate` | `#1e2749` | `FcColors.slate` -> card / elevated surface |
| `--color-white` | `#ffffff` | `FcColors.ink` -> `onSurface` |
| `--color-green` | `#00b559` | `FcColors.green` -> `primary`, all positive money |
| `--color-green-dark` | `#008f47` | `FcColors.greenDark` -> pressed state |
| `--color-red` | `#e63946` | `FcColors.red` -> `error`, danger button |
| `--color-gold` | `#ffd60a` | `FcColors.gold` -> achievements, highlights |
| `--color-gray` | `#778da9` | `FcColors.gray` -> secondary text, chart axes |
| `--color-muted-gold` | `#c9a648` | `FcColors.mutedGold` |

Light theme overrides (`[data-theme="light"]`): navy -> `#ffffff`, slate -> `#f8f9fa`, white -> `#0a1128`, gray -> `rgba(30,39,73,0.5)`. Implement as a second `ThemeData` from the same builder taking a token set, not as scattered `Theme.of(context).brightness` checks.

`--glow-green: 0 0 20px rgba(0,181,89,0.4)` becomes a reusable `BoxShadow` const, used on the live-timer earnings and primary buttons.

### 6.2 Typography

| Family | Role | Flutter |
|---|---|---|
| Playfair Display 700/900 | display headings (h1, h2, page titles) | `displayLarge`, `displayMedium`, `headlineLarge` |
| Work Sans 400/500/600 | body, labels, buttons | `bodyLarge/Medium/Small`, `labelLarge` |
| Roboto Mono 400/700 | every number, ticker, timer clock, chart ticks | `FcText.mono` extension + `TextTheme` monospace slots |

Declare all three under `pubspec.yaml` `fonts:` with the weights actually used. Do not use `google_fonts` with runtime fetching; that reintroduces the third-party request the audit flagged.

The `.mono` CSS utility class maps to a `TextStyle` getter, not to ad-hoc `fontFamily:` strings at call sites.

### 6.3 Spacing, radii, shadows, layout

- Spacing scale `0.25 / 0.5 / 1 / 1.5 / 2 / 3 / 4 / 6 rem` becomes `FcSpacing.xxs=4, xs=8, s=16, m=24, l=32, xl=48, xxl=64, xxxl=96` in logical pixels (16px root). 8pt grid preserved.
- Radii `4 / 8 / 12` -> `FcRadii.sm/md/lg` as `BorderRadius` consts.
- Shadows sm/md/lg -> `FcShadows` `List<BoxShadow>` consts.
- Widths: `--max-width: 1400`, `--content-width: 1200`, `--narrow-width: 800`, `--card-max-width: 600` -> `FcLayout` consts, applied with `ConstrainedBox` inside a `Center` in `fc_app_shell.dart`. This replaces the `.container` CSS class.
- Breakpoints 320 / 768 / 1024 / 1440 -> `FcBreakpoints` + a `LayoutBuilder`-based responsive helper. Navbar switches from a horizontal top bar (>=768) to a bottom navigation bar (<768).
- The fixed `body::before` texture overlay becomes a `Stack` layer in `fc_app_shell.dart` with `IgnorePointer`.

### 6.4 Component translation

| React component | CSS | Flutter widget | Notes |
|---|---|---|---|
| `Button.jsx` | `Button.css` | `FcButton` | Variants primary/secondary/danger/ghost x sizes sm/md/lg. Build on `ButtonStyle` in `ThemeData`, expose a thin enum-driven wrapper. Uppercase + letter-spacing preserved. |
| `Card.jsx` | `Card.css` | `FcCard` | `elevated` bool -> slate surface + `FcShadows.lg`. Border 1px `rgba(gray)`. |
| `Toast.jsx` + `ToastContext` | `Toast.css` | `FcToastHost` overlay + `toastController` | 3 types: success (green), info (gray), achievement (gold). Do NOT use `SnackBar`; the styling is bespoke. |
| `PageTransition.jsx` | `PageTransition.css` | `FcPageTransition` | Fade + slide-up on route enter; wire into `go_router` `pageBuilder` with `CustomTransitionPage`. |
| `AnimatedCurrency.jsx` + `useCountUp.js` | - | `AnimatedCurrency` | `TweenAnimationBuilder<double>` + currency formatter. Must respect `MediaQuery.disableAnimations`. |
| `Ticker.jsx` | `Ticker.css` marquee | `FcTicker` | CSS infinite scroll -> `AnimationController` driving a repeating `Transform.translate` over a duplicated item row. |
| `Navbar.jsx` | `Navbar.css` | `FcNavbar` | lucide `Timer/BarChart3/Trophy/Settings` -> `lucide_icons` equivalents. Active state = green text + underline. |
| `.form-input`, `select` | `index.css` | `FcTextField`, `FcDropdown` | Mono font on numeric inputs. Slate fill, gray border, green focus ring. |
| theme toggle | `Settings.css` | `FcSwitch` | Custom track/thumb to match, not stock `Switch`. |

### 6.5 Charts

Chart.js configs in `Dashboard.jsx:208-300` translate to `fl_chart`:

- Line: `borderColor #00b559`, fill `rgba(0,181,89,0.1)`, `tension 0.3`, point radius 4 -> `LineChartBarData(isCurved: true, curveSmoothness: 0.3, belowBarData: BarAreaData(...))`.
- Bar with `indexAxis: 'y'` -> `BarChart` with rotated layout; 24 buckets, `borderRadius 4`, fill `rgba(0,181,89,0.6)`.
- Doughnut -> `PieChart(centerSpaceRadius: ...)`, `sectionsSpace` for the 2px navy border, legend rendered as a separate `Wrap` below.
- Axis ticks: gray `#778da9`, Roboto Mono 10-11px, grid `rgba(119,141,169,0.2)`.
- Currency tick callbacks route through `currency_formatter`, so charts honour the currency setting too.

### 6.6 Sound

`useSound.js` synthesizes tones with the WebAudio API: cha-ching = 800Hz then 1200Hz; achievement = 523/659/784Hz arpeggio. Flutter has no cross-platform oscillator. Two options:

- **Recommended:** pre-render the two cues as short WAV/MP3 assets generated from the same frequencies and envelopes, ship them in `assets/`, play via `just_audio`. Deterministic and identical across platforms.
- Alternative: generate PCM bytes at runtime and feed a buffer source. More code, no benefit.

Both gate on `settings.soundEnabled`, matching the React `!== false` semantics (absent means enabled).

### 6.7 Accessibility

The design system targets WCAG AAA. Carry forward: semantic labels on every icon-only button (React uses `aria-label` on category chips, delete, theme toggle), `role="switch"` toggles -> `Semantics(toggled:)`, focus order, and 44x44 minimum tap targets. Add a widget-test lint pass using `meetsGuideline(textContrastGuideline)` and `androidTapTargetGuideline`.

---

## 7. Mobile release readiness

### 7.1 Android

1. `applicationId`: `com.fuckcorpo.app` (decide final; it is immutable after first Play upload).
2. `minSdkVersion` 23+, target the current Play requirement at release time.
3. App name, adaptive launcher icon (navy background + `$` mark), splash via `flutter_native_splash` with `#0a1128`.
4. Signing: generate an upload keystore, store it outside the repo, put the password in CI secrets. `key.properties` is gitignored.
5. `flutter build appbundle --release`, verify size and that R8/shrinking does not break `fl_chart` or reflection-free code.
6. Play Console: create the app, complete Data Safety (declare: no data collected, no data shared, data stored on device only), Content Rating questionnaire, Privacy Policy URL, target audience.
7. **Store listing risk:** the app name contains profanity. Plan a store-safe display name (for example "FC: Break Earnings Tracker" or "FuckCorpo") and set the content rating honestly. Have a fallback name ready before submission rather than after rejection.
8. Internal testing track first; verify install and a full parity QA pass on a real device plus one emulator.
9. Closed testing before production.

### 7.2 iOS

1. Bundle identifier `com.fuckcorpo.app`, Apple Developer Program membership required (annual fee).
2. App icons for all required sizes, launch screen with navy background.
3. `Info.plist`: no camera/location/mic permissions are needed. Do not add any.
4. `flutter build ipa --release`, upload via Transporter or Xcode.
5. App Store Connect: privacy nutrition label (no data collected), age rating, screenshots for every required device size.
6. **Review risk is higher than Android:** the name and premise invite a 4.3 (spam) or objectionable-content rejection. Prepare a sanitized display name, a clear "satire / humor" positioning in review notes, and remove any copy that could read as encouraging time theft in the store listing itself (the in-app copy can stay).

### 7.3 iOS build caveat on Windows (explicit)

**iOS builds cannot be produced on this Windows machine.** `flutter build ipa`, code signing, and simulator testing all require macOS with Xcode. There is no workaround on Windows.

Options, in order of preference:

- **A. macOS CI runner.** GitHub Actions `macos-latest` runs `flutter build ipa` with signing certs from secrets and uploads to TestFlight. No local Mac needed. Recommended.
- **B. Borrowed or rented Mac / Mac mini** for the first release, then move to A.
- **C. Defer iOS entirely.** Ship web + Android at parity, treat iOS as a separate later milestone. Given App Store overhead and the review risk in 7.2, this is a legitimate choice.

Gate G7 is satisfied by either a verified TestFlight build (A or B) or a written, dated decision to defer (C). It is not satisfied by silence.

The iOS project directory (`app/ios/`) should still be scaffolded, committed, and kept compiling in CI-lint terms even if C is chosen, so option A can be enabled later without rework.

---

## 8. Local data migration

### 8.1 Current schema (v0, implicit)

localStorage key `fuckcorpo_data`, a single JSON object with `salary`, `breaks[]`, `settings`, `achievements[]`, `onboarded`. No version field.

### 8.2 Target schema (v1)

Same field names and semantics, plus:

- `schemaVersion: 1` at the root.
- Typed, validated parsing. Unknown fields preserved where safe; invalid ones rejected with a surfaced error instead of a silent brick.
- `settings` deep-merged against defaults per field (fixes BUG-007).
- `runningTimer: { startedAt, category } | null` added (fixes BUG-008).
- `settings.timezone` retained but marked deprecated so old exports still import cleanly.

Document this in `docs/migration/storage_schema_v1.md`.

### 8.3 Web migration path (automatic, silent)

Flutter web `shared_preferences` writes to localStorage under prefixed keys (`flutter.*`), so it will **not** see `fuckcorpo_data` on its own. Bridge required:

At app boot, in `main.dart`, before `runApp`:

1. If a v1 Flutter payload already exists, load it and stop.
2. Else, on web only, read the raw `fuckcorpo_data` key via `package:web` localStorage.
3. If present, parse as v0, run `v0_localstorage_to_v1`, write the v1 payload, and **leave the original `fuckcorpo_data` key untouched** so React remains usable during the parallel period and rollback is lossless.
4. If absent, start from defaults.
5. Migration is idempotent and guarded by a `migratedFromV0: true` marker so a user who then adds more data in React does not get silently overwritten. Note this consequence explicitly: after first Flutter load, React and Flutter diverge. During the parallel window, the two apps are not synchronized. Communicate this in the release note.

If the v0 payload fails validation, do not brick: fall back to defaults, keep the raw payload in a `fuckcorpo_data_backup` key, and show a one-time in-app notice offering export of the raw JSON.

### 8.4 Mobile boundary (explicit)

**Android and iOS cannot read browser localStorage. There is no automatic migration path from the web app to the mobile apps.** The browser's storage is sandboxed to the browser origin and is not reachable from a native process. This is a hard platform boundary, not an implementation gap.

The only supported path is user-driven:

1. In the React (or Flutter web) app, Settings > Export Data, producing `fuckcorpo-export-YYYY-MM-DD.json`.
2. Move the file to the phone (email, cloud drive, AirDrop, USB).
3. In the mobile app, Settings > Import Data, pick the file.

Requirements this places on the plan:
- Import must accept a v0 export (no `schemaVersion`) and migrate it, not just v1.
- `file_picker` must be wired on Android and iOS with the correct JSON MIME/UTI handling.
- Export on mobile uses the share sheet, not a download.
- The Settings screen must carry a short line of copy explaining that mobile and web do not sync and that export/import is the transfer mechanism. Silence here produces support questions and perceived data loss.

### 8.5 Test cases

| Case | Expected |
|---|---|
| Fresh install, no prior data | defaults, onboarding shown |
| Web, existing v0 payload with 50 breaks | all 50 present, totals identical to React side by side |
| Web, existing v0 payload with partial `settings` | missing settings fall back to defaults, not `undefined` |
| Web, corrupt `fuckcorpo_data` | app boots to defaults, backup key written, notice shown |
| Web, migration run twice | idempotent, no duplication |
| Mobile, import v0 export file | full state restored |
| Mobile, import v1 export file | full state restored |
| Mobile, import `{"breaks":"x"}` | rejected with an error message, existing state untouched |

---

## 9. Validation gates

Every gate below runs in CI on every PR into the Flutter branch, plus manually before cutover.

### 9.1 Static analysis
```
cd app && flutter analyze
```
Zero errors, zero warnings. `analysis_options.yaml` includes `flutter_lints` plus `prefer_const_constructors`, `avoid_print`, `require_trailing_commas`. Treat warnings as errors in CI.

### 9.2 Tests
```
cd app && flutter test --coverage
```
- Unit: every row in matrix 4.2 and 4.3.
- Widget: every row in 4.1, plus one per screen for empty state and populated state.
- Golden: `fc_button`, `fc_card`, `fc_ticker`, and one full-screen golden per screen at 375x812 and 1280x800, in both dark and light.
- Integration (`integration_test/`): onboarding to first logged break; start timer, navigate away, return, stop, verify persistence; export then clear then import round trip.
- Coverage gate: `lib/domain/` and `lib/data/` >= 90%. UI coverage not gated.

### 9.3 Web build
```
cd app && flutter build web --release
```
- Build succeeds with no warnings.
- Record the total transferred size of a cold load and compare against React's ~165 kB gzipped. Expect Flutter web to be materially larger; see Section 11.
- Deploy to a Vercel preview and verify the preview URL, not just localhost.

### 9.4 Browser QA (manual, scripted in `docs/migration/qa_browser.md`)

Run against a Vercel preview, side by side with the React production app in a second window, using the same seeded data.

Browsers: Chrome desktop, Safari desktop (or iOS Safari), Firefox desktop, Chrome Android.

Script (abbreviated; the full sheet enumerates all matrix rows):
1. Fresh profile: onboarding all 5 steps completes and lands on Timer.
2. Existing profile with v0 data: migration runs, every total matches React to the cent.
3. Start timer, wait 30s, navigate to Dashboard and back: timer still running with correct elapsed. (React fails this; documented deviation.)
4. Reload mid-timer: elapsed preserved.
5. Stop: toast text and earnings match the React format, sound plays.
6. Quick log 15 minutes yesterday: appears in Recent, counts in Dashboard week bucket.
7. Delete a break: removed everywhere including the ticker.
8. Dashboard: all 5 totals, all 3 charts render, fun fact rotates at 10s, memo shows correct employee number, all 5 doughnut categories visually distinct.
9. Achievements: unlock First Flush, toast fires once, ASCII clipboard payload byte-identical to the React output.
10. Settings: switch to EUR, verify every money figure app-wide changes. Switch to JPY, verify no decimals.
11. Theme to light, reload, still light.
12. Sound off, log a break, no sound.
13. Export, clear, import the exported file, state fully restored.
14. Import a malformed file, error shown, existing state intact.
15. Deep link `/dashboard` on hard refresh loads correctly.
16. Responsive: 320, 768, 1024, 1440 all usable, navbar switches at 768.
17. Keyboard-only navigation reaches every interactive control.

### 9.5 PWA / installability
- Chrome DevTools > Application > Manifest: no errors, all icons resolve (BUG-001 must not recur).
- Install prompt appears; installed app launches standalone in portrait with the navy splash.
- Offline: load once, go offline, reload, app still boots and shows persisted data.
- Lighthouse: PWA installability pass; record Performance, Accessibility, Best Practices, SEO scores as a baseline and compare against React's.

### 9.6 Android build
```
cd app && flutter build apk --debug        # fast loop
cd app && flutter build appbundle --release
```
- Release bundle builds and is signed with the upload key.
- Install on: one physical Android device and one emulator (API level matching min and current).
- Mobile QA sheet (`docs/migration/qa_mobile.md`): the 9.4 script minus web-only items, plus back-button behavior, app backgrounding during a running timer, rotation locked to portrait, share-sheet export, file-picker import, and cold start time.

### 9.7 iOS build
```
cd app && flutter build ipa --release      # macOS only
```
- **Cannot run on this Windows host.** Gate G7 is satisfied by a macOS CI job producing a TestFlight build, or by a recorded decision to defer iOS (Section 7.3).
- If pursued: simulator QA on iPhone SE size and iPhone Pro Max size, plus one physical device via TestFlight.

### 9.8 CI wiring

GitHub Actions, three jobs:
- `analyze-test`: ubuntu, `flutter analyze` + `flutter test --coverage` + coverage threshold.
- `build-web`: ubuntu, `flutter build web --release`, deploy preview to Vercel, comment the URL on the PR.
- `build-android`: ubuntu, `flutter build appbundle --release` with signing secrets, upload artifact.
- `build-ios` (optional, macos-latest): `flutter build ipa`, upload to TestFlight.

Add `flutter analyze` and `flutter test` as required status checks on the Flutter branch before any parity sign-off.

---

## 10. Post-parity expansion (explicitly NOT in this migration)

Everything below is from `fuckcorpo-features.md` and the audit's strategic gaps. None of it is built, planned in detail, or allowed into the codebase before G1 through G9 close. Listed here only so that the boundary is unambiguous.

| Promised feature | Why deferred |
|---|---|
| Anonymous leaderboards by industry and state | Requires a backend that does not exist. Largest single scope item in the product. |
| Optional accounts and cloud sync | Same. Also unlocks web-to-mobile sync, which would supersede Section 8.4's manual export/import. |
| Shareable earnings images | High strategic value (it is the growth loop) but pure net-new. Flutter makes this *easier* than React via `RepaintBoundary` to PNG. First item after parity. |
| Automatic break tracking | Net-new; needs platform APIs and a permissions story. |
| Custom break categories | Net-new; requires the category model to become data rather than an enum. |
| Streaks, daily goals, notifications, weekly digest | The retention gap the audit calls out. Net-new. |
| Per-state labor rights content | Net-new content work. |
| Day-of-week and monthly trend charts | Net-new analytics. |
| Anonymous mode / privacy controls | Net-new. |

**Feature creep control.** Any PR into the Flutter app before G1 that adds a feature not present in the React app is closed, not merged, unless it is on the BUG fix list in Section 1. The parity matrix is the acceptance criterion; if a row does not exist for it, it does not ship yet. The one carve-out is architectural readiness: the model and repository layer may be shaped so that a future backend is possible (for example a `schemaVersion` field and a repository interface), but no networking code and no account UI enters the tree.

---

## 11. Risks and tradeoffs

### 11.1 Flutter web bundle weight and first paint

React ships ~475 kB raw / ~156 kB gzipped JS. Flutter web with CanvasKit typically ships several megabytes on first load (engine + fonts + app), and even the lighter rendering paths are substantially heavier. For a mobile-first product used on cellular in a bathroom, this is the single biggest regression risk of the whole migration.

Mitigations: self-hosted subset fonts, aggressive immutable caching on hashed assets, service worker precache so repeat visits are cheap, a branded loading state in `index.html` so the first paint is not blank, and measuring cold-load transferred bytes as a recorded gate in 9.3. Accept that first load will be slower and decide explicitly whether that is tolerable. If it is not, the honest alternative is to keep the React web app and use Flutter for mobile only. That decision should be made after the first `flutter build web --release` produces real numbers, not before.

### 11.2 Flutter web SEO

Flutter web renders to canvas or a shadow-DOM-heavy tree. Text is not reliably crawlable, there is no server-rendered HTML, and structured content is invisible to most crawlers. The React SPA is also client-rendered and therefore already weak here, but Flutter is meaningfully worse.

This matters because the product's growth model is virality and sharing, and shared links need decent link previews and some organic discoverability. Mitigations: keep `index.html` carrying real `<title>`, meta description, and Open Graph / Twitter card tags with a static preview image; consider a small static marketing page (plain HTML, served at `/` or a separate route) that links into the app; do not expect the app itself to rank. If organic search is a real acquisition channel, that is an argument for keeping a React or static-HTML marketing surface even after the app moves to Flutter.

### 11.3 App Store and Play Store overhead

Going native adds: a $99/year Apple Developer membership, Play Console one-time fee, two review processes, store listings and screenshots per device class, privacy labels, content ratings, and an ongoing release cadence tied to store review latency. The current PWA has none of this.

The name and premise raise real rejection risk (Section 7.2). Budget for at least one rejection cycle on iOS. Weigh honestly whether native distribution is worth it versus a properly installable PWA, which is what the original spec called for and which is currently broken only because three icon files are missing.

### 11.4 localStorage migration

Failure here means users perceive data loss, which for a product whose entire value is an accumulated number is fatal to retention. Risks: the bridge does not run, runs twice, or runs on malformed data. Mitigations: never delete the v0 key, write a backup key on parse failure, make the migration idempotent behind a marker, test against a real pre-existing browser profile (not a synthetic one) as gate G8, and keep the React app rollback-able by domain alias for 30 days.

The parallel-run divergence (Section 8.3 step 5) is a genuine tradeoff: the alternative, continuously syncing two apps against one storage key, is far more complex and more likely to corrupt data. Accept divergence, communicate it, keep the rollback.

### 11.5 Chart fidelity

`fl_chart` is not Chart.js. Tooltips, legend layout, animation curves, and horizontal-bar ergonomics will differ. Parity here should be judged on "same data, same colors, same readable shape", not pixel equality. Define that standard before D6-D8 are reviewed, or chart review becomes an unbounded bikeshed.

### 11.6 Rewrite risk generally

A rewrite of a working product is where subtle behavior gets silently dropped. The parity matrix plus the string-for-string fixture tests (C8, A3) are the defense. The second defense is that the React app stays live and unmodified, so any dispute is settled by opening both apps side by side.

### 11.7 Effort and single-contributor risk

This is a one-contributor repo with two commits of history. A full rewrite plus two store submissions is a large multiple of the effort that would fix the 11 known bugs in the existing React app. That comparison should be made consciously. If the driver for Flutter is native mobile distribution, this plan is sound. If the driver is code quality, fixing the React app is cheaper. If the driver is web performance, Flutter web makes it worse, not better.

---

## 12. Sequenced task list

| # | Task | Phase | Gate touched |
|---|---|---|---|
| 1 | Decide app id, store display name, and iOS defer-or-not (Section 7.3) | P0 | G7 |
| 2 | `flutter create app`, pin SDK, add deps, `analysis_options.yaml` | P0 | G2 |
| 3 | Self-host the 3 font families, commit to `assets/fonts/` | P0 | I2 |
| 4 | Build `core/theme/*` tokens and `fc_theme.dart`, dark + light | P0 | 6.1-6.3 |
| 5 | GitHub Actions: analyze + test job | P0 | G2, G3 |
| 6 | Port domain models incl. `BreakCategory` single owner | P1 | C9 |
| 7 | Port `calculations.dart`, `comparisons.dart`, formatters | P1 | C1-C7, C11 |
| 8 | Port `fun_facts.dart`, `corporate_memo.dart` with fixture tests | P1 | C8 |
| 9 | Port `achievements_catalog.dart` | P1 | C10 |
| 10 | `app_repository` + `shared_prefs_store` + validated import/export | P1 | P1-P5 |
| 11 | `v0_localstorage_to_v1` migrator + tests | P1 | P6, G8 |
| 12 | `app_controller`, `providers`, `timer_controller`, `toast_controller` | P1 | X6, X7 |
| 13 | Shared widget kit + widget gallery screen + goldens | P2 | 6.4 |
| 14 | `fc_app_shell`, `fc_navbar`, `fc_ticker`, responsive switch | P2 | X3-X5 |
| 15 | `go_router` config + onboarding redirect + page transitions | P2 | X2 |
| 16 | Timer screen | P3 | T1-T6 |
| 17 | Dashboard screen + fl_chart translation | P4 | D1-D9 |
| 18 | Achievements screen + ASCII fixture test | P5 | A1-A4 |
| 19 | Settings screen + file export/import on all platforms | P6 | S1-S8 |
| 20 | Landing + 5-step Application wizard | P7 | O1-O7 |
| 21 | Real PWA icons (192, 512, maskable, apple-touch) + `web/manifest.json` | P8 | I1, G4 |
| 22 | Vercel project `fuckcorpo-flutter`, SPA rewrites, cache headers, preview deploys | P8 | G4 |
| 23 | Integration tests + goldens complete | P8 | G3 |
| 24 | Browser QA sheet executed on 4 browsers against a preview | P8 | G5 |
| 25 | Android signing, appbundle, internal track, device + emulator QA | P8 | G6 |
| 26 | iOS via macOS CI to TestFlight, or written defer decision | P8 | G7 |
| 27 | Migration verified on a real pre-existing browser profile | P8 | G8 |
| 28 | Parity matrix sign-off, deviations register final | P9 | G1 |
| 29 | Domain alias cutover to Flutter project; React kept 30 days | P9 | G9 |
| 30 | Tag `react-final`, move React into `legacy/react/`, update CLAUDE.md and CODE_MAP.md | P9 | - |
| 31 | Begin expansion backlog (Section 10), shareable images first | P10 | - |

---

## 13. Documentation follow-ups

- `CLAUDE.md` currently states the repo is in "Design specification phase (pre-development). No source code... exists yet." That is wrong today (F-020) and will be wronger after this migration. Update it at step 30.
- `CODE_MAP.md`, `ENTRY_POINTS.md`, `DATA_FLOW.md`, `IMPORT_GRAPH_SUMMARY.md` all describe the React tree. Regenerate against the Flutter tree at step 30.
- Create and maintain `docs/migration/parity_matrix.md` as the live copy of Section 4. This document is the plan; that file is the tracker.
- Record architectural decisions (Riverpod over Bloc, fl_chart over alternatives, rewrite over strangler, iOS defer decision) in `decisions.md`.
