# React web deprecation

Date: 2026-07-28
Status: **DEPRECATED / FROZEN, retained for rollback and migration verification**

The non-Flutter React/Vite web app is no longer the forward implementation for FuckCorpo. Product work should target the Flutter app in `app/`.

This is an operational deprecation, not a deletion. The React app remains in the repository so migration and rollback stay safe until the Flutter cutover has completed and the 30-day quiet window in `docs/migration/cutover_plan.md` has passed.

## What is deprecated

The React web implementation consists of:

- `src/`
- root `index.html`
- root `vite.config.js`
- root `package.json` and `package-lock.json`
- `public/`
- React-only build/lint config such as `eslint.config.js`

These files should be treated as legacy unless a change is explicitly needed for rollback safety, migration verification, or a security-critical emergency on the still-accessible React deployment.

## Forward implementation

The active implementation target is the Flutter app under `app/`:

- Web: `app/web/`, built with `flutter build web`
- Android: `app/android/`
- iOS: `app/ios/`
- Product code: `app/lib/`
- Tests: `app/test/`
- Flutter web deploy config: `app/vercel.json`

## Rules during the deprecation window

1. **No new product features in React.** Implement feature work in Flutter.
2. **Do not delete or move React yet.** Keep it available for real-profile migration checks and fast rollback.
3. **Do not write or delete React's `fuckcorpo_data` key from Flutter.** Flutter may read it once through the v0 migration bridge only.
4. **Bug fixes in React require explicit rationale.** Acceptable reasons: rollback safety, migration parity proof, or urgent user-facing production breakage before cutover.
5. **Docs must distinguish deprecation from release readiness.** Flutter is the forward app, but public cutover still depends on the gates in `docs/migration/cutover_plan.md`.

## Remaining gates before archive/removal

React can move to `legacy/react/` only after:

- Flutter web has a staging deployment.
- Hosted route refresh, Lighthouse/PWA install, offline reload, and service-worker update checks pass.
- A genuine pre-existing React browser profile migrates correctly with `fuckcorpo_data` preserved byte-for-byte.
- Android release signing/internal track is completed or consciously deferred for web-only cutover.
- iOS is built/TestFlighted or formally deferred in writing.
- Production web is cut over to Flutter with React kept as a fallback deployment.
- The 30-day quiet rollback window completes.

## Archive target

After the quiet window, archive React in a single explicit commit:

- Tag the final React state as `react-final`.
- Move `src/`, root `index.html`, `vite.config.js`, React package files, `public/`, and React-only config to `legacy/react/`.
- Update root docs so Flutter is described as the only active application.
- Keep enough history and deployment metadata to redeploy React if a late data recovery issue appears.
