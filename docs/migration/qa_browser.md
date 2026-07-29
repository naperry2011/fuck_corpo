# Browser QA sheet (gate G5, G8)

Derived from the migration plan Section 9.4 and 9.5.

**Nothing on this sheet has been executed yet.** Every row below is `NOT RUN`.
The only things verified on this machine so far are the automated checks in the
"Automated preconditions" table. Runtime browser behavior, installability, the
service worker, and the migration-on-a-real-profile run (G8) all require a human
driving a browser against a deployed preview, which has not happened.

---

## Automated preconditions (verified locally)

| Check | Command | Result | Date |
|---|---|---|---|
| Static analysis clean | `cd app && flutter analyze` | PASS, `No issues found!` | 2026-07-28 |
| Test suite green | `cd app && flutter test --reporter compact --concurrency=1` | PASS, 269 tests | 2026-07-28 |
| Web release build | `cd app && flutter build web --release` | PASS, `Built build\web` | 2026-07-28 |
| Manifest icons all resolve on disk | `flutter test test/web/pwa_config_test.dart` | PASS | 2026-07-28 |
| v0 bridge behavior | `flutter test test/data/migrations/` | PASS, 13 tests | 2026-07-28 |

These prove the artifact builds and the config is internally coherent. They do
**not** prove the app works in a browser.

## Recorded build size (plan Section 9.3)

Measured from `app/build/web` after `flutter build web --release`, default
CanvasKit renderer. Gzip figures are `gzip -9` on the local file, an
approximation of what a CDN would serve, not a measured network transfer.

| Asset | Raw | Gzip |
|---|---|---|
| `main.dart.js` | 2,948 kB | 866 kB |
| `canvaskit/canvaskit.wasm` | 7,060 kB | 2,831 kB |
| `canvaskit/skwasm.wasm` | 3,497 kB | 1,496 kB |
| `flutter.js` | 9 kB | 4 kB |
| Total output directory on disk | 42 MB | n/a |

A cold desktop load pulls roughly `main.dart.js` + `canvaskit.wasm` + loader,
about **3.7 MB gzipped**, against React's ~156 kB gzipped. That is a ~24x
regression on first load and it is the single largest tradeoff in this
migration. Plan Section 11.1 requires this number be looked at and an explicit
decision made before cutover. **That decision is still open.** Repeat-visit cost
is far lower once the service worker precache is warm, but the first visit is
the one that matters for a mobile-first product used on cellular.

---

## Environments to cover

| Browser | Status |
|---|---|
| Chrome desktop | NOT RUN |
| Safari desktop or iOS Safari | NOT RUN |
| Firefox desktop | NOT RUN |
| Chrome Android | NOT RUN |

Run against a deployed preview URL, not localhost, side by side with the React
production app in a second window using the same seeded data.

---

## Script

Status column values: `NOT RUN` / `PASS` / `FAIL`.

### Migration (gate G8)

| # | Step | Expected | Status |
|---|---|---|---|
| M1 | Open the preview in a **real pre-existing browser profile** that already has React data under `fuckcorpo_data` | App boots with all existing breaks present | NOT RUN |
| M2 | Compare every total against React side by side | Identical to the cent | NOT RUN |
| M3 | Inspect `localStorage` in DevTools | `fuckcorpo_data` still present and unmodified; `flutter.fuckcorpo_state_v1` written; `flutter.fuckcorpo_migrated_from_v0` = `true` | NOT RUN |
| M4 | Reload | No re-import, no duplicated breaks | NOT RUN |
| M5 | Add a break in React, reload Flutter | Flutter does **not** pick it up. This divergence is intended, see plan 8.3 | NOT RUN |
| M6 | Seed a profile with `fuckcorpo_data` = `{not json`, load | App boots to defaults, `fuckcorpo_data_backup` written, original key intact | NOT RUN |
| M7 | Fresh profile, no prior data | Onboarding shown | NOT RUN |
| M8 | Profile with partial `settings` | Missing settings fall back to defaults, nothing undefined | NOT RUN |

Note on M6: the bridge preserves the payload and boots clean, but the **one-time
in-app notice** offering export of the raw JSON, described in plan Section 8.3,
is not implemented. Today the failure is silent to the user. Open item.

### Core flows

| # | Step | Expected | Status |
|---|---|---|---|
| 1 | Fresh profile, all 5 onboarding steps | Lands on Timer | NOT RUN |
| 2 | Start timer, wait 30s, navigate to Dashboard and back | Still running, elapsed correct (React fails this; documented deviation D-008) | NOT RUN |
| 3 | Reload mid-timer | Elapsed preserved | NOT RUN |
| 4 | Stop the timer | Toast text and earnings match the React format, sound plays | NOT RUN |
| 5 | Quick log 15 minutes yesterday | Appears in Recent, counts in the Dashboard week bucket | NOT RUN |
| 6 | Delete a break | Removed everywhere including the ticker | NOT RUN |
| 7 | Dashboard | 5 totals, 3 charts, fun fact rotates at 10s, memo employee number correct, all 5 doughnut categories visually distinct | NOT RUN |
| 8 | Achievements | Unlock First Flush, toast fires once, ASCII clipboard payload byte-identical to React | NOT RUN |
| 9 | Settings, switch to EUR | Every money figure app-wide changes | NOT RUN |
| 10 | Settings, switch to JPY | No decimals anywhere | NOT RUN |
| 11 | Theme to light, reload | Still light | NOT RUN |
| 12 | Sound off, log a break | No sound | NOT RUN |
| 13 | Export, clear, import the exported file | State fully restored | NOT RUN |
| 14 | Import a malformed file | Error shown, existing state intact | NOT RUN |
| 15 | Hard refresh on `/dashboard` | Loads correctly (requires the SPA rewrite in `app/vercel.json`) | NOT RUN |
| 16 | Resize to 320 / 768 / 1024 / 1440 | All usable, navbar switches at 768 | NOT RUN |
| 17 | Keyboard-only navigation | Reaches every interactive control | NOT RUN |

### PWA and installability (plan 9.5)

| # | Step | Expected | Status |
|---|---|---|---|
| P1 | DevTools > Application > Manifest | No errors, all 4 icons resolve, name `FuckCorpo: Get Paid to Shit` | NOT RUN |
| P2 | Install prompt | Appears; installed app launches standalone, portrait, navy splash | NOT RUN |
| P3 | Load once, go offline, reload | Boots from the service worker and shows persisted data | NOT RUN |
| P4 | Lighthouse | PWA installability passes; record Performance / Accessibility / Best Practices / SEO as a baseline against React | NOT RUN |
| P5 | Share a link into Slack or iMessage | Preview shows the title, description and the `$` icon from the Open Graph tags | NOT RUN |

---

## Known gaps that will affect this sheet

1. ~~**Icons are placeholders.**~~ **CLOSED.** `app/web/icons/*` and
   `app/web/favicon.png` are now real generated brand assets produced by
   `app/tool/generate_brand_assets.py` from design tokens, sized, declared, and
   maskable-safe, with `app/test/web/brand_assets_test.dart` pinning them. Final
   human brand approval still applies before a public release.
2. ~~**`og:image` points at `icons/Icon-512.png`.**~~ **CLOSED.** A dedicated
   1200x630 card lives at `app/web/social/og-card.png` and is wired through the
   Open Graph and Twitter meta in `app/web/index.html`.
3. ~~**Fonts are not self-hosted.**~~ **CLOSED.** Playfair Display, Work Sans and
   Roboto Mono are committed as upstream OFL variable fonts under
   `app/assets/fonts/`, declared in `pubspec.yaml`, and guarded by
   `app/test/core/theme/fonts_test.dart`. Parity row I2 is closed.
4. **No Vercel project exists yet.** `app/vercel.json` is written and unit
   checked, but nothing has been deployed. There is no preview URL, so every row
   here is blocked on plan task 22.
