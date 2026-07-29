# Deviation register

Deliberate divergences from shipped React behavior. Every entry here is a
correctness fix, not a change to copy, layout, or numbers. Source of truth for
policy: `.hermes/plans/2026-07-28_164551-flutter-migration-parity-plan.md`
Section 1.

Status legend: `LANDED` (implemented and covered by tests), `PLANNED` (agreed,
not yet built).

| # | Bug | React behavior | Flutter behavior | Where | Status |
|---|---|---|---|---|---|
| D-002 | BUG-002 | Currency setting ignored, everything renders USD | Every money figure routes through one formatter bound to the currency setting | `lib/core/format/currency_formatter.dart` | LANDED (formatter). Wiring to settings is P2+ |
| D-004 | BUG-004 | Any parseable JSON is imported, bad shapes brick the app | Import is strictly validated and throws on a bad shape, leaving existing state intact. Individual malformed break rows are dropped rather than failing the whole file | `lib/domain/models/app_state.dart`, `lib/data/app_repository.dart` | LANDED |
| D-005 | BUG-005 | Category colors keyed by strings that do not match the stored category values, so three of five doughnut wedges render gray | One `BreakCategory` enum owns wire value, label, emoji and color | `lib/domain/models/break_category.dart` | LANDED |
| D-007 | BUG-007 | Settings are shallow-merged, so a partial payload drops defaults | Settings parse field by field against defaults | `lib/domain/models/app_settings.dart` | LANDED |
| D-008 | BUG-008 | A running timer is lost on reload or navigation | `runningTimer` is persisted and elapsed time is derived from the wall clock | `lib/domain/models/running_timer.dart` | LANDED (model). Controller is P2+ |
| D-009 | BUG-009 | JPY renders with two decimals, which is invalid | Decimal digits come from `NumberFormat.simpleCurrency` | `lib/core/format/currency_formatter.dart` | LANDED |
| D-010 | BUG-010 | `settings.timezone` is collected and never used | Field is carried and marked `@Deprecated` so existing exports still import cleanly. Still unused | `lib/domain/models/app_settings.dart` | LANDED |
| D-001 | BUG-001 | PWA manifest references icons that do not exist | Every icon the manifest declares is committed and covered by a test that fails if a declared file is missing | `app/web/manifest.json`, `app/web/icons/`, `app/test/web/pwa_config_test.dart` | LANDED, with a caveat: the icons are generated placeholders, not brand-final artwork. See the open items below |
| D-003 | BUG-003 | Light theme is not restored on reload | `ThemeMode` is read from storage at boot | P2 | PLANNED |
| D-006 | BUG-006 | RESET and IMPORT reducer branches are unreachable | Not ported. The repository exposes explicit methods instead | `lib/data/app_repository.dart` | LANDED |

## Additional deviations found during implementation

| # | React behavior | Flutter behavior | Why | Where |
|---|---|---|---|---|
| D-101 | `getBreaksInRange` uses an inclusive upper bound (`t <= end`) against an exclusive end date, so a break timestamped exactly at midnight counts in both the day it ends and the day it starts | Ranges are half-open, `[start, end)` | The inclusive bound is unambiguously a bug, and half-open produces identical totals for every timestamp that is not exactly midnight. Covered by boundary tests | `lib/domain/calculations.dart` |
| D-102 | Comparison emoji live in `Dashboard.jsx`, separate from the priced catalog in `calculations.js`, keyed by name string | Emoji, price and copy live on one `ComparisonItem` | Same class of key-mismatch bug as BUG-005 | `lib/domain/comparisons.dart` |
| D-103 | Flutter v1 state is written under a new storage key `fuckcorpo_state_v1` | The React key `fuckcorpo_data` is never written by Flutter | Keeps React usable and rollback lossless during the parallel period, per plan Section 8.3 | `lib/data/app_repository.dart` |
| D-104 | React and Flutter web read the same browser profile but different keys, so after the first Flutter load the two apps diverge permanently | Accepted. The bridge runs once, guarded by `fuckcorpo_migrated_from_v0`, and never re-reads React data afterwards | The alternative, live-syncing two apps against one key, is far more likely to corrupt data than divergence is to confuse users. Must be stated in the release note | `lib/data/migrations/v0_localstorage_to_v1.dart` |
| D-105 | React's PWA manifest names the app `FuckCorpo — Get Paid to Shit` with an em dash | Flutter's manifest uses `FuckCorpo: Get Paid to Shit` | Punctuation only. No behavioral or layout change | `app/web/manifest.json`, `app/web/index.html` |

## Open items

1. ~~**Fonts are not self-hosted.**~~ **CLOSED.** Playfair Display, Work Sans and
   Roboto Mono are committed under `app/assets/fonts/` and declared in
   `pubspec.yaml`. They are the upstream OFL variable fonts from `google/fonts`
   (single `wght` axis); each weight the theme asks for points at the same file,
   which is how Flutter instantiates a variable axis. Upstream no longer ships
   `static/` instances for these families, so variable is the only option.
   Provenance and license text: `app/assets/fonts/README.md`, refreshed by
   `app/tool/fetch_fonts.sh`. Self-hosting also removes the runtime dependency on
   fonts.googleapis.com that the React build had, so typography now survives
   offline. Verified in `build/web/assets/FontManifest.json` and guarded by
   `app/test/core/theme/fonts_test.dart`.
2. ~~**PWA icons are placeholders.**~~ **CLOSED for generated assets.**
   `app/web/icons/*`, `app/web/favicon.png`, `app/web/icons/apple-touch-icon.png`,
   and `app/web/social/og-card.png` are generated brand assets, not flat placeholder
   fills: navy field, green money-mark, subtle earnings-line motif, maskable safe
   zones, and a dedicated 1200x630 Open Graph/Twitter card. `index.html` now points
   `og:image` and `twitter:image` at `social/og-card.png` and declares the 1200x630
   dimensions. Guarded by `app/test/web/brand_assets_test.dart` plus
   `app/test/web/pwa_config_test.dart`. Final human brand approval is still needed
   before public launch, but the repo no longer lacks real generated assets.
3. **A failed v0 migration is no longer silent, but recovery is still manual.**
   The bridge writes `fuckcorpo_v0_migration_failed` alongside the backup, and
   Settings renders a dismissible Import Notice card that says the old data was
   found, could not be read, was not deleted, and names the
   `fuckcorpo_data_backup` key. Deliberately kept to a persisted flag plus a card
   rather than threading `V0MigrationResult` through boot: the notice has to
   survive the reloads a confused user will try first, and nothing about the
   bridge or the render path had to change.
   **Remaining TODO:** the plan Section 8.3 offer to *export* that raw JSON with
   one tap is not built. Doing it properly means reading the backup out of
   `localStorage` through `LegacyStore` (web-only, and `LegacyStore` is currently
   only reachable from `main.dart`, not from a provider) and routing it to the
   same clipboard path as Export Data. That is a small provider addition, not an
   architecture change, but it is a separate task. Until then recovery is a
   devtools copy of the key, which the notice states explicitly.
4. ~~**No copy explains that web and mobile do not sync.**~~ **CLOSED.**
   Settings > Data Management now opens with `SettingsScreen.syncNoticeText`,
   which states the data is stored on this device only, that the website and the
   app each keep their own copy, that browsers keep a copy per profile, that
   clearing browser data erases the web copy, and that Export/Import is the way
   to move it. This is the user-facing statement of D-104. Covered by
   `test/features/settings/settings_screen_test.dart`, group `N4`.
