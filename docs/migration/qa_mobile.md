# Mobile QA and release readiness (gates G6, G7)

Derived from the migration plan Sections 7, 8.4 and 9.6.

**No mobile QA has been performed.** Nothing has been installed on a device or
an emulator, nothing has been signed, and nothing has been uploaded to any
store. The single verified fact is that a debug APK compiles on this machine.

---

## Android

### Verified locally

| Check | Command | Result | Date |
|---|---|---|---|
| Debug APK compiles | `cd app && flutter build apk --debug` | PASS, `Built build\app\outputs\flutter-apk\app-debug.apk` (145 MB debug, unshrunk) | 2026-07-28 |

That is the whole list. A debug APK compiling proves the Gradle project is
coherent. It proves nothing about runtime behavior, release shrinking, or store
readiness.

### Not verified

| Item | Status |
|---|---|
| `flutter build appbundle --release` | NOT RUN. Requires an upload keystore, which does not exist |
| R8 / resource shrinking does not break `fl_chart` | NOT VERIFIED. Only reachable via a release build |
| Install on a physical device | NOT RUN |
| Install on an emulator | NOT RUN |
| Play Console app created | NO |
| Internal testing track | NO |
| Data Safety declaration | NOT SUBMITTED |
| Content rating questionnaire | NOT SUBMITTED |
| Privacy policy URL | DOES NOT EXIST |

### Environment blockers on this machine

`flutter doctor` reports the Android toolchain as incomplete:

- `cmdline-tools` component is missing.
- Android SDK license status unknown; `flutter doctor --android-licenses` has not
  been accepted.

The debug build succeeded regardless, but these should be resolved before
treating any Android result from this machine as trustworthy.

### Configuration decisions still open

| Decision | Current value | Note |
|---|---|---|
| `applicationId` | `com.fuckcorpo.fuckcorpo` | This is the `flutter create` default, not a decision. It is **immutable after the first Play upload**. Plan Section 7.1 calls for `com.fuckcorpo.app`. Change it before the first upload or live with it forever |
| `minSdk` | Flutter default | Not pinned. Plan calls for 23+ |
| Store display name | Not chosen | The app name contains profanity. Plan 7.1 item 7 requires a store-safe fallback name ready **before** submission |
| Launcher icon | Flutter default | Adaptive icon with navy background and the `$` mark not built |
| Splash screen | Flutter default | `flutter_native_splash` with `#0a1128` not configured |
| Signing | None | No upload keystore. `key.properties` not created, not gitignored |

### Mobile QA script (to run once a build is installable)

Everything below is `NOT RUN`. Run the browser sheet's "Core flows" section
first, minus the web-only rows (15, 16, 17, and all of the PWA section), then
these mobile-specific rows.

| # | Step | Expected | Status |
|---|---|---|---|
| N1 | Android back button from each screen | Sensible pop, no dead ends, no accidental app exit mid-timer | NOT RUN |
| N2 | Background the app with a timer running, wait 2 minutes, return | Elapsed correct, derived from the wall clock | NOT RUN |
| N3 | Kill and relaunch with a timer running | Timer rehydrates | NOT RUN |
| N4 | Rotate the device | Locked to portrait | NOT RUN |
| N5 | Settings > Export Data | Opens the share sheet, not a download | NOT RUN |
| N6 | Settings > Import Data | File picker opens, filters to JSON, imports | NOT RUN |
| N7 | Import a **v0** export produced by the React web app | Full state restored, including breaks and achievements | NOT RUN |
| N8 | Import a v1 export produced by Flutter web | Full state restored | NOT RUN |
| N9 | Import `{"breaks":"x"}` | Rejected with an error, existing state untouched | NOT RUN |
| N10 | Cold start time | Recorded as a baseline | NOT RUN |

---

## The web-to-mobile boundary (plan Section 8.4)

**Android and iOS cannot read browser localStorage.** The v0 bridge implemented
in `app/lib/data/migrations/v0_localstorage_to_v1.dart` is web-only by
construction: `openLegacyStore()` returns `null` on every non-web platform, and
there is a test asserting that a null legacy store skips cleanly. This is a
platform boundary, not a gap to be closed.

The only supported transfer is user-driven export then import. Rows N7 and N8
exist specifically to prove both payload versions import.

Two requirements this places on the product, neither of which is done:

1. `file_picker` and share-sheet export are not wired on Android or iOS. The
   Settings screen's export/import path has only been exercised in tests, not on
   a device.
2. The Settings screen must carry a line of copy stating that mobile and web do
   not sync and that export/import is the transfer mechanism. **This copy does
   not exist yet.** Without it, users will read the divergence as data loss.

---

## iOS (gate G7)

**iOS builds cannot be produced on this Windows machine.** `flutter build ipa`,
code signing, and simulator testing all require macOS with Xcode. There is no
workaround.

Gate G7 is satisfied by either a verified TestFlight build or a written, dated
decision to defer. **Neither exists.** G7 is currently unsatisfied by silence,
which the plan explicitly calls out as not acceptable.

The three options from plan Section 7.3, unchanged:

- **A.** macOS CI runner (`macos-latest` GitHub Actions) builds and uploads to
  TestFlight using signing certs from secrets. Recommended, no local Mac needed.
- **B.** Borrowed or rented Mac for the first release, then move to A.
- **C.** Defer iOS entirely. Ship web and Android at parity. Given the $99/year
  membership and the review risk from the app name, this is a legitimate choice.

`app/ios/` is scaffolded and committed so option A can be enabled later without
rework. No `Info.plist` changes have been made and no permissions have been
added, which is correct: the app needs none.

**Action required:** pick A, B or C and record the decision with a date in
`decisions.md`. This is the cheapest open item on the whole board and it is
blocking a gate.
