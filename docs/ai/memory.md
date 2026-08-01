# Project Memory

Last updated: 2026-07-28 | commit 34e0f62 | branch `zali-init`

Project history and current state. Written for AI-assisted sessions. Facts only; no aspiration.

---

## What this project is

**FuckCorpo** is a satirical PWA that calculates money earned during bathroom breaks at work. Corporate/Wall Street visual language, subverted, pro-worker. Client-only, no backend, no accounts, no analytics.

---

## Current state in one paragraph

The repo contains **two implementations**. The React 19 + Vite 7 SPA in `src/` is now **deprecated/frozen** and retained for rollback plus real-profile migration verification. The Flutter app in `app/` is the **forward implementation** and has reached complete local MVP parity with green analyze, 269 tests, web build, and an Android release-mode emulator run. Public cutover/release gates are still open.

---

## Timeline

| When | What |
|---|---|
| 2026-02-05 | Two commits, single author, ~3.5 minutes apart. `18a7224` first commit, `34e0f62` readme. React app complete at this point. |
| 2026-02-05 → 2026-07-28 | Dormant, ~5.7 months, no upstream activity. |
| 2026-07-28 | Repo cloned/opened. Code map generated. Full codebase audit run against React (`docs/audit/`, 20 findings F-001…F-020, 11 bugs). |
| 2026-07-28 | Flutter migration planned and executed to local MVP parity. Migration docs written (`docs/migration/`). Brand assets generated, fonts self-hosted, v0 storage bridge built. |
| 2026-07-28 | Documentation refresh across code map, audit, migration, and this `docs/ai/` set. |

Everything after the dormancy is still **uncommitted working-tree state**. `app/`, `docs/`, `.hermes/`, and the root index docs are all untracked.

---

## Key decisions already made

See `decisions.md` for the full records. Summary:

1. **Flutter, not React Native or a React rewrite**, for the mobile target.
2. **React is not deleted at cutover.** It is tagged `react-final` and archived to `legacy/react/` after 30 days.
3. **Storage is versioned going forward.** v1 schema at key `fuckcorpo_state_v1`; React's `fuckcorpo_data` is read-only forever.
4. **Fonts are self-hosted**, dropping the Google Fonts CDN call that contradicted the "no tracking" claim.
5. **Export/import is clipboard-based**, not file-picker-based, in the Flutter app.
6. **Brand assets are generated deterministically** from design tokens by a committed script, not hand-drawn placeholders.

---

## What the Flutter port fixed

Of the 11 audit bugs found in React, the Flutter app resolves 10 by construction:

* BUG-001 PWA icons missing → real generated icons, test-guarded
* BUG-002 / BUG-009 currency setting inert → single `currency_formatter.dart` seam
* BUG-003 light theme not restored → `ThemeMode` read from storage at boot
* BUG-004 / BUG-007 unvalidated import → validating `importJson`, throws rather than corrupting
* BUG-005 category colour drift → `BreakCategory` enum owns label, emoji, colour
* BUG-006 dead reducer branches → not ported
* BUG-008 running timer lost on reload → `RunningTimer.startedAt` persisted, elapsed derived from wall clock
* BUG-010 dead `timezone` setting → `@Deprecated`, retained only for import compatibility
* BUG-011 onboarding re-renders → not reproduced in the Flutter wizard

BUG-001 and the React-only items (F-001 router advisories, F-010 lint failures, F-011 build-chain advisories, F-015 bundle size) remain open **for React**, which is deprecated/frozen rather than the forward implementation.

---

## What is still open

Release/cutover only. No local MVP feature work is outstanding.

* **No staging deployment.** The `fuckcorpo-flutter` Vercel project has never been created.
* **Migration never verified against a real pre-existing user profile.** Only synthetic fixtures.
* **Android release build is unsigned.** No keystore, no `key.properties`, nothing on an internal track.
* **iOS has never been built.** Windows host cannot produce an IPA. Needs TestFlight or a written defer decision.
* **No CI.** No `.github/` directory for either app.
* **Test coverage never measured** (269 tests pass, but the ≥90% target is unverified).
* **Final human brand approval** on the generated assets.
* **Written owner go/no-go** referencing `docs/migration/cutover_plan.md`.

---

## Traps and gotchas

* `shared_preferences` namespaces web keys under `flutter.`. That is why `legacy_store_web.dart` exists to read React's unprefixed keys.
* `AppSettings.region` serializes under the JSON key `state`, and `timezone` is deprecated-but-retained. Both look like cleanup targets and are not — they preserve v0 import compatibility.
* `app/test/web/` asserts against `manifest.json`, `index.html`, `vercel.json`, and icon byte sizes. Editing those files without running the Flutter suite produces confusing failures.
* `app/vercel.json` has `buildCommand: null`. `build/web` must be produced before deploy.
* The Flutter web first load is roughly 3.7 MB gzipped against React's ~156 kB. This is a real regression and the decision to accept it is still open.
* `app/lib/dev/widget_gallery.dart` is intentionally unreachable dead code, not an oversight.
* `git status` is large and mostly untracked. Do not assume anything in `app/` or `docs/` is committed.

---

## Validation commands

From `app/`:
```
flutter analyze
flutter test --reporter compact --concurrency=1
flutter build web
```
From repo root:
```
npm run build -- --mode production
npm run lint
```

Last full run, 2026-07-28: analyze clean, 269/269 tests pass, both builds succeed. `npm run lint` still fails on the React app (F-010, 5 errors + 1 warning) and is not part of the green set.
