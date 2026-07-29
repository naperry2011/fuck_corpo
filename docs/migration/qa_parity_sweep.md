# Local React vs Flutter parity sweep

Date: 2026-07-28
Status: **LOCAL FEATURE PARITY EVIDENCE COMPLETE. Not production cutover proof.**

## Scope

This sweep covers parity matrix screen rows 4.4 through 4.8 by comparing the
current React build against the current Flutter web build on the same Windows
machine.

It is intentionally local:
- React was built with `npm run build -- --mode production` into `dist/`.
- Flutter was built with `flutter build web` into `app/build/web`.
- Both were served through `.hermes/scripts/parity_static_server.py` with SPA
  rewrites.
- The same synthetic-but-realistic React v0 `fuckcorpo_data` payload was seeded
  into both browser profiles. React consumes it natively; Flutter imports it
  through the v0 bridge.

This proves local functional/screen parity evidence. It does **not** prove
Vercel deployment, Lighthouse PWA status, offline installability, production
migration, Play Store, or iOS/TestFlight.

## Commands

Run from the repo root:

```bash
npm run build -- --mode production
flutter build web # from app/
python .hermes/scripts/parity_static_server.py app/build/web 8787
python .hermes/scripts/parity_static_server.py dist 8788
NODE_PATH="$(pwd -W)\\.hermes\\playwright-runner\\node_modules" node .hermes/scripts/parity_sweep.cjs
```

Latest execution result:

```text
React build: exit 0
Flutter build web: exit 0
Flutter static server: http://127.0.0.1:8787, HTTP 200
React static server: http://127.0.0.1:8788, HTTP 200
Parity sweep script: exit 0
```

## Artifacts

- Harness: `.hermes/scripts/parity_sweep.cjs`
- Report: `.hermes/parity-proof/parity-sweep-report.txt`
- Contact sheet: `.hermes/parity-proof/contact-sheet.html`
- React DOM copy snapshot: `.hermes/parity-proof/react-rendered-copy.json`
- Screenshots: `.hermes/parity-proof/{mobile,desktop}/{react,flutter}/`

Captured rows/screens:

```text
mobile/flutter/01-landing captured (rows O1, O2)
mobile/flutter/02-timer captured (rows T1, T3, T4, T5)
mobile/flutter/03-dashboard captured (rows D1-D9)
mobile/flutter/04-achievements captured (rows A1, A3, A4)
mobile/flutter/05-settings captured (rows S1-S8)
mobile/react/01-landing captured (rows O1, O2)
mobile/react/02-timer captured (rows T1, T3, T4, T5)
mobile/react/03-dashboard captured (rows D1-D9)
mobile/react/04-achievements captured (rows A1, A3, A4)
mobile/react/05-settings captured (rows S1-S8)
desktop/flutter/01-landing captured (rows O1, O2)
desktop/flutter/02-timer captured (rows T1, T3, T4, T5)
desktop/flutter/03-dashboard captured (rows D1-D9)
desktop/flutter/04-achievements captured (rows A1, A3, A4)
desktop/flutter/05-settings captured (rows S1-S8)
desktop/react/01-landing captured (rows O1, O2)
desktop/react/02-timer captured (rows T1, T3, T4, T5)
desktop/react/03-dashboard captured (rows D1-D9)
desktop/react/04-achievements captured (rows A1, A3, A4)
desktop/react/05-settings captured (rows S1-S8)
```

## Coverage of parity matrix screen rows

| Matrix area | Evidence |
|---|---|
| 4.4 Onboarding / first-run | `01-landing` screenshots, mobile and desktop, React and Flutter |
| 4.5 Timer | `02-timer` screenshots, mobile and desktop, React and Flutter |
| 4.6 Dashboard | `03-dashboard` screenshots plus scroll captures |
| 4.7 Achievements | `04-achievements` screenshots plus scroll captures |
| 4.8 Settings / import/export / copy | `05-settings` screenshots plus scroll captures |

## Verdict

Local screen/feature parity is complete for the planned MVP parity scope, backed
by repeatable React-vs-Flutter screenshot evidence and the 269-test Flutter
suite.

True 100% release parity is **not** complete until the external gates are closed:
staged web deployment, genuine-profile migration, Lighthouse/install/offline PWA
checks, Android signing/internal-track or waiver, and iOS/TestFlight or written
defer decision.
