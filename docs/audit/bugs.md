# Bugs

Defects with a concrete user-visible failure mode. Architectural and process observations live in `findings.md`; cross-references are noted per entry.

Severity legend follows `findings.md`. Verification labels: VERIFIED (observed or reproduced), STATIC-ONLY (read in code, not executed), HYPOTHESIS (needs follow-up).

| ID | Title | Severity | Verification | Cross-ref |
|---|---|---|---|---|
| BUG-001 | PWA install ships with missing icons | High | VERIFIED | F-002 |
| BUG-002 | Currency preference is ignored everywhere except one label | High | STATIC-ONLY | F-003 |
| BUG-003 | Light theme is not restored after reload | Medium | STATIC-ONLY | F-005 |
| BUG-004 | Data import performs no schema validation | Medium | STATIC-ONLY | F-007 |
| BUG-005 | Dashboard category colours never match logged categories | Medium | STATIC-ONLY | F-006 |
| BUG-006 | `RESET` and `IMPORT_DATA` reducer branches are unreachable and incorrect | Medium | STATIC-ONLY | F-008 |
| BUG-007 | Partial persisted settings silently drop defaults | Medium | STATIC-ONLY | F-007 |
| BUG-008 | Running timer is lost on reload or tab close | Medium | STATIC-ONLY | F-012 |
| BUG-009 | Zero-decimal currencies render with two decimals | Low | STATIC-ONLY | F-015 |
| BUG-010 | Timezone setting is captured but never used | Low | STATIC-ONLY | F-016 |
| BUG-011 | Cascading re-renders in the onboarding flow | Low | VERIFIED | F-010 |

---

## BUG-001: PWA install ships with missing icons (High)

**Verification:** VERIFIED. `npm run build` completed with exit 0 and emitted `dist/manifest.webmanifest` referencing all three icons. Directory listing of `public/` confirms only `favicon.svg` and `vite.svg` are present.

**Evidence:**
- `vite.config.js:22-24` declares manifest icons `/icon-192.png` and `/icon-512.png` (the latter twice, once as `maskable`).
- `vite.config.js:10` lists `apple-touch-icon.png` in `includeAssets`.
- `index.html:9` links `<link rel="apple-touch-icon" href="/apple-touch-icon.png" />`.
- `public/` contains `favicon.svg` (248 bytes) and `vite.svg` (1,497 bytes). None of the three referenced PNGs exist.

**Repro steps:**
1. `npm ci`
2. `npm run build`
3. `npm run preview`
4. Open the preview URL in Chrome, open DevTools, Application, Manifest.
5. Icon entries resolve to 404. The install prompt does not qualify.

**Impact:** The product is specified as an installable PWA. It builds and passes with no warning, but the browser install criteria are not met and the home screen icon is broken. This is a silent failure: nothing in the build output flags it.

**Recommendation:**
1. Add `public/icon-192.png`, `public/icon-512.png`, and `public/apple-touch-icon.png` using the Corporate Navy `#0a1128` background from the design system.
2. Add a build-time assertion or a Lighthouse PWA check in CI so a missing manifest asset fails the pipeline rather than shipping quietly.

---

## BUG-002: Currency preference is ignored everywhere except one label (High)

**Verification:** STATIC-ONLY.

**Evidence:** `src/utils/calculations.js:33` defines `formatCurrency(amount, currency = 'USD')`. Of the 14 call sites, only two pass a currency:
- `src/pages/Settings.jsx:168` passes `currency`
- `src/components/shared/AnimatedCurrency.jsx:6` forwards a `currency` prop, but `src/pages/Dashboard.jsx:325` and `:330` render `<AnimatedCurrency>` without one

Every other site falls back to USD: `src/pages/Timer.jsx:85, 108, 150, 240, 260`; `src/pages/Achievements.jsx:76, 145, 185, 193`; `src/pages/Dashboard.jsx:215, 228`; `src/components/layout/Ticker.jsx:14, 16, 18`.

**Repro steps:**
1. Complete onboarding, or open Settings.
2. Set Currency to `EUR` and save the profile.
3. Log a break on the Timer page.

Expected: the toast, live earnings, today summary, ticker, dashboard, and achievements all show euros.
Actual: all of them show dollars. Only the per-minute rate preview inside the Settings salary card shows euros.

**Impact:** The currency selector offers six currencies and functionally changes nothing a user sees during normal use. For a product whose entire value proposition is a money figure, this is a headline correctness defect for every non-USD user.

**Recommendation:**
1. Read `state.settings.currency` from `AppContext` and expose it alongside `perMinuteRate`.
2. Either thread it through every `formatCurrency` call, or preferably remove the parameter and provide a `useCurrencyFormatter()` hook that closes over the setting. See F-009 for the design rationale.
3. Add a unit test asserting that the formatter honours a non-USD setting.

---

## BUG-003: Light theme is not restored after reload (Medium)

**Verification:** STATIC-ONLY.

**Evidence:** `src/pages/Settings.jsx:75-80` sets `document.documentElement.setAttribute('data-theme', next)` and persists the choice to state. `index.html:2` hardcodes `data-theme="dark"` on `<html>`. A grep for `data-theme` across `src/` returns only the Settings write and the CSS selector at `src/index.css:44`. No provider, effect, or bootstrap code reads `state.settings.theme` and reapplies it.

**Repro steps:**
1. Open Settings, toggle Theme to Light. The UI switches correctly.
2. Reload the page.

Expected: the app stays in light mode; the toggle still reads Light.
Actual: the document reverts to dark because `index.html` hardcodes it, while the Settings toggle still reads Light from persisted state. The UI and the stored preference disagree.

**Impact:** A persisted user preference is silently discarded on every reload, and the settings screen then misreports the active theme. Light mode is effectively non-functional.

**Recommendation:** Add an effect in `AppProvider` that applies `state.settings.theme` to `document.documentElement` on mount and on change, and remove the theme write from `Settings.jsx` so there is a single owner of the attribute.

---

## BUG-004: Data import performs no schema validation (Medium)

**Verification:** STATIC-ONLY.

**Evidence:** `src/utils/storage.js:47-55`. `importData` parses the string and shallow-merges over defaults. The only failure mode it guards is a `JSON.parse` throw. Any syntactically valid JSON is accepted and written to localStorage. `src/pages/Settings.jsx:106` then calls `window.location.reload()`.

**Repro steps:**
1. Create a file `evil.json` containing `{"breaks": "not-an-array", "onboarded": true}`.
2. Settings, Import Data, select the file.
3. The import reports success and the page reloads.

Expected: the file is rejected as malformed.
Actual: `state.breaks` is a string. On the next render `src/pages/Timer.jsx:124` calls `[...state.breaks].sort(...)`, `getTodayBreaks` calls `.filter`, and `totalEarnings` calls `.reduce`. The app throws and, because the bad value is already persisted, it throws again on every subsequent load. There is no in-app recovery path short of clearing site data manually.

**Impact:** A malformed or hand-edited import file permanently bricks the application for that user. The import path is the only place untrusted external data enters the system, and it is unvalidated.

**Recommendation:**
1. Validate the parsed object before saving: `breaks` must be an array whose entries have `id`, `duration` (finite number), `timestamp` (parseable), and `category`; `salary.amount` must be a finite number; `achievements` must be an array of strings.
2. Reject and surface the existing error state rather than saving.
3. Add a version field to the exported payload so future schema migrations are possible.
4. Wrap the top-level render in an error boundary that offers a "clear data and restart" action, so no persisted state can produce an unrecoverable blank screen.

---

## BUG-005: Dashboard category colours never match logged categories (Medium)

**Verification:** STATIC-ONLY.

**Evidence:** `src/pages/Dashboard.jsx:59-65` keys `CATEGORY_COLORS` on `Bathroom`, `Smoke`, `Mental Health`, `Coffee`, `Other`. `src/pages/Timer.jsx:20-26` writes the category values `Bathroom`, `Smoke Break`, `Mental Health Moment`, `Coffee Break`, `Other`. Three of the five keys can never match. `Dashboard.jsx:276` falls back to `'#778da9'` (Cool Gray).

**Repro steps:**
1. Log one break in each of the five categories.
2. Open Dashboard, Category Breakdown.

Expected: five distinct brand colours per the design system.
Actual: Bathroom is green, Other is gray, and Smoke Break, Mental Health Moment, and Coffee Break are all the same gray. Three of five wedges are visually indistinguishable.

**Impact:** The primary category chart is unreadable for the majority of categories, on the screen the product presents as its "quarterly earnings report" centrepiece.

**Recommendation:** Extract the category list, including label, emoji, and colour, into a single exported constant in `src/utils/` and import it in both `Timer.jsx` and `Dashboard.jsx`. This class of drift recurs whenever two modules hold parallel copies of a domain enum. See F-020.

---

## BUG-006: `RESET` and `IMPORT_DATA` reducer branches are unreachable and incorrect (Medium)

**Verification:** STATIC-ONLY.

**Evidence:**
- `src/context/AppContext.jsx:30-34`. `IMPORT_DATA` returns `{ ...loadData(), ...action.payload }`; `RESET` returns `loadData()`.
- A grep across `src/` finds these two action types only at their definitions. Nothing dispatches either one.
- `src/pages/Settings.jsx:115-122` implements Clear All Data as `clearData()` followed by `window.location.reload()`, bypassing the reducer entirely.
- `src/pages/Settings.jsx:102-106` implements import as `importData(...)` followed by `window.location.reload()`, likewise.

Beyond being dead, both branches are wrong. `loadData()` reads localStorage, so `RESET` would return whatever is currently persisted rather than the defaults. And because `AppProvider` persists on every state change (`AppContext.jsx:45-47`), a `RESET` dispatch would immediately re-save the unchanged state. `RESET` as written is a no-op.

**Impact:** Two of eight reducer actions are dead code that would misbehave if wired up. Both documented data-management flows work only because they perform a full page reload, which is a heavier and less predictable mechanism than a state transition. The reload also discards any unsaved UI state and produces a visible flash.

**Recommendation:** Either delete both branches, or fix them to return `defaultData` (exported from `storage.js`) and route Settings through them so the reload is no longer required. Do not leave them as-is; they are a trap for the next contributor.

---

## BUG-007: Partial persisted settings silently drop defaults (Medium)

**Verification:** STATIC-ONLY.

**Evidence:** `src/utils/storage.js:22` returns `{ ...defaultData, ...JSON.parse(raw) }`. The spread is shallow, so a persisted payload containing a `settings` key replaces the entire default `settings` object rather than merging into it. `importData` at line 50 has the same shape.

**Repro steps:**
1. Import an export produced by an earlier build, or hand-write `{"settings": {"currency": "EUR"}}`.
2. Reload.

Expected: currency changes to EUR, other settings keep their defaults.
Actual: `settings.soundEnabled`, `settings.theme`, and `settings.timezone` become `undefined`. `useSound` at `src/hooks/useSound.js:33` checks `=== false`, so undefined reads as enabled, which is tolerable. `theme` undefined falls through the `|| 'dark'` guard in Settings, also tolerable. But the pattern is fragile: any future setting whose default is truthy or whose absence is meaningful will break silently.

**Impact:** Forward and backward compatibility of the persisted schema is not handled. Today the consequences are absorbed by defensive `||` and `!== false` guards scattered across call sites. That is not a durable strategy once the schema evolves.

**Recommendation:** Deep-merge `settings` explicitly, or better, add a `schemaVersion` field and a small migration function that normalises any persisted payload to the current shape in one place.

---

## BUG-008: Running timer is lost on reload or tab close (Medium)

**Verification:** STATIC-ONLY.

**Evidence:** `src/pages/Timer.jsx:49-52`. `running`, `elapsed`, and `startTimeRef` are component-local `useState` and `useRef`. Nothing is written to `AppContext` or localStorage until the user presses Stop, at which point `ADD_BREAK` fires (`Timer.jsx:84`). Navigating to another route unmounts `Timer` and destroys the state.

**Repro steps:**
1. Press Start Break.
2. Navigate to Dashboard, then back to Timer. Or reload the page.

Expected for a mobile-first PWA: the timer survives, since the entire premise is that the user has left their desk with their phone.
Actual: the timer is reset to zero and the elapsed break is discarded with no warning.

**Impact:** This is the product's primary interaction. On mobile, backgrounding a PWA tab or letting the OS reclaim it discards the in-progress break. The failure is silent and the data is unrecoverable. Related: `Timer.jsx:76` discards any break under 1000 ms without feedback, so a mis-tap start-stop vanishes with no toast.

**Recommendation:** Persist `{ running, startedAt, category }` to localStorage on start and clear it on stop. On mount, rehydrate and recompute elapsed from `Date.now() - startedAt`. This also fixes the wall-clock drift inherent in the current `setInterval` approach.

---

## BUG-009: Zero-decimal currencies render with two decimals (Low)

**Verification:** STATIC-ONLY.

**Evidence:** `src/utils/calculations.js:33-40` hardcodes locale `'en-US'` and forces `minimumFractionDigits: 2` and `maximumFractionDigits: 2`. `src/pages/Settings.jsx:12` offers `JPY`, which is a zero-decimal currency.

**Repro:** Set currency to JPY. `Intl.NumberFormat` is overridden by the explicit fraction-digit options and renders `¥1,234.00`, which is not valid JPY formatting.

**Impact:** Cosmetic but visible, and it undercuts a product whose core output is a formatted money figure. The hardcoded `en-US` locale also means every user, in every region, sees US grouping and separator conventions.

**Recommendation:** Drop the explicit fraction-digit options and let `Intl` derive them from the currency, or set them conditionally. Use `undefined` for the locale so the browser locale applies, or make locale a setting alongside currency.

---

## BUG-010: Timezone setting is captured but never used (Low)

**Verification:** STATIC-ONLY.

**Evidence:** `src/utils/storage.js:9` captures `Intl.DateTimeFormat().resolvedOptions().timeZone` into `settings.timezone` at first load. A grep across `src/` finds no read of `settings.timezone` anywhere. All date logic uses the browser's ambient local time: `calculations.js:61-92`, `Dashboard.jsx:88-95`, `Achievements.jsx:21-22`.

**Impact:** Dead configuration. The stored value is also a mild privacy signal (see F-013) that the app collects and exports without ever using it. A traveller crossing timezones sees their day boundaries and Early Bird / Night Owl achievements shift with no explanation, because the captured timezone is not applied.

**Recommendation:** Either apply the stored timezone in the date-range selectors, or remove the field from the schema and the export payload.

---

## BUG-011: Cascading re-renders in the onboarding flow (Low)

**Verification:** VERIFIED by lint. `npm run lint` exit 1, rule `react-hooks/set-state-in-effect` at `src/components/Application.jsx:83` (with related calls at lines 84 and 85).

**Evidence:** State setters are called synchronously in an effect body rather than in an event handler or a lazy initialiser.

**Impact:** Extra render passes during the onboarding animation. No incorrect output observed, but it is the only lint error in the set with a runtime cost, and it is on the first screen every new user sees.

**Recommendation:** Move the initialisation into the `useState` initialiser or an event handler, or guard the effect so it runs once.

---

## Coverage note

Every defect above is derived from code reading plus a verified build and lint pass. **No behavioural repro was executed in a browser.** BUG-001 and BUG-011 are VERIFIED because a build artifact and a lint rule respectively confirm them without needing a browser. The remaining nine are STATIC-ONLY: the code path is unambiguous, but no one has driven the UI to observe the failure. There is no test suite to encode any of this, which is why F-004 is rated High.

---
generated_by: codebase-audit skill v1.1
generated_on: 2026-07-28
project: C:\Users\Ziggy\Dropbox\GitHub\fuck_corpo
project_type: node
verification: full
---
