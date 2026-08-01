<div align="center">

# :toilet: FuckCorpo

### *Your Quarterly Bathroom Earnings Report*

**A Flutter-first app that calculates exactly how much your employer pays you to take bathroom breaks.**<br>
**Because your time is valuable -- even in the bathroom.**

[![Flutter](https://img.shields.io/badge/Flutter-Forward-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![PWA](https://img.shields.io/badge/PWA-Ready-00b559?style=for-the-badge&logo=pwa&logoColor=white)](https://web.dev/progressive-web-apps/)
[![License](https://img.shields.io/badge/License-MIT-ffd60a?style=for-the-badge)](LICENSE)

---

**`$POOP` +2.47%** &nbsp;&nbsp; | &nbsp;&nbsp; **`$TIME` +0.83%** &nbsp;&nbsp; | &nbsp;&nbsp; **`$FLUSH` +5.12%** &nbsp;&nbsp; | &nbsp;&nbsp; **`$BREAK` +1.94%**

---

</div>

## :memo: EXECUTIVE SUMMARY

FuckCorpo is a satirical app that tracks money earned during bathroom breaks at work. Enter your salary, start the timer when nature calls, and watch your "bathroom earnings" tick up in real time. Think of it as a stock ticker for your most productive meetings -- the ones you attend solo, seated comfortably, behind a locked door.

Built with the polished aesthetic of Wall Street trading floors and Fortune 500 annual reports, but subverted to celebrate the one thing corporate America can never fully optimize: **your bathroom time**.

> *"SHAREHOLDER VALUE: YOU."*

---

## :warning: IMPLEMENTATION STATUS

**Flutter is now the forward implementation.** Product work should happen in `app/`.

The original React/Vite web app is **deprecated and frozen**. It remains in the repository only as a rollback path and migration reference until the cutover gates and 30-day quiet window are complete. See `docs/migration/react_deprecation.md` and `docs/migration/cutover_plan.md`.

Current posture:

| Implementation | Location | Status |
|---|---|---|
| Flutter app | `app/` | Forward implementation for web, Android, and iOS |
| React/Vite web | `src/`, root web files | Deprecated/frozen legacy implementation; rollback and migration reference only |

---

## :chart_with_upwards_trend: QUARTERLY FEATURE REPORT

| Feature | Description |
|---|---|
| :toilet: **Live Break Timer** | Real-time earnings counter while you handle business. Watch the dollars tick up penny by penny with a satisfying cha-ching. |
| :chart_with_upwards_trend: **Earnings Dashboard** | Charts, stats, and your personal "Quarterly Earnings Report" -- peak bathroom hours, day-of-week patterns, monthly trends, and lifetime totals. |
| :trophy: **Achievement Badges** | 11 unlockable corporate medals -- from "First Flush" ($1 earned) to the legendary "$10,000 Club". Each one a gold-embossed testament to your dedication. |
| :clipboard: **Corporate Application** | A 5-step satirical job application to become Chief Bathroom Revenue Officer. Complete with corporate personality assessment and official appointment letter. |
| :moneybag: **CEO Comparison** | See how your bathroom earnings compare to Fortune 500 CEOs. Spoiler: while you earned $2, the CEO earned $10,000. |
| :bell: **Toast Notifications** | Cha-ching sound effects and celebratory toasts when you log breaks, hit milestones, or unlock achievements. |
| :iphone: **Mobile-First PWA** | Installable, offline-capable, built for bathroom use. Add to home screen and never miss tracking a session. |
| :crescent_moon: **Dark / Light Mode** | Dark mode default -- essential for bathroom lighting conditions. Light mode available for the brave. |
| :outbox_tray: **Data Export / Import** | Your data, your rules. Full JSON export and import. No vendor lock-in on your bathroom portfolio. |
| :lock: **100% Private** | All data stays on device. No accounts, no tracking, no analytics. Your bathroom habits are yours alone. |

---

## :wrench: TECHNOLOGY INFRASTRUCTURE

| Layer | Technology | Purpose |
|---|---|---|
| **Framework** | Flutter / Dart | Shared app implementation for web and native targets |
| **State** | Riverpod | App state, persistence write path, derived values |
| **Routing** | go_router | App shell and route navigation |
| **Charts** | fl_chart | Earnings visualizations and dashboard charts |
| **Storage** | shared_preferences plus v0 localStorage bridge | Local-first persistence and React data migration |
| **PWA** | Flutter web + generated service worker | Offline-capable installable web app |
| **Fonts** | Self-hosted Playfair Display, Work Sans, Roboto Mono | No runtime font CDN dependency |

---

## :briefcase: ONBOARDING GUIDE

### Prerequisites

- Flutter SDK with Dart 3 support
- Android toolchain for Android builds
- macOS/Xcode for iOS builds

### Quick Start

```bash
cd app
flutter pub get
flutter run -d chrome
```

### Common validation

```bash
cd app
flutter analyze
flutter test --reporter compact --concurrency=1
flutter build web
```

The Flutter web production build outputs to `app/build/web/`.

### Legacy React web

The deprecated React app can still be built for rollback/reference checks:

```bash
npm ci
npm run build -- --mode production
```

Do not add new product work to React unless `docs/migration/react_deprecation.md` allows it.

---

## :art: BRAND IDENTITY GUIDELINES

FuckCorpo uses a **"Capitalist Satire"** design system -- appropriating the visual language of Wall Street and corporate America to celebrate worker autonomy.

### Color Palette

| Swatch | Token | Hex | Usage |
|---|---|---|---|
| :black_circle: | **Corporate Navy** | `#0a1128` | Primary backgrounds, headers |
| :blue_circle: | **Slate** | `#1e2749` | Cards, elevated surfaces |
| :green_circle: | **Stock Market Green** | `#00b559` | Earnings, success states |
| :red_circle: | **Stock Market Red** | `#e63946` | Time indicators, warnings |
| :yellow_circle: | **Achievement Gold** | `#ffd60a` | Badges, milestones |
| :white_circle: | **Cool Gray** | `#778da9` | Borders, secondary text |

### Typography

| Role | Font | Character |
|---|---|---|
| **Display** | Playfair Display | Editorial, authoritative -- for headlines & report titles |
| **Body** | Work Sans | Clean, corporate -- for UI text & navigation |
| **Data** | Roboto Mono | Financial terminal -- for dollar amounts, timers & stats |

---

## :file_folder: ORGANIZATIONAL STRUCTURE

```text
app/
├── lib/                              # Flutter product code
│   ├── main.dart                     # App bootstrap and v0 migration
│   ├── app.dart                      # MaterialApp.router and theme mode
│   ├── router.dart                   # Routes and shell
│   ├── core/                         # Theme tokens and formatters
│   ├── data/                         # Persistence, storage, migration bridge
│   ├── domain/                       # Pure calculations, models, copy, achievements
│   ├── features/                     # Timer, dashboard, achievements, onboarding, settings
│   ├── state/                        # Controllers and providers
│   └── widgets/                      # Product design-system widgets
├── test/                             # Unit and widget tests
├── web/                              # Flutter web shell, manifest, icons, social card
├── android/                          # Android platform target
├── ios/                              # iOS platform target
└── vercel.json                       # Flutter web static deploy config

src/                                  # Deprecated React/Vite web implementation
```

---

## :rocket: BUILD & DEPLOYMENT

```bash
cd app
flutter build web
```

The production Flutter web build outputs to `app/build/web/`. `app/vercel.json` is configured for static hosting with SPA rewrites and cache headers, but the release docs still require staging verification before production cutover.

See:

- `docs/migration/release_readiness.md`
- `docs/migration/cutover_plan.md`
- `docs/migration/react_deprecation.md`

---

## :handshake: CONTRIBUTING

Contributions welcome. Whether you are fixing bugs, adding features, or improving the satirical copy, we appreciate the help.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/bathroom-innovation`)
3. Keep product changes in the Flutter app under `app/`
4. Run `flutter analyze` and `flutter test --reporter compact --concurrency=1`
5. Commit your changes and open a Pull Request

Please keep the satirical corporate tone in any user-facing copy. We are irreverent but never mean-spirited. Pro-worker, anti-exploitation, always.

---

## :page_facing_up: LICENSE

MIT License. See [LICENSE](LICENSE) for details.

Free as in freedom. Free as in bathroom breaks.

---

<div align="center">

Made with :poop: and :heart: -- Because every flush is a transaction.

**Remember: Your employer cannot restrict your bathroom breaks. Know your rights.**

---

*CONFIDENTIAL -- For Internal Distribution Only*<br>
*FuckCorpo Inc. -- Board of Directors: You*<br>
*Turning Breaks Into Banks Since 2026*

</div>
