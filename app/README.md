# FuckCorpo Flutter App

This is the forward implementation of FuckCorpo for web, Android, and iOS.

The legacy React/Vite web app at the repository root is deprecated and frozen. Keep it available for migration checks and rollback until the cutover plan says it can be archived.

## Common commands

```bash
flutter pub get
flutter analyze
flutter test --reporter compact --concurrency=1
flutter build web
```

## Entry points

- `lib/main.dart` — bootstraps storage and the React v0 localStorage migration bridge before `runApp`.
- `lib/app.dart` — app root and theme mode.
- `lib/router.dart` — route table and shell.
- `web/index.html` — Flutter web shell.
- `vercel.json` — static Flutter web deploy config for `build/web`.

## Release posture

Local MVP parity is complete, but production cutover still requires the gates in `../docs/migration/cutover_plan.md`.
