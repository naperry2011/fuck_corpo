# P9 cutover plan (Flutter replaces React)

Date: 2026-07-28
Status: **PLAN ONLY. Not approved, not executed.**

React is now deprecated/frozen for new product work, but remains available as the rollback and migration-reference implementation. Nothing in this document has been deployed, committed, or pushed. Every step below requires explicit human approval before it runs. See `docs/migration/react_deprecation.md`.

Source of truth for phase and gate definitions:
`.hermes/plans/2026-07-28_164551-flutter-migration-parity-plan.md`.

---

## 1. Prerequisites already satisfied

These are verified locally with artifacts on disk. They are necessary, not
sufficient.

| # | Prerequisite | Evidence |
|---|---|---|
| A1 | Domain, data, widgets, timer, onboarding, settings, dashboard, achievements ported | `app/lib/`, phase results under `.hermes/flutter-migration-p*-result.json` |
| A2 | Static analysis clean | `flutter analyze` exit 0, `No issues found!` (rerun this pass, see section 9) |
| A3 | Unit and widget suite green | `flutter test --reporter compact --concurrency=1`, 269 tests passing |
| A4 | Web release artifact builds | `flutter build web`, output `app/build/web` |
| A5 | Android release APK builds and installs | `docs/migration/qa_android_runtime.md`, APK at `app/build/app/outputs/flutter-apk/app-release.apk` |
| A6 | Android runtime flows exercised on emulator | `docs/migration/qa_android_runtime.md`; screenshots `.hermes/android-proof/01-launch.png` through `.hermes/android-proof/17-dashboard-after-start-stop.png`, summary `.hermes/android-proof/android-runtime-summary.txt` |
| A7 | Hosted static web QA with SPA rewrites | `docs/migration/qa_browser_hosted.md`; server `.hermes/scripts/spa_server.py`, proof `.hermes/web-proof/01-fresh-landing.png` through `.hermes/web-proof/06-timer.png` |
| A8 | v0 React localStorage migration bridge exercised in a real browser | `docs/migration/qa_browser_hosted.md`; `.hermes/web-proof/02-after-v0-migration.png`, `.hermes/web-proof/web-qa-report.txt` |
| A9 | Corrupt v0 payload does not brick the app, backup written | `.hermes/web-proof/07-corrupt-v0-backup.png`, `.hermes/web-proof/web-qa-report.txt` |
| A10 | Hosting config authored for the Flutter web target | `app/vercel.json` (SPA rewrite, immutable hashed assets, `max-age=0` on `index.html` and the service worker). Unit checked, never deployed |
| A11 | Deliberate divergences from React recorded | `docs/migration/deviations.md` |

Note on A8: the injected legacy payload was synthetic but shaped like a real
React `fuckcorpo_data` record, run against a real Chromium browser profile
through the built web artifact. That is stronger than the unit-only status
recorded earlier for parity row P6, and weaker than a copy of a genuine
production user profile. Gate G8 below still requires the latter.

---

## 2. Remaining blockers and gates

Ordered by what blocks what. Nothing in P9 proceeds while a BLOCKER is open.

### Blockers (hard stop)

| # | Blocker | Owner action | Reference |
|---|---|---|---|
| B1 | No staging deployment exists. The `fuckcorpo-flutter` Vercel project has never been created | Section 3 | parity row I4 |
| B2 | Migration never verified against a copy of a genuine pre-existing user profile | Section 4 | gate G8 |
| ~~B3~~ | ~~PWA icons/social card missing or placeholder-only~~ **CLOSED for generated assets.** Final human brand approval remains before public release | Generated PWA icons, favicon, apple-touch icon, maskable icons, and 1200x630 social card committed and tested | `docs/migration/deviations.md` open item 2, `app/test/web/brand_assets_test.dart` |
| ~~B4~~ | ~~Fonts are not self-hosted~~ **CLOSED** | Upstream OFL variable fonts committed under `app/assets/fonts/`, wired in `pubspec.yaml`, present in `build/web/assets/FontManifest.json`, guarded by `app/test/core/theme/fonts_test.dart` | deviations open item 1, parity row I2 |
| B5 | Android release build is unsigned. No keystore, no `flutter build appbundle --release`, nothing on an internal track | Section 5 | gate G6 |
| B6 | iOS has never been built. Windows host cannot produce an IPA | Section 5, or a written defer decision | gate G7 |
| ~~B7~~ | ~~Parity matrix rows 4.4 through 4.8 unswept~~ **CLOSED locally.** Staged/production sweep still separate | React and Flutter local builds served side by side; mobile/desktop screenshots captured for landing, timer, dashboard, achievements, settings | `docs/migration/qa_parity_sweep.md`, `.hermes/parity-proof/contact-sheet.html` |

### Non-blocking but must be resolved or explicitly waived

| # | Item | Reference |
|---|---|---|
| N1 | Domain and data coverage gate (>= 90%) has never been measured | gate G3 |
| N2 | `flutter analyze` and `flutter test` do not run in CI | parity row I3 |
| ~~N3~~ | ~~A failed v0 migration is silent~~ **CLOSED for the notice.** Settings shows a dismissible Import Notice naming `fuckcorpo_data_backup`. One-tap export of the raw payload is still a TODO | deviations open item 3 |
| ~~N4~~ | ~~No copy states that web and mobile data do not sync~~ **CLOSED.** Settings > Data Management leads with the per-device / no-sync / use-export copy | deviations open item 4 |
| N5 | Physical Android device QA has not been done. Emulator only | `docs/migration/qa_android_runtime.md` |

N3 and N4 were called must-close-before-cutover rather than waivable. Both are
now implemented and tested, so neither needs a waiver. N1, N2, N5 are acceptable
to waive in writing if the schedule demands it.

---

## 3. Staging deployment plan

Goal: a Flutter web URL that is real, hosted, and separate from the React
production domain. React's deploy path stays untouched throughout.

Preconditions: B4 closed (self-hosted fonts) - done. B3 generated assets closed;
final human brand approval can happen during/after staging visual review.

1. Create a **new** Vercel project `fuckcorpo-flutter`, root directory `app/`.
   Do not attach it to the existing React project and do not touch the React
   project's domains or build settings.
2. Confirm the project picks up `app/vercel.json`: `outputDirectory` is
   `build/web`, the SPA rewrite is active, hashed assets are immutable, and
   `index.html` plus `flutter_service_worker.js` are `max-age=0`.
3. Deploy to a **preview** URL only. No production alias, no custom domain.
4. Staging smoke, repeating the local hosted script against the deployed URL
   (`.hermes/scripts/web_qa_playwright.spec.cjs`, retargeted):
   - `/`, `/dashboard`, `/achievements`, `/settings` each return 200 on a hard
     refresh (deep-link rewrite works on real infrastructure).
   - Fresh profile reaches the onboarding flow.
   - Full onboarding to app shell, log a break, verify dashboard, achievements,
     and settings render the logged value.
5. PWA verification, which local static serving could not establish:
   - Lighthouse PWA audit against the preview URL.
   - Install the app from Chrome desktop and Android Chrome, confirm the icon,
     name, and standalone launch.
   - Load once online, go offline, reload, confirm the shell still boots from
     the service worker.
   - Deploy a second time and confirm the update is picked up rather than a
     stale service worker being served.
6. Record everything in `docs/migration/qa_web_staging.md` with proof under
   `.hermes/web-staging-proof/`.

Gate G4 and G5 close only when step 6 exists and is green.

---

## 4. Data migration verification plan

This is the highest-risk part of cutover. A user who loses their break history
has no recovery path, because there is no backend.

Design recap (`docs/migration/deviations.md` D-103, D-104):
Flutter writes `flutter.fuckcorpo_state_v1` and never writes React's
`fuckcorpo_data`. The bridge runs exactly once, guarded by
`flutter.fuckcorpo_migrated_from_v0`. After that the two apps diverge
permanently by design.

### Verification steps

1. **Real-profile test (closes B2 / gate G8).** Take a Chrome profile that has
   genuinely used the live React app (the maintainer's own is acceptable, with a
   directory copy taken first). Point it at the staging URL. Verify:
   - `fuckcorpo_data` is byte-identical before and after.
   - `flutter.fuckcorpo_state_v1` contains the same salary, currency, settings,
     onboarded flag, and break count as the React payload.
   - Achievement unlock count matches what React shows for the same data.
   - Dashboard totals for today, week, month, year, and lifetime match React's
     within the known half-open range deviation (D-101). Any mismatch other than
     an exactly-midnight timestamp is a stop.
2. **Idempotency.** Reload three times. The marker prevents re-migration and
   the v1 payload is unchanged.
3. **Rollback safety.** After migrating, open React in the same profile.
   React must still work off the untouched `fuckcorpo_data`.
4. **Corrupt payload.** Already verified locally
   (`.hermes/web-proof/07-corrupt-v0-backup.png`). Repeat once on staging:
   backup written to `fuckcorpo_data_backup`, marker set, app boots to
   onboarding rather than a blank screen.
5. **Export/import round trip.** Export from React, import into Flutter, verify
   the break list, then export from Flutter and re-import to confirm the file
   format survives its own round trip.
6. **Mobile has no bridge.** Confirm and document that an Android install
   starts empty, and that the only path from web data to mobile is manual
   export/import. This is what N4 must say in Settings.

Record in `docs/migration/qa_migration_real_profile.md`.

---

## 5. Android and iOS release plan

### Android

1. Generate an upload keystore. Store it outside the repo. Add
   `app/android/key.properties` to `.gitignore` and never commit either file.
2. Wire release signing in `app/android/app/build.gradle`, replacing the debug
   signing config currently used for release builds.
3. `flutter build appbundle --release`, confirm the AAB is produced.
4. Upload to the Play Console **internal testing** track. Complete the data
   safety form honestly: all data is stored on-device, nothing is collected or
   transmitted.
5. Install from the internal track on at least one physical device and repeat
   the flow set already covered on emulator in
   `docs/migration/qa_android_runtime.md` (onboarding, timer start/stop,
   quick log validation, dashboard, achievements, settings).
6. Only after internal track passes: closed testing, then production. Staged
   rollout at 10 percent for 48 hours before widening.

Gate G6 closes at step 5.

### iOS

The current host is Windows, so no IPA can be produced here. Two acceptable
outcomes, and silence is not one of them:

- **Ship it:** on a macOS host, `flutter build ipa`, upload to TestFlight,
  internal test the same flow set, then App Store review.
- **Defer it:** write `docs/migration/ios_defer_decision.md` stating that iOS is
  out of scope for this cutover, that iOS users continue on the React web app
  (which remains reachable, see section 7), and who owns revisiting it.

Gate G7 closes with either artifact.

---

## 6. Rollback plan

Rollback must stay cheap at every step. It does, because React is never
modified and its data key is never written.

| Trigger | Action | Recovery time |
|---|---|---|
| Staging smoke fails | Stop. Nothing is user-facing. Delete the preview | Immediate |
| Production web regression after domain switch | Re-point the production domain alias back to the React Vercel project. React reads `fuckcorpo_data`, which Flutter never touched, so user data is intact | Minutes |
| Data loss or corruption reported | Same domain revert, plus instruct affected users to check `fuckcorpo_data_backup` in devtools. Halt the Play rollout | Minutes for web, hours for mobile |
| Android crash spike | Halt the staged rollout in the Play Console. Previously installed versions are unaffected; there is no server dependency | Immediate halt |
| Migration bug found post-cutover | The `flutter.fuckcorpo_migrated_from_v0` marker can be cleared per-profile to re-run the bridge, because `fuckcorpo_data` is still present | Per user |

Rollback preconditions to establish **before** cutover:
- Record the exact React production deployment ID to revert to.
- Confirm the React Vercel project is not deleted, unlinked, or reconfigured at
  any point during P9.
- Keep the React source on `main` untouched for the full 30-day window in
  section 7.

---

## 7. 30-day React archive plan

React is not deleted at cutover. It is demoted, then archived, then removed only
after a quiet period.

| Day | Action |
|---|---|
| 0 | Production domain points at the Flutter deployment. React deployment stays live on its own Vercel-assigned URL. Nothing is deleted |
| 0 | Tag the last React-only commit as `react-final` for a clean revert point |
| 0 to 7 | Watch for data-loss reports, install failures, and migration complaints. Any of these triggers section 6 |
| 7 | If clean: add a banner to the React deployment pointing at the new app and noting that its data stays local to that browser |
| 30 | If still clean: move `src/`, `index.html`, `vite.config.js`, and React-only config into `legacy/react/` in a single commit. Do not delete history |
| 30 | Update `README.md`, `CLAUDE.md`, and `CODE_MAP.md` to describe Flutter as the application and React as archived reference |
| 30+ | The React Vercel deployment may be paused, not deleted, so `react-final` remains redeployable |

Nothing in this table is executed by this phase, and none of it happens without
a second explicit approval on day 0 and again on day 30.

---

## 8. Go / no-go checklist

Every line must be checked by a human against a named artifact. An unchecked
line is a no-go. This checklist is currently **NO-GO**.

### Build and code health
- [ ] `flutter analyze` clean on the cutover commit
- [ ] `flutter test --reporter compact --concurrency=1` fully green
- [ ] Domain and data coverage measured and >= 90%, or waived in writing (N1)
- [ ] Analyze and test run in CI, or waived in writing (N2)

### Parity
- [ ] Parity matrix rows 4.1 through 4.9 re-swept against the live React app, all `DONE` (B7, gate G1)
- [ ] Every entry in `docs/migration/deviations.md` is either LANDED or consciously accepted
- [x] Fonts self-hosted (B4). Bundled and test-guarded; visual confirmation that they *render* as intended is still pending a staging deploy (B1)

### Assets
- [ ] Brand-final PWA icons and favicon replace the placeholders (B3)
- [ ] 1200x630 social card exists and `og:image` points at it

### Web
- [ ] Staging deployment exists on `fuckcorpo-flutter` (B1)
- [ ] All four routes return 200 on hard refresh against the deployed URL
- [ ] Lighthouse PWA audit passes on the deployed URL
- [ ] Install, offline reload, and service-worker update verified on the deployed URL
- [ ] `docs/migration/qa_web_staging.md` written with proof paths

### Data
- [ ] Real pre-existing browser profile migrated with totals matching React (B2, gate G8)
- [ ] `fuckcorpo_data` verified untouched after migration
- [ ] Migration idempotent across reloads
- [ ] React still functional in the same profile post-migration
- [ ] Export/import round trip verified both directions
- [x] In-app notice on failed migration implemented (N3). One-tap export of the backed-up payload remains a TODO
- [x] Settings states that web and mobile do not sync (N4)

### Mobile
- [ ] Release keystore generated, stored outside the repo, signing wired (B5)
- [ ] `flutter build appbundle --release` succeeds
- [ ] Play internal testing track live and verified on a physical device (B5, N5, gate G6)
- [ ] iOS TestFlight verified, or `docs/migration/ios_defer_decision.md` written (B6, gate G7)

### Rollback readiness
- [ ] `react-final` tag created
- [ ] React production deployment ID recorded
- [ ] React Vercel project confirmed intact and untouched
- [ ] Domain revert procedure tested at least once against the staging alias

### Approval
- [ ] Explicit written go from the repository owner, referencing this document
- [ ] Cutover window agreed, with someone available to execute section 6

---

## 9. Verification run for this document pass

See `docs/migration/release_readiness.md` section "Commands run this pass" for
the exact results of `flutter analyze`, `flutter test`, and `flutter build web`
executed alongside these docs.
