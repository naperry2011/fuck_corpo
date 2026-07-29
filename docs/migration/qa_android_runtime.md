# Android runtime QA - Flutter parity build

Date: 2026-07-28

## Scope
Runtime verification of the Flutter port on an Android emulator after the code parity phases passed local tests and web build.

This is not production cutover approval. React remains the live/reference implementation until hosted browser QA, Android release QA, iOS/TestFlight QA, final assets, and rollback/cutover gates pass.

## Device and artifact
- Device: `emulator-5554`
- Model: `sdk_gphone16k_x86_64`
- Android: 17 / API 37
- Package: `com.fuckcorpo.fuckcorpo`
- Version: `versionName=1.0.0`, `versionCode=1`
- APK: `app/build/app/outputs/flutter-apk/app-release.apk`
- Install method: `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk`
- Install result: `Success`

## Code/build gates rerun before install
- `flutter analyze`: exit 0, `No issues found!`
- `flutter test --reporter compact --concurrency=1`: exit 0, `All tests passed!` / 269 tests
- `flutter build apk --release`: exit 0, built `app-release.apk` (50.6 MB)

## Runtime flows verified

### First-run onboarding
Proof files:
- `.hermes/android-proof/01-launch.png`
- `.hermes/android-proof/02-applicant.png`
- `.hermes/android-proof/03-skills.png`
- `.hermes/android-proof/04-offer.png`
- `.hermes/android-proof/05-timer-home.png`

Observed:
- Fresh `pm clear` launch reached branded landing/application flow.
- `BEGIN APPLICATION` advanced to Applicant Information.
- `CONTINUE` advanced to Skills Assessment.
- `SUBMIT FOR REVIEW` advanced through background check to Offer Letter.
- Salary `124800` was entered/accepted.
- `ACCEPT OFFER & BEGIN` persisted onboarding and routed into the app shell.

### Settings
Proof file:
- `.hermes/android-proof/current.png`

Observed:
- Settings route opens from bottom nav.
- Compensation Package shows `124800`, Annual, and calculated `Per-minute rate: $1.00/min`.
- Employee profile form is present with Currency, Industry, and State/Region fields.

### Timer
Proof files:
- `.hermes/android-proof/12-timer-live.png`
- `.hermes/android-proof/15-running-timer.png`
- `.hermes/android-proof/16-stopped-timer.png`

Observed:
- Timer route opens from bottom nav.
- Category chips render: Bathroom, Smoke Break, Mental Health Moment, Coffee Break, Other.
- Start action changes the screen to running state: timer advanced to `00:03`, earnings showed `$0.05`, button became `STOP & LOG`.
- Stop action logged the break and showed success toast: `Break logged! You earned $0.06`.

### Dashboard
Proof files:
- `.hermes/android-proof/10-dashboard-live.png`
- `.hermes/android-proof/17-dashboard-after-start-stop.png`

Observed:
- Dashboard route opens from bottom nav.
- Empty state appears before any break data: `No data yet. Start tracking your breaks to see your earnings report.`
- After a live start/stop break, dashboard populated with earnings cards: Today, This Week, This Month, This Year, and Lifetime Earnings all showed `$0.05` at capture time.
- Market Analysis section begins below the summary cards.

### Achievements
Proof file:
- `.hermes/android-proof/11-achievements-live.png`

Observed:
- Achievements route opens from bottom nav.
- Header `INVESTOR ACHIEVEMENTS` renders with `0 / 11 unlocked` before qualifying data.
- Badge grid renders locked cards including First Flush, The Regular, Consistency Champion, Century, $100 Club, $1,000 Club, $10,000 Club, and Marathon Runner.

## Runtime notes
- UIAutomator XML dumps sometimes returned stale semantics with `ERROR: could not get idle state`, likely because the app ticker animates continuously. Screenshots are the authoritative runtime proof for the later route captures.
- The quick-log field visibly showed `15`, but that is the placeholder/hint. Tapping `Log Break` without entering text correctly produced the validation toast `Enter a whole number of minutes between 1 and 480.` This is expected behavior, not a runtime blocker.
- The live Start/Stop path was used to create real break data for Dashboard proof.

## Remaining release/cutover gates
- Hosted Flutter web/browser QA against a staged URL.
- Migration bridge test against copied/prod-like React browser localStorage.
- Android device QA on a real physical phone, if required beyond emulator release APK QA.
- iOS/TestFlight QA on macOS.
- Final icon/brand asset approval.
- P9 cutover/archive plan and explicit approval before replacing React.
