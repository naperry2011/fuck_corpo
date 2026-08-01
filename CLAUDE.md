# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**FuckCorpo** is a satirical app that calculates and tracks money earned during bathroom breaks at work. It uses a "Capitalist Satire" aesthetic: Wall Street / corporate visual language subverted for pro-worker bathroom-break autonomy.

## Current Implementation Status

The repository contains two implementations:

| Implementation | Location | Status |
|---|---|---|
| Flutter | `app/` | **Forward implementation** for web, Android, and iOS |
| React/Vite | `src/` plus root web files | **Deprecated/frozen legacy implementation** retained for rollback and migration verification |

Do not add new product work to the React app unless the change is explicitly required for rollback safety, migration proof, or an urgent production fix before cutover. See `docs/migration/react_deprecation.md`.

Flutter local MVP parity has been verified, but public cutover is not complete. Release blockers and cutover gates are tracked in `docs/migration/release_readiness.md` and `docs/migration/cutover_plan.md`.

## Important Documents

- `README.md` — current project overview and commands.
- `CODE_MAP.md` — feature-oriented repository map.
- `ENTRY_POINTS.md` — executable entry points.
- `FEATURE_BOUNDARIES.md` — ownership rules, especially React vs Flutter migration boundaries.
- `DATA_FLOW.md` — local-only data movement and v0-to-v1 migration behavior.
- `docs/migration/react_deprecation.md` — React web deprecation rules.
- `docs/migration/cutover_plan.md` — gates before production cutover and archive.
- `docs/migration/release_readiness.md` — verified evidence and remaining blockers.
- `fuckcorpo-design-system.md` — visual design system source of truth.
- `fuckcorpo-features.md` — product feature specification.

## Flutter Commands

Run from `app/`:

```bash
flutter pub get
flutter analyze
flutter test --reporter compact --concurrency=1
flutter build web
```

Android release APK builds locally, but release signing / Play internal track are still open cutover items. iOS cannot be built on this Windows host unless a macOS build path is provided or iOS is formally deferred.

## Legacy React Commands

Run from the repository root only when rollback/reference verification is needed:

```bash
npm ci
npm run build -- --mode production
npm run lint
```

The React app persists unversioned local data under `localStorage` key `fuckcorpo_data`. Flutter's v0 migration bridge may read this key once, but must never write or delete it.

## Brand Voice

Irreverent but not mean-spirited. Pro-worker, anti-exploitation. Uses corporate/financial language satirically, such as "QUARTERLY EARNINGS REPORT" and fake ticker symbols like `$POOP`. Copy should sound like an official corporate document that has been subverted.
