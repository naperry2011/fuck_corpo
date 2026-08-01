# P8 Flutter web/PWA/QA handoff

## Scope completed
- Ran Claude Code via `claude-opus-5` using `.hermes/prompts/flutter-migration-p8-web-pwa-qa-claude.md`.
- Claude CLI timed out after 600s and left `.hermes/flutter-migration-p8-web-pwa-qa-result.json` empty, but generated implementation/test/doc artifacts.
- Verified and accepted the generated P8 work with Hermes tool checks.

## Key changes
- Added React v0 localStorage to Flutter v1 migration bridge:
  - `app/lib/data/migrations/v0_localstorage_to_v1.dart`
  - `app/lib/data/storage/legacy_store.dart`
  - `app/lib/data/storage/legacy_store_stub.dart`
  - `app/lib/data/storage/legacy_store_web.dart`
  - `app/test/data/migrations/v0_localstorage_to_v1_test.dart`
  - `app/test/helpers/memory_legacy_store.dart`
- Hardened Flutter web/PWA config:
  - `app/web/index.html`
  - `app/web/manifest.json`
  - `app/web/favicon.png`
  - `app/web/icons/*.png`
  - `app/test/web/pwa_config_test.dart`
- Updated/created migration QA docs:
  - `docs/migration/qa_browser.md`
  - `docs/migration/qa_mobile.md`
  - `docs/migration/parity_matrix.md`
  - `docs/migration/deviations.md`
  - `docs/migration/storage_schema_v1.md`

## Verified behavior
- Migration bridge preserves the React legacy payload and does not destroy it.
- Migration writes a v1 Flutter key only when no v1 data exists.
- Migration marker prevents duplicate re-imports.
- Corrupt/invalid legacy data is backed up/marked and does not brick first run.
- Non-web platforms skip the legacy localStorage bridge cleanly.
- PWA manifest uses FuckCorpo branding, installable settings, and existing icon paths.
- Web index has branded title/description/preview/theme metadata and boot state.
- Vercel config is expected to serve Flutter web output and deep-link rewrites.

## Validation outputs
- `flutter analyze`: exit 0, `No issues found!`
- Focused tests: `flutter test test/data test/core test/router_test.dart --reporter compact --concurrency=1`: exit 0, `All tests passed!`
- Full suite: `flutter test --reporter compact --concurrency=1`: exit 0, `All tests passed!` with 249 passing tests.
- Web build: `flutter build web`: exit 0, `√ Built build\web`.

## Remaining blockers / not yet verified
- Claude CLI result JSON is empty due timeout, so this handoff is based on filesystem and Flutter verification, not Claude's final JSON summary.
- Android emulator/device QA not run in this session.
- iOS/TestFlight QA not run in this Windows session.
- Browser manual QA against a hosted/staged URL not run.
- Final production icons/brand assets may still require design approval even though placeholder/installable icons exist.
- React is now deprecated/frozen, but must not be deleted until cutover gates pass.

## Next cutover/release steps
1. Run local browser smoke on `app/build/web` or a local static server.
2. Stage Flutter web separately from current React production and verify migration on copied browser localStorage.
3. Run Android release build/install QA.
4. Run iOS build/TestFlight QA on macOS.
5. Only after parity, QA, migration, and rollback gates pass: plan P9 cutover and 30-day React archive.
