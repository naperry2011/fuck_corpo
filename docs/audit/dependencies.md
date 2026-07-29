# Dependencies

Manifest: `package.json` | Lockfile: `package-lock.json` (lockfileVersion 3) | Package manager: npm
Module type: ESM (`"type": "module"`). Private package, version `0.0.0`.
Analysis date: 2026-07-28

---

## 1. Toolchain observed

| Item | Value |
|---|---|
| node | v25.9.0 |
| npm | 11.12.1 |
| `npm ci` | exit 0, 444 packages added, 445 audited, ~9s |
| Resolved lockfile entries | 493 |

`node_modules/` was absent at audit start. It was populated by `npm ci` during verification.

---

## 2. Scripts

| Script | Command |
|---|---|
| `dev` | `vite` |
| `build` | `vite build` |
| `lint` | `eslint .` |
| `preview` | `vite preview` |

No `test`, no `format`, no `typecheck` script.

---

## 3. Production dependencies (8)

| Package | Constraint | Purpose |
|---|---|---|
| `react` | `^19.2.0` | UI runtime |
| `react-dom` | `^19.2.0` | DOM renderer |
| `react-router-dom` | `^7.13.0` | Client-side routing |
| `chart.js` | `^4.5.1` | Charting engine |
| `react-chartjs-2` | `^5.3.1` | React bindings for Chart.js |
| `lucide-react` | `^0.563.0` | Icon set |
| `vite-plugin-pwa` | `^1.2.0` | Manifest and service worker generation (build-time only, misplaced) |
| `workbox-window` | `^7.4.0` | Service worker registration and update handling |

## 4. Dev dependencies (10)

| Package | Constraint | Purpose |
|---|---|---|
| `vite` | `^7.2.4` | Build tool and dev server |
| `@vitejs/plugin-react` | `^5.1.1` | Fast Refresh and JSX transform |
| `eslint` | `^9.39.1` | Linter (flat config) |
| `@eslint/js` | `^9.39.1` | Recommended rule set |
| `eslint-plugin-react-hooks` | `^7.0.1` | Hooks rules |
| `eslint-plugin-react-refresh` | `^0.4.24` | HMR safety rules |
| `globals` | `^16.5.0` | Global environment definitions |
| `@types/react` | `^19.2.5` | React type definitions |
| `@types/react-dom` | `^19.2.3` | React DOM type definitions |

`@types/*` are installed but there is no TypeScript compiler and no `tsconfig.json`. They serve editor tooling only.

---

## 5. Vulnerability scan (VERIFIED)

`npm audit` run against the installed tree. Exit code 1.

**Result: 19 vulnerabilities. 14 high, 3 moderate, 2 low.**

### Runtime-shipped, highest priority

| Package | Severity | Notes |
|---|---|---|
| `react-router` (via `react-router-dom` 7.13.0) | High | 12 advisories. The ones that matter for a client-only SPA are open redirect via backslash in `<Link>` and `useNavigate` (GHSA-wrjc-x8rr-h8h6), open redirect via protocol-relative `//` paths (GHSA-2j2x-hqr9-3h42), and unauthenticated denial of service via inefficient route matching (GHSA-chx6-hx7r-mcp5). The SSR, RSC, and single-fetch advisories in the same cluster do not apply to this deployment shape. Fixed range is above 7.14.1. |

This is the only advisory cluster in code that ships to the browser. Everything below runs at build time only.

### Build-chain and tooling

| Package | Severity | Class |
|---|---|---|
| `vite` (7.0.0 to 7.3.3) | High | Dev-server path traversal, arbitrary file read via WebSocket, `server.fs.deny` bypass on Windows, NTLMv2 hash disclosure via `launch-editor` UNC paths. Dev-server exposure only, but material on a Windows host if the dev server is ever bound to a non-loopback interface. |
| `rollup` | High | Arbitrary file write via path traversal |
| `postcss` | High | XSS via unescaped `</style>`, arbitrary file read via `sourceMappingURL` |
| `serialize-javascript` -> `@rollup/plugin-terser` -> `workbox-build` | High | RCE via `RegExp.flags`, CPU exhaustion DoS |
| `lodash` | High | Code injection via `_.template`, prototype pollution in `_.unset` / `_.omit` |
| `minimatch`, `picomatch`, `brace-expansion` | High | Multiple ReDoS and memory-exhaustion patterns |
| `js-yaml`, `flatted`, `fast-uri` | High | DoS, prototype pollution, path traversal |
| `@babel/plugin-transform-modules-systemjs` | High | Arbitrary code generation from malicious input |
| `@babel/core`, `esbuild`, `ajv` | Moderate / low | Arbitrary file read via `sourceMappingURL`; dev-server file read on Windows; ReDoS in `$data` |

`npm audit fix` is reported as available for all 19. That command has not been run; it is out of scope for a read-only audit.

Deprecation warnings observed during install: `sourcemap-codec@1.4.8`, `source-map@0.8.0-beta.0`, `glob@11.1.0`.

---

## 6. Outdated check

**VERIFICATION-GAP.** `npm outdated` was not executed successfully during the audit window. Given that `npm ci` resolved cleanly and `npm audit` reports fixes available for every finding, the practical drift signal is captured by the audit above. Run `npm outdated` locally to close this gap.

Browserslist emitted a notice during build that `caniuse-lite` data is roughly six months old.

---

## 7. Constraint quality

- **All 18 dependencies use caret ranges. Nothing is pinned.** With lockfileVersion 3 this is safe under `npm ci`, but a fresh `npm install` or any lockfile regeneration can shift React, Vite, and Router minors simultaneously.
- **`lucide-react` at `^0.563.0` is the highest-risk constraint.** Pre-1.0 semver means the caret behaves as `>=0.563.0 <0.564.0`, so it is effectively patch-pinned, but lucide ships icon renames and export changes in minor bumps with no stability guarantee. Any manual minor bump needs an icon-import audit.
- `vite-plugin-pwa` at `^1.2.0` is barely past 1.0 and its Workbox configuration surface is still moving.
- `vite-plugin-pwa` is declared in `dependencies` but is a build-time plugin never imported by shipped code. It belongs in `devDependencies`. `workbox-window` is correctly placed.
- **No `engines` field and no `.nvmrc`.** Vite 7 requires Node 20.19+ or 22.12+. Nothing in the repository documents or enforces this, so a contributor on Node 18 gets a confusing failure.
- No `.npmrc`, so registry, `save-exact`, and audit-level settings are all defaults.

---

## 8. Notably absent dependencies

| Missing | Impact |
|---|---|
| Test framework (Vitest, Jest, Testing Library, Playwright) | The core of this product is a money-per-minute earnings calculation. That arithmetic, the date-range selectors, and the localStorage round-trip are entirely untested. This is the single largest gap in the dependency set. |
| TypeScript | Currency math, timer state, and localStorage-persisted records are untyped, despite `@types/react` being installed. |
| Error or crash reporting | A PWA with a service worker fails in ways that are invisible without telemetry: stale precache, registration errors, lost offline writes. |
| Prettier or stylistic ESLint config | Formatting is unenforced. |
| CI configuration | No `.github/` directory. Lint and build never run automatically. |
| `eslint-plugin-jsx-a11y` | The design specification targets WCAG AAA. Nothing mechanically checks accessibility. |
| Schema validator (zod, valibot) | `importData` accepts arbitrary JSON with no validation. See `bugs.md` BUG-004. |
| Bundle analysis (`rollup-plugin-visualizer`) | The app ships one 475 kB chunk with no visibility into composition. |

---

## 9. Version compatibility notes

- **React 19 + Vite 7 + `@vitejs/plugin-react` 5** is the current intended combination. Plugin v5 is the release line built for Vite 7. `npm ci` resolved with no peer conflicts, so compatibility is VERIFIED for this lockfile.
- **React 19** removes `propTypes`, `defaultProps` on function components, and legacy string refs, and no longer requires `forwardRef`. Older tutorials and copied snippets will break.
- **`react-router-dom` v7** is ESM-first and merged the Remix data-router APIs. The app currently uses the declarative `<Routes>` / `<Route element>` form, which remains supported. In v7 the `react-router-dom` package largely re-exports `react-router`; importing from `react-router` directly is the documented path.
- **`vite-plugin-pwa` 1.x with `workbox-window` 7.x** is the matching pair. Bump the two together; a Workbox major split across them causes service worker registration mismatches.

---

## 10. Recommended actions

1. Upgrade `react-router-dom` past 7.14.1 to clear the only runtime-shipped high-severity advisory cluster.
2. Run `npm audit fix` and re-verify build and lint. All 19 findings report an available fix.
3. Add Vitest plus Testing Library and a `test` script. Cover `src/utils/calculations.js` first.
4. Add a CI workflow running `npm ci`, `npm run lint`, `npm run build`.
5. Move `vite-plugin-pwa` to `devDependencies` and add an `engines.node` field.
6. Pin `lucide-react` to an exact version and adopt Renovate or Dependabot for controlled bumps.

---
generated_by: codebase-audit skill v1.1
generated_on: 2026-07-28
project: C:\Users\Ziggy\Dropbox\GitHub\fuck_corpo
project_type: node
verification: full
---
