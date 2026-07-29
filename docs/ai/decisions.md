# Decisions

Last updated: 2026-07-28 | commit 34e0f62

Architectural decision records. Append-only. Do not rewrite a superseded record; add a new one and mark the old one Superseded.

---

## ADR-001: Port to Flutter rather than React Native or a React rewrite

**Date:** 2026-07-28
**Status:** Accepted

**Context.** The product needed a real mobile presence. The React PWA could not be installed at all (missing manifest icons, F-002), so the primary distribution channel was closed. Options were to fix the React PWA only, adopt React Native, or port to Flutter.

**Decision.** Port to Flutter, targeting web, Android, and iOS from one codebase.

**Consequences.**
* One codebase covers three targets, and the port was used as the occasion to fix 10 of 11 audit bugs by construction rather than patching them in React.
* Cost: a full reimplementation, and a large web bundle regression (~3.7 MB gz vs ~156 kB gz).
* The React app is retained as the reference and rollback path rather than deleted.

---

## ADR-002: React is archived, not deleted, at cutover

**Date:** 2026-07-28
**Status:** Accepted, not yet executed

**Context.** Cutover replaces the live app. If the Flutter app misbehaves in production, there must be a path back.

**Decision.** At cutover, tag `react-final`, switch the domain on day 0, keep `src/` in place for 30 days, then move it to `legacy/react/` and update `README.md`, `CLAUDE.md`, and `CODE_MAP.md`.

**Consequences.** Rollback is a domain switch, not a code restore, for the first 30 days. The repo carries two apps during that window, which is why `FEATURE_BOUNDARIES.md` Boundary 0 exists.

---

## ADR-003: Versioned storage schema with a one-way v0 bridge

**Date:** 2026-07-28
**Status:** Accepted

**Context.** React persists an unversioned JSON blob to `localStorage` key `fuckcorpo_data`, shallow-merged on load with no validation. Existing users have data there. The Flutter app must adopt that data without risking it.

**Decision.** Flutter writes a versioned document (`schemaVersion = 1`) to a **new** key, `fuckcorpo_state_v1`. A one-time `V0Migrator` runs before `runApp` and reads the React key. `fuckcorpo_data` is **read-only forever** — never written, never deleted.

**Consequences.**
* Rollback to React is always possible, because React's data is untouched.
* On web the bridge must bypass `shared_preferences` (which namespaces keys under `flutter.`), requiring the conditional-export `LegacyStore`.
* A corrupt v0 payload is preserved to `fuckcorpo_data_backup` and the app boots to defaults with an in-app notice rather than failing.
* Future schema changes require a real migration step, not a code edit.

---

## ADR-004: Self-host fonts

**Date:** 2026-07-28
**Status:** Accepted

**Context.** The React app loads Playfair Display, Work Sans, and Roboto Mono from the Google Fonts CDN, while the README claims "no tracking, no analytics" (F-013). The claim and the behaviour contradicted each other.

**Decision.** Bundle the three variable fonts in `app/assets/fonts/` with their OFL licenses committed. No `google_fonts` package, no runtime fetch. `fonts_test.dart` guards against a family silently unbundling.

**Consequences.** The privacy claim becomes true for Flutter. Bundle size grows modestly. The React app still has the CDN dependency, so the claim remains qualified there until cutover.

---

## ADR-005: Generate brand assets deterministically from design tokens

**Date:** 2026-07-28
**Status:** Accepted, pending human brand approval

**Context.** The React manifest referenced icons that did not exist, blocking PWA installability entirely. An initial Flutter pass used obvious placeholders (navy field, green `$`).

**Decision.** Commit `app/tool/generate_brand_assets.py`, which deterministically renders all PWA icons, favicon, apple-touch-icon, and a 1200×630 OG card from the design tokens. It replaced `generate_placeholder_icons.py`. Icon byte sizes are pinned by `brand_assets_test.dart`.

**Consequences.**
* PWA installability is unblocked and the social preview is real, not a cropped square.
* Assets are reproducible rather than hand-maintained.
* These are **generated**, not designed. Final human brand approval is still an open release gate.
* Android launcher icons were **not** regenerated and remain stock Flutter mipmaps. Web branding is done; native branding is not.

---

## ADR-006: Clipboard-based export/import instead of a file picker

**Date:** 2026-07-28
**Status:** Accepted

**Context.** React exports via a `Blob` download and imports via a file input. Matching that on Flutter across web, Android, and iOS means adding `file_picker` and `share_plus` plus per-platform permission and share-sheet wiring.

**Decision.** Export copies pretty JSON to the clipboard; import reads from the clipboard and validates. No file-picker dependency.

**Consequences.**
* Zero new platform dependencies, and the flow is uniform across all three targets.
* Deviation from React behaviour, recorded in `docs/migration/deviations.md`.
* Awkward for large datasets. A one-tap export of a backed-up failed-migration payload is still TODO.

---

## ADR-007: Import validation fails loudly rather than merging

**Date:** 2026-07-28
**Status:** Accepted

**Context.** React shallow-merges arbitrary imported JSON into state (F-007, BUG-004, BUG-007), so a partial or hostile file can silently drop defaults or corrupt state.

**Decision.** `AppRepository.importJson` validates and throws `FormatException` on bad input. Existing state is left untouched on failure. Separately, `BreakRecord.tryFromJson` drops individual malformed rows on **load** rather than failing the whole document.

**Consequences.** A bad import is a visible error instead of silent corruption, while a single bad stored row cannot brick the app. Two different failure policies, deliberately, because the trust level of the input differs.

---

## ADR-008: Android applicationId is `com.fuckcorpo.fuckcorpo`

**Date:** 2026-07-28
**Status:** Accepted, flagged for reconsideration **before first Play upload**

**Context.** The Flutter scaffold produced `com.fuckcorpo.fuckcorpo`. The migration plan preferred `com.fuckcorpo.app`.

**Decision.** Left as `com.fuckcorpo.fuckcorpo` for now.

**Consequences.** This identifier is **immutable after the first Play Store upload**. If `com.fuckcorpo.app` is wanted, it must change before then. This is the single decision in this file with a hard, irreversible deadline.

---

## ADR-009: React remains authoritative until written cutover approval

**Date:** 2026-07-28
**Status:** Accepted, active

**Context.** The Flutter app reached complete local MVP parity and is green on analyze, 269 tests, web build, and an Android release-mode emulator run. That is easy to mistake for "ready to ship."

**Decision.** Local parity does **not** authorize cutover. React stays live until every gate in `docs/migration/cutover_plan.md` passes, including staging deployment, real-profile migration verification, Android signing and internal track, iOS TestFlight or a written defer decision, final brand approval, and an explicit written go from the repository owner.

**Consequences.** Documentation must state parity and release-readiness as two separate things everywhere. Any doc that implies the Flutter app is shippable because tests pass is wrong and should be corrected.

---

## Pending decisions

| Topic | Question | Blocking |
|---|---|---|
| iOS | TestFlight, or a written defer? A Windows host cannot produce an IPA. | Gate G7. Needs `docs/migration/ios_defer_decision.md`. |
| Web bundle size | Accept ~3.7 MB gz first load, or invest in reduction? | Open, recorded in `qa_browser.md`. |
| Android applicationId | Keep `com.fuckcorpo.fuckcorpo` or switch to `com.fuckcorpo.app`? | **Irreversible after first Play upload.** |
| Store display name | "FuckCorpo" may hit store profanity policy. Fallback name? | Play/App Store submission. |
| CI | Which provider, and does it gate merges? | N2. No `.github/` exists. |
| Privacy policy | Required URL for Play Data Safety. Does not exist. | Play submission. |
