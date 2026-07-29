# Codebase Audit: FuckCorpo

Repository: `C:\Users\Ziggy\Dropbox\GitHub\fuck_corpo` | Branch audited: `zali-init` at `34e0f62` | Analysis date: 2026-07-28

Verification labels used throughout: **VERIFIED** (reproduced or directly observed during this audit), **STATIC-ONLY** (read in code, not executed), **HYPOTHESIS** (inference requiring follow-up).

---

## 1. Executive Summary

FuckCorpo is a client-only React 19 single-page application, roughly 4,600 lines of hand-written source, that converts break time into a running earnings figure. There is no backend, no authentication, and no third-party service beyond a webfont CDN. All state lives in one `localStorage` key. Install, build, lint, dependency scan, and full git history were executed as part of this audit; no user flow was driven in a browser.

**The build is in better shape than its two-commit history suggests.** The layering is conventional and clean, there is no god object and no circular dependency, and the Achievements and PWA service-worker work show genuine care. The problems are concentrated at the last mile of otherwise finished features, and in the absence of any automated safety net.

Twenty findings were recorded: zero Critical, four High, nine Medium, seven Low. Eleven of those carry a concrete user-visible failure mode and are tracked separately as bugs.

Four points deserve executive attention:

1. **The product cannot be installed.** It is specified and built as an installable PWA, and the manifest references three icon files that do not exist in `public/`. The build emits the manifest and exits 0 with no warning, so the failure is silent. The primary distribution channel is closed by three missing image assets (F-002, VERIFIED).
2. **The currency setting does not work.** Settings offers six currencies; twelve of fourteen `formatCurrency` call sites omit the argument and fall back to a hardcoded USD default. For a product whose sole output is a money figure, every non-USD user sees wrong values everywhere except one label on the settings screen (F-003, STATIC-ONLY).
3. **Nothing is tested and nothing runs automatically.** There is no test script, no test runner in the dependency tree, no test files, and no CI configuration. `npm run lint` currently exits 1 on the checked-out tree and no signal exists to report that. Six of the eleven bugs are the class a single unit test would have caught, and three of them produce silently wrong output rather than a crash (F-004, F-010, VERIFIED).
4. **One runtime dependency carries known advisories.** `react-router-dom` at `^7.13.0` resolves a `react-router` version in the vulnerable range. Practical exposure in a four-route SPA with no credentials is limited, but the fix is a version bump with no code change (F-001, VERIFIED). The other 14 high-severity advisories are build-chain only and do not reach the browser (F-011).

No incident, compromise, or exposed secret was found. A secret scan across all commits and the working tree returned zero true positives. The `.gitignore` lacks an `.env` rule, which is preventive rather than remedial: no such file exists and the application reads no environment variables.

**Overall posture:** a coherent, well-designed product one focused week away from being honest about what it does. The engineering readiness gaps are survivable at 4,600 lines and one contributor, and become the binding constraint the moment a backend or a second contributor arrives.

---

## 2. Findings by Dimension

### Severity tally

| Severity | Count |
|---|---|
| Critical | 0 |
| High | 4 |
| Medium | 9 |
| Low | 7 |
| **Total** | **20** |

### Security & Compliance (4 findings: 1 High, 3 Medium)

`npm audit` exits 1 with 19 vulnerabilities, 14 high (VERIFIED). Exactly one cluster ships to the browser: `react-router` open-redirect and route-matching denial-of-service advisories reached through `react-router-dom` (F-001). The remaining clusters, including the Vite dev-server path traversal and Windows-specific NTLMv2 disclosure issues, execute only at build time on developer machines (F-011). All 19 report an available fix.

Two data-handling findings sit alongside these. Persisted and imported state is accepted without any schema validation, so a malformed import file is written to `localStorage` and then crashes every subsequent render with no in-app recovery (F-007). Separately, salary, industry, region, and timezone are stored and exported as plaintext, and the README claim of "no tracking" is undercut by the Google Fonts CDN requests issued on every page load (F-013). Self-hosting the three webfonts closes the credibility gap, removes two runtime-caching rules, and improves offline fidelity in one change.

### Operational Readiness (3 findings: 2 High, 1 Medium)

The PWA does not meet browser install criteria (F-002). There is no test suite and no CI pipeline (F-004). There is no error boundary anywhere in the provider tree, and `loadData()` is called at module scope in `AppContext`, so a corrupt persisted payload throws before React can catch it and produces a permanent white screen rather than a transient error (F-014). Combined with the absence of any crash reporting, such failures are both unrecoverable for the user and invisible to the maintainer.

### Bugs & Stability (4 findings: 1 High, 2 Medium, 1 Low)

Currency is ignored throughout (F-003). Light theme is persisted but never reapplied at boot, because `index.html` hardcodes `data-theme="dark"` and no code reads the stored preference, so the settings screen misreports the active theme after every reload (F-005). In-progress timer state is component-local and is discarded silently on navigation, reload, or OS reclamation of a backgrounded mobile tab, which is the exact scenario the product is designed for (F-012). Locale and fraction-digit handling is hardcoded to `en-US` with two decimals, so JPY renders invalidly (F-017).

### Design & Abstraction (2 findings, both Medium)

Category metadata is split across three files with no single owner, and two consumers key on the writer's string values by convention rather than by import. The drift has already occurred and produces three indistinguishable wedges in the dashboard category chart (F-006). `formatCurrency` carries a `'USD'` default that makes the correct call and the incorrect call syntactically identical, which is the design cause of F-003 (F-009).

These share one root cause worth stating plainly: the application has a well-formed central store, but three concerns that belong to it (currency, category metadata, reset semantics) live as module-level constants beside their consumers instead. The store is the nominal source of truth but not the enforced one. None of this is load-bearing today. All of it becomes expensive at the point a second writer exists.

### Code Quality (6 findings: 1 Medium, 5 Low)

Lint fails on the default configuration with five errors and one warning (F-010, VERIFIED). Two reducer actions, `IMPORT_DATA` and `RESET`, are never dispatched and would misbehave if wired up, because both call `loadData()` rather than returning defaults; the UI bypasses them with `window.location.reload()` (F-008). The build produces a single 474.81 kB chunk with no code splitting despite four separable routes and a charting library used on one of them (F-015). Minor items: `settings.timezone` is captured, persisted, exported, and never read (F-018); `vite-plugin-pwa` is declared as a runtime dependency and there is no `engines` field (F-019); and the four index files plus `CLAUDE.md` have drifted from the code, with `CLAUDE.md` still describing the repository as pre-development (F-020).

### Git Hygiene (1 finding, Low)

Two commits, both with non-informative messages, authored 3 minutes 37 seconds apart, followed by 5.7 months of dormancy. Zero tags, zero merges, no branch protection. Structural hygiene is sound: no vendored dependencies, no build output committed, lockfile present and correct. The weaknesses are entirely process-level, and cost nothing today at one contributor (F-016).

---

## 3. Three-Horizon Roadmap

### Horizon 1: Make the existing surface honest (1 to 2 weeks)

No new features. Every item closes a gap between what the UI already promises and what it delivers. This is the cheapest available improvement to perceived quality.

| # | Action | Findings |
|---|---|---|
| 1 | Produce the three PWA icon assets on the Corporate Navy background | F-002 |
| 2 | Thread currency through every display path; remove the `'USD'` default and add a `useMoney()` hook | F-003, F-009 |
| 3 | Persist and rehydrate in-progress timer state | F-012 |
| 4 | Apply the stored theme from `AppProvider`; make it the single owner of `data-theme` | F-005 |
| 5 | Extract a single `CATEGORIES` constant and import it in both consumers | F-006 |
| 6 | Validate imported payloads; add an error boundary with export and reset escape hatches | F-007, F-014 |
| 7 | Upgrade `react-router-dom` past 7.14.1; run `npm audit fix`; re-verify build | F-001, F-011 |
| 8 | Clear the five lint errors; annotate the intentional `exhaustive-deps` suppression | F-010 |
| 9 | Add Vitest, cover `calculations.js` first, add a GitHub Actions workflow running install, lint, build, test, and `npm audit --audit-level=high` | F-004 |
| 10 | Add `.env*` and tool-output rules to `.gitignore`; adopt a commit convention | F-016 |

Item 9 is the one that changes the trajectory rather than the state. Do it before the backend, not after.

### Horizon 2: Close the growth and retention loops (2 to 4 weeks)

No infrastructure required.

1. **Shareable image generation.** The earnings statement card is already designed and rendered; rendering it to canvas with a download and Web Share API path is contained work with disproportionate payoff. This is the closest thing to a free acquisition channel the product has.
2. **Streaks and a daily hook.** The product currently has a strong first session and no second one. Consecutive-day tracking makes "Consistency Champion" mean what its name says.
3. **Per-state labour rights content.** Static, accurate, genuinely useful, and the clearest expression of the stated positioning. It is what earns the app a place on a phone after the joke wears off.
4. **Onboarding trim.** Stop collecting industry, region, and timezone until a feature reads them, or move them behind an optional and honestly-labelled step.
5. **Route-level code splitting and self-hosted fonts.** Moves Chart.js out of the initial payload and makes the privacy claim true. F-015, F-013.

### Horizon 3: The community layer (backend required)

Only after the above, and only if the leaderboards are a real commitment rather than an aspiration.

1. Anonymous, aggregate-only leaderboards by industry and region. Submit bucketed statistics and a hashed device identifier; never store raw salary server-side.
2. Optional account and cross-device sync.
3. Comparative dashboards against industry and region averages.

Sequencing note: the design findings (F-006, F-008, F-009) are cosmetic today precisely because there is one writer. The moment a sync path exists there are two, and conventions stop holding. Fix the store seams in Horizon 1 while they are cheap.

---

## 4. Forward Look

**What changes shape next.** The architecture is a client-only SPA with a single unversioned JSON blob in `localStorage`. Every design decision in the repository is downstream of that, and it is a defensible choice for the current product. The first backend feature invalidates it. At that point the persisted schema needs a version field and a migration path, the store needs to be the enforced source of truth rather than the nominal one, and the unvalidated import path becomes a real trust boundary rather than a self-inflicted risk. Adding `schemaVersion` and a single normalisation function during Horizon 1 costs an afternoon; retrofitting it across an installed user base costs considerably more.

**What compounds if left.** Two things. First, the absence of tests is currently a small tax and becomes a hard ceiling: three of the eleven known bugs produce silently wrong output, which is exactly the class that ships undetected and accumulates. Second, the git history carries no information about how the code evolved, so there is nothing to bisect and nothing useful to blame. Both are near-free to fix now at one contributor and 4,600 lines, and both are materially harder at the point a second person joins.

**What stays cheap.** The layering, the shared component kit, the reducer surface, and the PWA configuration are all sound and will not need rework. Chart.js, `lucide-react`, and the plain-CSS approach are all replaceable in isolation. There is no framework decision in this repository that looks like a trap.

**The open strategic question.** Whether this is a launch candidate, a portfolio piece, or a weekend experiment changes the urgency of every readiness finding above, and it cannot be answered from inside the repository. The two-commit, single-author, five-months-dormant history reads as the third; the completeness and polish of the shipped surface argues for the first. That question is worth answering before Horizon 2 is scoped. Six further owner questions are listed in `product_strategy.md` section 5.

---

## 5. Verification Gaps

This audit was static plus toolchain execution. The following were not performed and are stated as gaps rather than as clean results.

| Gap | Why it matters | How to close |
|---|---|---|
| No browser execution of any user flow | Nine of eleven bugs are STATIC-ONLY. The code paths are unambiguous, but no one has driven the UI to observe the failures | `npm run preview`, then walk onboarding, timer, dashboard, achievements, settings |
| PWA installability not tested live | F-002 is inferred from a directory listing plus the emitted manifest, not from a browser install attempt | Chrome DevTools, Application, Manifest; then a Lighthouse PWA audit |
| Offline behaviour untested | Service worker precache and font runtime caching were never exercised | Load, go offline in DevTools, reload, exercise all four routes |
| Cross-browser and mobile viewport | The specification targets 320px upward and mobile-first | Test at 320, 768, 1024, 1440 in Chrome, Safari, Firefox |
| Accessibility unmeasured | The design specification targets WCAG AAA and nothing mechanically checks it | axe DevTools per route; add `eslint-plugin-jsx-a11y` |
| `npm outdated` not executed | Major-version drift is not enumerated. The audit-fix signal partially substitutes | Run from the repository root |
| Repository size and blob listing | `git count-objects -vH` and the blob pipeline were blocked by the permission layer | Re-run with shell permission granted |
| Secret scan depth | The zero-positive verdict rests on pattern matching, not entropy analysis | Install gitleaks and re-run the full ruleset |
| Force-push history | The reflog is same-day from a fresh clone, so any upstream rewrite before the clone is undetectable. Absence of evidence is not evidence of absence | Inspect the remote's history directly if this matters |
| No usage, analytics, or user research | Every retention and positioning judgement in `product_strategy.md` is inference from code and specifications | Owner input; see `product_strategy.md` section 5 |

---

## 6. Artifact Index

| File | Contents |
|---|---|
| `docs/audit/report.md` | This executive report |
| `docs/audit/findings.md` | Full findings register, F-001 through F-020, with evidence, impact, and recommendations |
| `docs/audit/bugs.md` | Eleven defects with concrete failure modes, repro steps, and cross-references to findings |
| `docs/audit/dependencies.md` | Manifest, scripts, dependency inventory, vulnerability scan, constraint quality, notable absences |
| `docs/audit/architecture_and_implementation.md` | System shape, store schema, data flow, third-party inventory, feature walkthrough, layering assessment, build posture, verification plan |
| `docs/audit/git_analysis.md` | History, contributors, cadence, message quality, branching, `.gitignore` review, hygiene scorecard |
| `docs/audit/product_strategy.md` | Positioning, shipped-versus-specified matrix, strategic gaps, recommended order, future angles, owner questions |

---
generated_by: codebase-audit skill v1.1
generated_on: 2026-07-28
project: C:\Users\Ziggy\Dropbox\GitHub\fuck_corpo
project_type: node
verification: full
---
