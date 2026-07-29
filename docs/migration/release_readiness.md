# Release readiness (P9)

Date: 2026-07-28
Overall verdict: **NOT READY. NO-GO for cutover.**

React is live and remains the reference implementation. This document
summarizes what has actually been verified, with exact local paths, and what is
still open. The execution plan for closing the gaps is
`docs/migration/cutover_plan.md`.

Rule applied throughout: a claim appears in the "verified" table only if there
is an artifact on disk that supports it. Local and staged verification is
labelled as such and is never presented as production verification.

---

## Commands run this pass

Run from `app/` on 2026-07-28.

| Command | Result |
|---|---|
| `flutter analyze` | `No issues found! (ran in 1.5s)`, exit 0 |
| `flutter test --reporter compact --concurrency=1` | `00:22 +269: All tests passed!`, 269 tests, exit 0 |
| `flutter build web` | `Built build\web`, exit 0. Wasm dry run succeeded (advisory only) |

Not run this pass and still unmeasured: domain and data coverage, Android
release rebuild, any app bundle, any iOS build.

---

## Verified evidence

### Code health

| Claim | Evidence |
|---|---|
| Static analysis clean | `flutter analyze`, this pass |
| 269 unit and widget tests green | `flutter test`, this pass |
| Web release artifact builds | `flutter build web`, this pass, output `app/build/web` |

### Android, emulator release APK

Scope: emulator only, release APK, debug-signed. Not a physical device, not a
signed app bundle, not a Play track.

| Claim | Evidence |
|---|---|
| Release APK builds and installs | `docs/migration/qa_android_runtime.md`, APK `app/build/app/outputs/flutter-apk/app-release.apk` (50.6 MB), install result `Success` on `emulator-5554`, Android 17 / API 37, package `com.fuckcorpo.fuckcorpo` |
| First-run onboarding completes end to end | `.hermes/android-proof/01-launch.png`, `02-applicant.png`, `03-skills.png`, `04-offer.png`, `05-timer-home.png` |
| Timer start, run, and stop logs a break | `.hermes/android-proof/12-timer-live.png`, `15-running-timer.png`, `16-stopped-timer.png`. Observed `00:03` / `$0.05` running, toast `Break logged! You earned $0.06` |
| Quick log validates input rather than accepting the placeholder | `docs/migration/qa_android_runtime.md` runtime notes; toast `Enter a whole number of minutes between 1 and 480.` |
| Dashboard empty state, then populated after a real break | `.hermes/android-proof/10-dashboard-live.png`, `17-dashboard-after-start-stop.png` |
| Achievements grid renders with unlock counter | `.hermes/android-proof/11-achievements-live.png`, `0 / 11 unlocked` |
| Settings renders salary and derived per-minute rate | `.hermes/android-proof/current.png`, `124800` annual, `$1.00/min` |
| Run summary | `.hermes/android-proof/android-runtime-summary.txt` |

Caveat recorded at the source: UIAutomator XML dumps returned stale semantics
during later captures because the ticker animates continuously, so the `.xml`
dumps are weaker evidence than the `.png` screenshots. Screenshots are
authoritative.

### Web, local hosted static stage

Scope: `app/build/web` served by a local static server with SPA rewrites at
`http://127.0.0.1:8787`. This is **not** a Vercel or production deployment.

| Claim | Evidence |
|---|---|
| Deep links survive a hard refresh under SPA rewrite | `docs/migration/qa_browser_hosted.md`: `/`, `/dashboard`, `/achievements`, `/settings` each HTTP 200 |
| Fresh profile reaches branded onboarding | `.hermes/web-proof/01-fresh-landing.png` |
| Routes render after onboarding | `.hermes/web-proof/03-dashboard.png`, `04-achievements.png`, `05-settings.png`, `06-timer.png` |
| Server and harness | `.hermes/scripts/spa_server.py`, `.hermes/scripts/web_qa_playwright.spec.cjs`, Playwright Chromium at 390x844 |

### Data migration bridge, real browser

Scope: real Chromium profile, real built artifact, synthetic-but-realistic React
`fuckcorpo_data` payload. Stronger than the unit-only status previously recorded
for parity row P6. Weaker than a copy of a genuine production user profile,
which gate G8 still requires.

| Claim | Evidence |
|---|---|
| React legacy key preserved byte-for-byte | `.hermes/web-proof/web-qa-report.txt`, `legacy_preserved=true` |
| Flutter v1 state written under its own key | `v1_written=true`, keys `flutter.fuckcorpo_state_v1`, `flutter.fuckcorpo_migrated_from_v0`, `fuckcorpo_data` |
| One-time marker set, no spurious backup | `marker_true=true`, `backup_absent=true` |
| Migrated values correct | `migrated_salary=65000`, `migrated_currency=EUR`, `migrated_break_count=2`, `migrated_onboarded=true` |
| App routes into the onboarded shell, currency respected | `.hermes/web-proof/02-after-v0-migration.png`; ticker `€10.42` / `2`, Lifetime `€10.38`, Settings `€0.52/min`, Achievements `1 / 11 unlocked` |
| Corrupt legacy payload does not brick the app | `.hermes/web-proof/07-corrupt-v0-backup.png`; `corrupt_backup_written=true`, `corrupt_marker_true=true`, `corrupt_v1_absent=true`, app returns to first-run onboarding |
| Bridge unit coverage | `app/lib/data/migrations/v0_localstorage_to_v1.dart`, 13 tests (migrates, never destroys `fuckcorpo_data`, idempotent, marker-guarded, partial payload defaults, corrupt payload backed up, non-web skip) |

### Design and configuration

| Claim | Evidence |
|---|---|
| Hosting config authored, never deployed | `app/vercel.json` |
| PWA manifest, `index.html`, icons, favicon, apple-touch icon, and 1200x630 social card internally coherent and test-enforced | `app/web/manifest.json`, `app/web/icons/`, `app/web/social/og-card.png`, `app/test/web/pwa_config_test.dart`, `app/test/web/brand_assets_test.dart` |
| Deliberate divergences from React are documented | `docs/migration/deviations.md`, 10 bug-fix deviations plus 5 implementation deviations |

---

## Open items

### Blockers

| # | Item | Where tracked |
|---|---|---|
| B1 | No staging deployment. The `fuckcorpo-flutter` Vercel project does not exist, so PWA installability, offline load, and service-worker update are all unverified. Lighthouse has never been run | cutover plan section 3, parity row I4, gate G4 / G5 |
| B2 | Migration never run against a copy of a genuine pre-existing user profile | cutover plan section 4, gate G8 |
| ~~B3~~ | ~~PWA icons/social card missing or placeholder-only~~ **CLOSED for generated assets.** New generated brand assets include PWA icons, favicon, apple-touch icon, maskable icons, and `app/web/social/og-card.png` wired through Open Graph/Twitter meta. Final human brand approval remains pre-launch, but this is no longer a repo-local blocker | `docs/migration/deviations.md` open item 2, `app/test/web/brand_assets_test.dart` |
| ~~B4~~ | ~~Fonts are not self-hosted~~ **CLOSED.** All three families are committed under `app/assets/fonts/` as upstream OFL variable fonts, declared in `pubspec.yaml`, and confirmed present in `build/web/assets/FontManifest.json`. `app/test/core/theme/fonts_test.dart` fails if a declared asset goes missing or is not a real font binary | `docs/migration/deviations.md` open item 1, parity row I2 |
| B5 | No release keystore, no signed app bundle, nothing on a Play track | cutover plan section 5, gate G6 |
| B6 | iOS has never been built. Windows host cannot produce an IPA. No written defer decision exists | cutover plan section 5, gate G7 |
| ~~B7~~ | ~~Parity matrix rows 4.4 through 4.8 unswept~~ **CLOSED locally.** Local React build and Flutter web build were served side by side; mobile and desktop screenshots captured for landing, timer, dashboard, achievements, and settings. Human visual review still applies, and staged/prod QA is separate | `docs/migration/qa_parity_sweep.md`, `.hermes/parity-proof/contact-sheet.html` |

### Non-blocking, resolve or waive in writing

| # | Item |
|---|---|
| N1 | Domain and data coverage (>= 90%) has never been measured (gate G3) |
| N2 | `flutter analyze` and `flutter test` do not run in CI (parity row I3) |
| ~~N3~~ | ~~A failed v0 migration is silent to the user~~ **CLOSED in-app.** The bridge now sets `fuckcorpo_v0_migration_failed`; Settings renders a dismissible Import Notice card naming the `fuckcorpo_data_backup` key. Residual gap: recovery is a manual devtools step, not a one-click export. See `deviations.md` open item 3 |
| ~~N4~~ | ~~Nothing in the UI states that web and mobile do not sync~~ **CLOSED.** Settings > Data Management leads with copy stating the data is per-device, that nothing syncs, and that Export/Import is the transfer path. See `deviations.md` open item 4 |
| N5 | Android QA is emulator-only. No physical device run |

Recommendation: N3 and N4, previously called blocking for a public cutover, are
now addressed in the UI and covered by tests. N1, N2, and N5 remain reasonable
to waive with a written note. The remaining data-trust residue is N3's manual
recovery path, which is acceptable because the payload is never destroyed.

---

## Explicitly not claimed

To keep this document honest, none of the following has happened:

- No production deployment. No Vercel deployment of any kind, preview included.
- No custom domain change. React's deploy path and domains are untouched.
- No iOS build, simulator run, TestFlight upload, or App Store submission.
- No Play Console upload, internal track, or physical Android device install.
- No Lighthouse audit, PWA install test, or offline reload test.
- No git commit, push, tag, or branch operation in this pass.
- No React source file was modified, deleted, or deprecated.

---

## Next action

Work `docs/migration/cutover_plan.md` section 2 blockers in order. Repo-local parity work is now effectively complete; B1 (staging) is the item unblocking the remaining external verification: real-profile migration, Lighthouse/install/offline, and production-domain cutover evidence.
Cutover requires the go/no-go checklist in section 8 of that document to be
fully checked and an explicit written approval from the repository owner.
