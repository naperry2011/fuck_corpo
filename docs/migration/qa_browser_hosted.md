# Hosted Flutter web QA - local static stage

Date: 2026-07-28

## Scope
Hosted-browser smoke verification of `app/build/web` served through a local static server with SPA rewrites. This verifies the Flutter web artifact as a staged static site, not a production deployment.

## Server/artifact
- Build artifact: `app/build/web`
- Local URL: `http://127.0.0.1:8787`
- Server: `.hermes/scripts/spa_server.py`
- Browser automation: Playwright Chromium, mobile viewport 390x844, deviceScaleFactor 2
- Proof output: `.hermes/web-proof/`

## Static server checks
- `/`: HTTP 200
- `/dashboard`: HTTP 200, rewritten to `index.html`
- `/achievements`: HTTP 200, rewritten to `index.html`
- `/settings`: HTTP 200, rewritten to `index.html`

## Fresh first-run smoke
Proof:
- `.hermes/web-proof/01-fresh-landing.png`

Observed:
- Branded onboarding renders.
- Visible copy: `$POOP +420.69%`, `QUARTERLY EARNINGS REPORT`, `APPLICATION FOR EMPLOYMENT`, `BEGIN APPLICATION`.

## React v0 localStorage migration bridge
Proof:
- `.hermes/web-proof/02-after-v0-migration.png`
- `.hermes/web-proof/web-qa-report.txt`

Injected legacy key:
- `fuckcorpo_data`

Observed localStorage after reload:
- `legacy_preserved=true`
- `v1_written=true`
- `marker_true=true`
- `backup_absent=true`
- `migrated_salary=65000`
- `migrated_currency=EUR`
- `migrated_break_count=2`
- `migrated_onboarded=true`
- Keys: `flutter.fuckcorpo_migrated_from_v0`, `flutter.fuckcorpo_state_v1`, `fuckcorpo_data`

Visual result:
- App routed into onboarded app shell rather than onboarding.
- Timer route showed EUR values and the ticker reflected migrated lifetime/session state (`€10.42`, `2`).
- React legacy payload was preserved. Flutter wrote the v1 SharedPreferences-web keys using the `flutter.` prefix.

## Route smoke after migration
Proof:
- `.hermes/web-proof/03-dashboard.png`
- `.hermes/web-proof/04-achievements.png`
- `.hermes/web-proof/05-settings.png`
- `.hermes/web-proof/06-timer.png`

Observed:
- Dashboard opened from the fixed bottom nav and rendered `YOUR QUARTERLY EARNINGS REPORT` with EUR earnings cards, including Lifetime Earnings `€10.38`.
- Achievements opened from nav and rendered `INVESTOR ACHIEVEMENTS`, `1 / 11 unlocked`, `First Flush` unlocked, and locked badges below.
- Settings opened from nav and rendered `ACCOUNT SETTINGS`, `Compensation Package`, salary `65000`, and `Per-minute rate: €0.52/min`.
- Timer opened from nav and rendered category chips, `€0.00`, `START BREAK`, and Quick Log.

## Corrupt legacy data smoke
Proof:
- `.hermes/web-proof/07-corrupt-v0-backup.png`
- `.hermes/web-proof/web-qa-report.txt`

Injected legacy key:
- `fuckcorpo_data = {not json`

Observed:
- `corrupt_backup_written=true`
- `corrupt_marker_true=true`
- `corrupt_v1_absent=true`
- Visual state returned to non-bricked first-run onboarding (`APPLICATION FOR EMPLOYMENT`, `BEGIN APPLICATION`).

## Notes
- Flutter web text is rendered visually and Playwright `innerText()` is not reliable for all screen assertions, so screenshot proof is authoritative for route content.
- Local static QA is not a production/Vercel deployment. It does verify build output, SPA rewrites, onboarded routing, and browser localStorage migration behavior.

## Remaining before cutover
- Staged/production-hosted URL QA after deployment.
- Physical Android QA if required beyond emulator release APK.
- iOS/TestFlight QA on macOS.
- Final icon/brand approval.
- P9 cutover/archive plan and explicit approval before replacing React.
