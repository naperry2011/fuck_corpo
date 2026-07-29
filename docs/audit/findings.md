# Findings Register

Analysis date: 2026-07-28. Repository: `C:\Users\Ziggy\Dropbox\GitHub\fuck_corpo`.

Verification labels: **VERIFIED** (reproduced or directly observed), **STATIC-ONLY** (read in code, not executed), **HYPOTHESIS** (needs follow-up).

## Severity tally

| Severity | Count |
|---|---|
| Critical | 0 |
| High | 4 |
| Medium | 9 |
| Low | 7 |
| **Total** | **20** |

## Index

| ID | Title | Dimension | Severity | Verification |
|---|---|---|---|---|
| F-001 | Runtime router dependency carries high-severity advisories | Security & Compliance | High | VERIFIED |
| F-002 | PWA install criteria not met; manifest icons absent | Operational Readiness | High | VERIFIED |
| F-003 | Currency setting has no effect on displayed earnings | Bugs & Stability | High | STATIC-ONLY |
| F-004 | No test suite and no CI pipeline | Operational Readiness | High | VERIFIED |
| F-005 | Theme preference not restored on load | Bugs & Stability | Medium | STATIC-ONLY |
| F-006 | Category enum duplicated and drifted between modules | Design & Abstraction | Medium | STATIC-ONLY |
| F-007 | Persisted and imported state is unvalidated | Security & Compliance | Medium | STATIC-ONLY |
| F-008 | Dead and incorrect reducer branches | Code Quality | Medium | STATIC-ONLY |
| F-009 | Currency formatting has no seam; every call site must remember | Design & Abstraction | Medium | STATIC-ONLY |
| F-010 | Lint fails on the default configuration | Code Quality | Medium | VERIFIED |
| F-011 | Build toolchain carries 14 high-severity advisories | Security & Compliance | Medium | VERIFIED |
| F-012 | In-progress timer state is not durable | Bugs & Stability | Medium | STATIC-ONLY |
| F-013 | Income and location data stored and exported in the clear | Security & Compliance | Medium | STATIC-ONLY |
| F-014 | No error boundary; any persisted-state defect is unrecoverable | Operational Readiness | Medium | STATIC-ONLY |
| F-015 | Single 475 kB bundle with no code splitting | Code Quality | Low | VERIFIED |
| F-016 | Git hygiene: two commits, no convention, `.env` unignored | Git Hygiene | Low | VERIFIED |
| F-017 | Currency and locale formatting is US-only | Bugs & Stability | Low | STATIC-ONLY |
| F-018 | Dead configuration: `settings.timezone` | Code Quality | Low | STATIC-ONLY |
| F-019 | Manifest drift: `vite-plugin-pwa` misplaced, no `engines` | Code Quality | Low | VERIFIED |
| F-020 | Documentation drift between index files and code | Code Quality | Low | VERIFIED |

---

## F-001: Runtime router dependency carries high-severity advisories (High / Security & Compliance)

**Verification:** VERIFIED. `npm audit` exit 1.

**Evidence:** `package.json:18` pins `react-router-dom` at `^7.13.0`. `npm audit` reports the transitive `react-router` package in the vulnerable range `6.0.0 - 8.2.0` with 12 advisories. The ones that apply to a client-only SPA are open redirect via backslash in `<Link>` and `useNavigate` (GHSA-wrjc-x8rr-h8h6), open redirect via protocol-relative `//` paths (GHSA-2j2x-hqr9-3h42), and unauthenticated denial of service via inefficient route matching (GHSA-chx6-hx7r-mcp5). The SSR, RSC, and single-fetch advisories in the same cluster do not apply to this deployment shape.

**Impact:** This is the only advisory cluster in code that ships to the browser. Practical exposure today is limited because the application has four static routes, takes no user-controlled navigation targets, and holds no session or credential worth redirecting away. The finding is High on the dependency itself rather than on demonstrated exploitability in this app: the fix is a version bump with no code change, and leaving a known-vulnerable runtime dependency in place is not defensible once the product adds the accounts and leaderboard features the specification calls for.

**Recommendation:**
1. Upgrade `react-router-dom` past 7.14.1.
2. Re-run `npm run build` and exercise all four routes.
3. Add `npm audit --audit-level=high` to CI once the pipeline exists (F-004).

---

## F-002: PWA install criteria not met; manifest icons absent (High / Operational Readiness)

**Verification:** VERIFIED. `npm run build` exit 0 and the manifest was emitted; directory listing confirms the referenced files do not exist.

**Evidence:** `vite.config.js:22-24` and `vite.config.js:10` reference `/icon-192.png`, `/icon-512.png`, and `apple-touch-icon.png`. `index.html:9` links the apple touch icon. `public/` contains only `favicon.svg` and `vite.svg`.

**Impact:** The product is specified as an installable, mobile-first PWA. That is the primary distribution mechanism, and it does not work. The build emits the manifest with no warning, so the failure is silent and would ship to production unnoticed. Cross-referenced as BUG-001.

**Recommendation:**
1. Produce the three PNG assets from the existing brand mark on the Corporate Navy `#0a1128` background.
2. Add a Lighthouse PWA assertion to CI so missing manifest assets fail the build.

---

## F-003: Currency setting has no effect on displayed earnings (High / Bugs & Stability)

**Verification:** STATIC-ONLY.

**Evidence:** `src/utils/calculations.js:33` defaults the currency parameter to `'USD'`. Twelve of fourteen call sites omit the argument, including every user-facing earnings display: `src/pages/Timer.jsx:85, 108, 150, 240, 260`; `src/pages/Achievements.jsx:76, 145, 185, 193`; `src/components/layout/Ticker.jsx:14, 16, 18`; `src/pages/Dashboard.jsx:215, 228`. `Dashboard.jsx:325` and `:330` render `AnimatedCurrency` without a `currency` prop.

**Impact:** Settings offers six currencies. Selecting any of them changes exactly one label on the settings screen and nothing else. For a product whose sole output is a money figure, every non-USD user sees incorrect values throughout the application. Cross-referenced as BUG-002.

**Recommendation:** See F-009 for the structural fix. The tactical fix is to expose `currency` from `AppContext` alongside `perMinuteRate` and thread it through, with a unit test asserting non-USD output.

---

## F-004: No test suite and no CI pipeline (High / Operational Readiness)

**Verification:** VERIFIED. No `test` script in `package.json`, no test runner in the dependency tree, zero `*.test.*` or `*.spec.*` files under `src/`, no `.github/` directory.

**Evidence:** `package.json:6-11` defines `dev`, `build`, `lint`, `preview` only.

**Impact:** The product's core is an arithmetic pipeline: salary to per-minute rate, duration to earnings, breaks to date-bucketed aggregates. None of it is tested. Six of the eleven defects in `bugs.md` are the kind a single unit test or a smoke render would have caught before commit, and three of them (BUG-002, BUG-003, BUG-005) are silent wrong-output bugs rather than crashes, which is precisely the class that ships undetected without tests. Separately, nothing runs lint or build automatically, so the repository is currently in a state where `npm run lint` fails on `main` and no signal exists to say so.

**Recommendation:**
1. Add Vitest and `@testing-library/react` with a `test` script.
2. Cover `src/utils/calculations.js` first: rate conversion for all four salary types, earnings math, the four date-range selectors around boundaries, and `formatCurrency` with a non-USD currency.
3. Add a smoke test that renders each route with a seeded state.
4. Add a GitHub Actions workflow running `npm ci`, `npm run lint`, `npm run build`, `npm test` on push and pull request.

---

## F-005: Theme preference not restored on load (Medium / Bugs & Stability)

**Verification:** STATIC-ONLY.

**Evidence:** `src/pages/Settings.jsx:78` is the only writer of the `data-theme` attribute. `index.html:2` hardcodes `data-theme="dark"`. No code reads `state.settings.theme` at boot.

**Impact:** Light mode is persisted but never reapplied, so it silently reverts on every reload while the settings toggle continues to report Light. The stored preference and the rendered UI disagree. Cross-referenced as BUG-003.

**Recommendation:** Apply the theme from an effect in `AppProvider` and make that the single owner of the attribute.

---

## F-006: Category enum duplicated and drifted between modules (Medium / Design & Abstraction)

**Verification:** STATIC-ONLY.

**Evidence:** `src/pages/Timer.jsx:20-26` defines the authoritative category values with emoji. `src/pages/Dashboard.jsx:59-65` defines a parallel colour map keyed on three strings that do not exist in the writer (`Smoke`, `Mental Health`, `Coffee` versus `Smoke Break`, `Mental Health Moment`, `Coffee Break`). `src/pages/Dashboard.jsx:49-57` holds a third parallel map for comparison emoji, keyed on strings owned by `src/utils/calculations.js:103-111`.

**Impact:** This is a missing seam rather than a typo. The category concept has three attributes (label, emoji, colour) spread across three files with no single owner, and two of the three consumers key on the writer's values by convention rather than by import. The drift has already happened once and produced a visible defect (BUG-005). Any future category addition requires touching three files, and nothing fails if one is missed.

**Recommendation:** Extract a single `CATEGORIES` constant in `src/utils/` carrying `{ value, label, emoji, color }`, import it in `Timer.jsx` and `Dashboard.jsx`, and derive the colour map from it. Do the same for the comparison items so the emoji map lives beside the price list it keys on.

---

## F-007: Persisted and imported state is unvalidated (Medium / Security & Compliance)

**Verification:** STATIC-ONLY.

**Evidence:** `src/utils/storage.js:47-55`. `importData` guards only against a `JSON.parse` throw, then shallow-merges arbitrary JSON over defaults and persists it. `src/utils/storage.js:22` applies the same unvalidated shallow merge to whatever is already in localStorage. `src/pages/Settings.jsx:106` reloads the page immediately after.

**Impact:** The import path is the only channel through which external data enters the system, and it accepts anything syntactically valid. A malformed payload (for example `{"breaks": "x"}`) is persisted and then crashes every subsequent render, with no in-app recovery. The shallow merge separately means a partial `settings` object erases sibling defaults. This is not a remote attack surface, since the file is user-selected, but it is a durable self-inflicted denial of service. Cross-referenced as BUG-004 and BUG-007.

**Recommendation:**
1. Validate shape and types before persisting; reject and surface the existing error state otherwise.
2. Add a `schemaVersion` field to the export payload and a single normalisation function applied on every load.
3. Deep-merge `settings` rather than replacing it.
4. Pair with F-014 so no persisted value can produce an unrecoverable blank screen.

---

## F-008: Dead and incorrect reducer branches (Medium / Code Quality)

**Verification:** STATIC-ONLY.

**Evidence:** `src/context/AppContext.jsx:30-34`. Neither `IMPORT_DATA` nor `RESET` is dispatched anywhere in `src/`. Both call `loadData()`, which reads localStorage rather than returning defaults, so `RESET` would return the current persisted state. Combined with the persist-on-every-change effect at `AppContext.jsx:45-47`, a `RESET` dispatch would be a no-op. `src/pages/Settings.jsx:115-122` and `:102-106` bypass the reducer entirely with `window.location.reload()`.

**Impact:** Two of eight reducer actions are unreachable and would misbehave if wired up. The documented data-management flows work only because they force a full page reload, a heavier mechanism that discards UI state and produces a visible flash. This is a trap for the next contributor, who will reasonably assume the reducer actions are the supported path. Cross-referenced as BUG-006.

**Recommendation:** Export `defaultData` from `storage.js`, fix both branches to use it, route Settings through dispatch, and remove the reloads. Alternatively delete both branches. Do not leave them as-is.

---

## F-009: Currency formatting has no seam; every call site must remember (Medium / Design & Abstraction)

**Verification:** STATIC-ONLY.

**Evidence:** `src/utils/calculations.js:33` signature is `formatCurrency(amount, currency = 'USD')`. The default makes the correct call and the incorrect call syntactically identical, so omitting the second argument is silent and produces plausible-looking output. Fourteen call sites across five modules; twelve are wrong.

**Impact:** This is the design cause of F-003, and it is worth recording separately because fixing the twelve call sites without fixing the shape leaves the same trap for call site fifteen. The currency lives in `AppContext`, every consumer of `formatCurrency` is already inside a component with context access, and yet the formatter is a bare module function that knows nothing about the store. The abstraction in use is a stateless utility; the coupling the call sites demonstrate is that every one of them needs a store-derived value. Those do not match.

**Recommendation:**
1. Remove the default from `formatCurrency` so an omitted currency is a lint or type error rather than a silent USD.
2. Add a `useMoney()` hook in `src/hooks/` that reads `state.settings.currency` and returns a bound formatter. Have components call that.
3. Keep the bare `formatCurrency` for the Chart.js tick callbacks, which run outside React, and pass the currency explicitly there.

---

## F-010: Lint fails on the default configuration (Medium / Code Quality)

**Verification:** VERIFIED. `npm run lint` exit 1. Five errors, one warning.

**Evidence:**

| Rule | Count | Location |
|---|---|---|
| `react-hooks/set-state-in-effect` | 1 | `src/components/Application.jsx:83` (also 84, 85) |
| `react-refresh/only-export-components` | 2 | `src/context/AppContext.jsx:57`, `src/context/ToastContext.jsx:34` |
| `no-unused-vars` | 2 | `src/pages/Achievements.jsx:5`, `src/pages/Dashboard.jsx:14` (`calculateEarnings` imported unused) |
| `react-hooks/exhaustive-deps` (warning) | 1 | `src/pages/Timer.jsx:70` (missing dep `elapsed`) |

**Impact:** The repository ships in a state where its own configured lint command fails. The two unused imports and the two Fast Refresh warnings are hygiene. `set-state-in-effect` at `Application.jsx:83` has real render cost on the first screen a new user sees. The `exhaustive-deps` warning at `Timer.jsx:70` is intentional (adding `elapsed` would restart the interval every tick) but is unannotated, so a future contributor cannot distinguish deliberate from accidental.

**Recommendation:**
1. Delete the two unused imports.
2. Move the `Application.jsx` state initialisation out of the effect body.
3. Add an explicit `// eslint-disable-next-line react-hooks/exhaustive-deps` with a one-line rationale at `Timer.jsx:70`.
4. Move `useApp` and `useToast` to separate files, or accept the Fast Refresh warnings and disable that rule for `src/context/`.
5. Gate lint in CI so this cannot regress (F-004).

---

## F-011: Build toolchain carries 14 high-severity advisories (Medium / Security & Compliance)

**Verification:** VERIFIED. `npm audit` exit 1: 19 vulnerabilities, 14 high, 3 moderate, 2 low.

**Evidence:** Affected build-time packages include `vite`, `rollup`, `postcss`, `serialize-javascript` (via `@rollup/plugin-terser` and `workbox-build`), `lodash`, `minimatch`, `picomatch`, `brace-expansion`, `js-yaml`, `flatted`, `fast-uri`, `@babel/plugin-transform-modules-systemjs`, `@babel/core`, `esbuild`, `ajv`. Full breakdown in `dependencies.md` section 5.

**Impact:** These execute at build time on developer machines and in CI, not in the browser, so end-user exposure is nil. The material subset is the `vite` cluster: dev-server path traversal, arbitrary file read via WebSocket, `server.fs.deny` bypass on Windows alternate paths, and NTLMv2 hash disclosure through `launch-editor` UNC handling. On a Windows development host that is a real local risk if the dev server is ever bound beyond loopback or the developer opens an untrusted page while it runs. Rated Medium rather than High on that basis.

**Recommendation:**
1. Run `npm audit fix`; all 19 report an available fix.
2. Re-run build and lint to confirm nothing regressed.
3. Keep the Vite dev server on loopback only.
4. Add `npm audit --audit-level=high` to CI.

---

## F-012: In-progress timer state is not durable (Medium / Bugs & Stability)

**Verification:** STATIC-ONLY.

**Evidence:** `src/pages/Timer.jsx:49-52` holds `running`, `elapsed`, and `startTimeRef` in component-local state. Nothing persists until `ADD_BREAK` fires on stop (`Timer.jsx:84`). Route changes unmount the component.

**Impact:** The live timer is the product's primary interaction and its premise is that the user has physically left their desk. Navigating to another tab in the app, reloading, or having the OS reclaim a backgrounded mobile PWA discards the in-progress break silently. Additionally `Timer.jsx:76` drops any break under one second with no feedback, so a mis-tap disappears without explanation. Cross-referenced as BUG-008.

**Recommendation:** Persist `{ running, startedAt, category }` on start, clear on stop, and rehydrate elapsed from `Date.now() - startedAt` on mount. This also removes the wall-clock drift inherent in the current interval approach.

---

## F-013: Income and location data stored and exported in the clear (Medium / Security & Compliance)

**Verification:** STATIC-ONLY.

**Evidence:**
- `src/utils/storage.js:3-16` persists `salary.amount`, `settings.industry`, `settings.state`, and `settings.timezone` to `localStorage` under key `fuckcorpo_data`, unencrypted.
- `src/utils/storage.js:36-45` exports the same payload to a plaintext JSON file.
- `README.md:46` claims "100% Private. All data stays in localStorage. No accounts, no tracking, no analytics."
- `src/index.css:2` loads webfonts from `fonts.googleapis.com`; `vite.config.js:31-38` adds runtime caching for `fonts.googleapis.com` and `fonts.gstatic.com`.

**Impact:** Two distinct issues.

First, the combination of salary, industry, state or region, and timezone is a re-identifiable profile in a small population, held in a storage medium accessible to any script running on the origin and to anyone with physical access to an unlocked device. The threat model for a satirical local-first app is genuinely low, and localStorage is a defensible choice, but the export file is the sharper edge: users are invited to download and move a plaintext file containing their salary.

Second, the "no tracking" claim is not strictly accurate. Every page load issues requests to Google's font CDN, disclosing IP address and user agent to a third party. German courts have found self-hosting obligations under GDPR on exactly this pattern. For a product positioned on privacy and worker autonomy, this is a credibility gap as much as a compliance one.

**Recommendation:**
1. Self-host the three webfonts. This removes the third-party request, makes the "no tracking" claim true, removes the two runtime-caching rules, and improves offline fidelity.
2. Add a short in-app privacy note stating plainly what is stored, where, and that the export file is unencrypted plaintext.
3. Consider omitting `settings.state` and `settings.timezone` from the export payload, since neither is currently used (see F-018).

---

## F-014: No error boundary; any persisted-state defect is unrecoverable (Medium / Operational Readiness)

**Verification:** STATIC-ONLY.

**Evidence:** `src/main.jsx:9-19` renders `StrictMode > BrowserRouter > AppProvider > ToastProvider > App` with no error boundary at any level. `src/context/AppContext.jsx:7` calls `loadData()` at module scope, so a throw during load happens before React can catch anything.

**Impact:** Because state is rehydrated from localStorage on every boot, any defect that writes a bad value produces a permanent white screen rather than a transient error. F-007 provides a concrete path to that state. There is no in-app escape hatch: the user must clear site data through browser settings, which most will not do. Combined with the absence of crash reporting (`dependencies.md` section 8), such failures are both unrecoverable and invisible to the maintainer.

**Recommendation:**
1. Add an error boundary above `App` that renders a fallback offering "export my data" and "clear data and restart", the latter calling `clearData()`.
2. Wrap the module-scope `loadData()` call so a corrupt payload degrades to defaults rather than throwing at import time.
3. Add lightweight error reporting before any public launch.

---

## F-015: Single 475 kB bundle with no code splitting (Low / Code Quality)

**Verification:** VERIFIED. `npm run build` exit 0, 1757 modules, 1.99s.

**Evidence:**

| Artifact | Raw | Gzip |
|---|---|---|
| `dist/assets/index-rG0QUFCB.js` | 474.81 kB | 156.48 kB |
| `dist/assets/index-D92yLCa4.css` | 45.51 kB | 8.08 kB |
| Total precache | 510.89 KiB (8 entries) | ~165 kB |

**Impact:** One monolithic chunk despite React Router being present and four clearly separable routes. Chart.js and the icon set are pulled into the initial payload even though charts appear only on Dashboard. At 474.81 kB the bundle sits just under Vite's 500 kB warning threshold, so the next feature will start emitting warnings. For a mobile-first PWA on cellular this is the difference between a fast first paint and a slow one, though the service worker precache mitigates repeat visits.

**Recommendation:** Lazy-load the four route components with `React.lazy` and `Suspense`. Chart.js moving out of the initial chunk is the single biggest win. Consider `rollup-plugin-visualizer` to confirm composition.

---

## F-016: Git hygiene: two commits, no convention, `.env` unignored (Low / Git Hygiene)

**Verification:** VERIFIED. See `git_analysis.md`.

**Evidence:** Two commits, messages `first commit` and `read me file`, authored 3 minutes 37 seconds apart. Zero tags, zero merges, no branch protection observed. `.gitignore` is the stock Vite template with no `.env` or `.env.*` rule and no rule for tool output, leaving five untracked artifacts in `git status`.

**Impact:** The history carries no information about how the code evolved, so there is nothing to bisect and nothing useful to blame. This costs nothing today at 4,600 lines and one contributor; it compounds quickly with a second. The missing `.env` rule is preventive: no such file exists and the app reads no environment variables, but a future backend integration would make an accidental commit trivially easy.

**Recommendation:**
1. Add `.env`, `.env.*`, `!.env.example`, `.hermes/`, and `coverage/` to `.gitignore`.
2. Adopt Conventional Commits before the history grows.
3. Enable branch protection on `main` once CI exists.

---

## F-017: Currency and locale formatting is US-only (Low / Bugs & Stability)

**Verification:** STATIC-ONLY.

**Evidence:** `src/utils/calculations.js:34` hardcodes locale `'en-US'` and forces two fraction digits. `src/pages/Settings.jsx:12` offers JPY, a zero-decimal currency. `src/pages/Achievements.jsx:73` and `:138` and `src/pages/Dashboard.jsx:95` also hardcode `'en-US'` for date formatting.

**Impact:** Every user in every region sees US number grouping and US date formats. JPY renders with two decimals, which is invalid. Cosmetic, but on a product whose entire output is a formatted money figure. Cross-referenced as BUG-009.

**Recommendation:** Pass `undefined` as the locale so the browser locale applies, and let `Intl` derive fraction digits from the currency.

---

## F-018: Dead configuration: `settings.timezone` (Low / Code Quality)

**Verification:** STATIC-ONLY.

**Evidence:** `src/utils/storage.js:9` captures the resolved timezone at first load. No read of `settings.timezone` exists anywhere in `src/`. All date logic uses ambient browser local time.

**Impact:** Dead field that is nonetheless persisted and included in the export payload, so it is collected without purpose (see F-013). A user crossing timezones sees day boundaries and the Early Bird / Night Owl achievements shift with no explanation, because the captured value is never applied. Cross-referenced as BUG-010.

**Recommendation:** Either apply it in the date-range selectors or remove it from the schema and the export.

---

## F-019: Manifest drift: `vite-plugin-pwa` misplaced, no `engines` (Low / Code Quality)

**Verification:** VERIFIED.

**Evidence:** `package.json:19` declares `vite-plugin-pwa` under `dependencies`, but it is a build-time plugin never imported by shipped code. No `engines` field and no `.nvmrc`, while Vite 7 requires Node 20.19+ or 22.12+. `@types/react` and `@types/react-dom` are installed with no TypeScript compiler and no `tsconfig.json`.

**Impact:** Minor. Misplaced dependencies inflate a production install and blur the build-time and runtime boundary. The missing `engines` field means a contributor on Node 18 gets a confusing failure rather than a clear one.

**Recommendation:** Move `vite-plugin-pwa` to `devDependencies`, add `"engines": { "node": ">=20.19" }`, and either adopt TypeScript or drop the unused `@types/*`.

---

## F-020: Documentation drift between index files and code (Low / Code Quality)

**Verification:** VERIFIED.

**Evidence:**
- `CODE_MAP.md` under "Settings / Data Portability" states the page "Dispatches `SET_SALARY`, `UPDATE_SETTINGS`, `IMPORT_DATA`, `RESET`." It dispatches only the first two; the other two are dispatched nowhere (F-008).
- `DATA_FLOW.md` under "Data Export / Import" states the flow dispatches `IMPORT_DATA` / `RESET`. It does not; both paths call `window.location.reload()`.
- `ENTRY_POINTS.md` under "Route Entry: Settings" repeats the same claim.
- `CLAUDE.md` describes the repository as being in "Design specification phase (pre-development). No source code, build system, or dependencies exist yet." A complete React application, a build system, and a lockfile all exist.

**Impact:** Low in isolation, but these index files exist specifically so that contributors and tooling can navigate without reading every file. Where they are wrong they actively mislead, and `CLAUDE.md` in particular would give an agent a materially false picture of the repository.

**Recommendation:** Regenerate the four index files against the current tree and update the Current Status section of `CLAUDE.md`. These are the only files in this list that are safe to change without touching application behaviour.

---

## Design & Abstraction summary

Three findings sit in this dimension: F-006 (duplicated category enum), F-009 (formatter with no store seam), and by extension F-008 (a reducer surface that call sites bypass entirely). They share one root cause. The application has a well-formed central store in `AppContext`, but three separate concerns that logically belong to it (currency, category metadata, and reset semantics) are implemented as module-level constants or bare functions outside it, and consumers reach around the store rather than through it. None of these is load-bearing at 4,600 lines. All three become expensive at the point the specification's leaderboard and account-sync features arrive, because that is when a second writer appears and conventions stop holding.

No in-flight plan or design document was found in the repository beyond the two original specifications (`fuckcorpo-design-system.md`, `fuckcorpo-features.md`), which describe intended product scope rather than a proposed abstraction. There is therefore no plan to evaluate for a bundle-versus-adapter mismatch. Those two specifications are assessed against the shipped code in `product_strategy.md`.

---
generated_by: codebase-audit skill v1.1
generated_on: 2026-07-28
project: C:\Users\Ziggy\Dropbox\GitHub\fuck_corpo
project_type: node
verification: full
---
