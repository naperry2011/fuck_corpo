<div align="center">

# :toilet: FuckCorpo

### *Your Quarterly Bathroom Earnings Report*

**A Progressive Web App that calculates exactly how much your employer pays you to take bathroom breaks.**<br>
**Because your time is valuable -- even in the bathroom.**

[![React](https://img.shields.io/badge/React-19-61DAFB?style=for-the-badge&logo=react&logoColor=white)](https://react.dev)
[![Vite](https://img.shields.io/badge/Vite-7-646CFF?style=for-the-badge&logo=vite&logoColor=white)](https://vite.dev)
[![PWA](https://img.shields.io/badge/PWA-Ready-00b559?style=for-the-badge&logo=pwa&logoColor=white)](https://web.dev/progressive-web-apps/)
[![License](https://img.shields.io/badge/License-MIT-ffd60a?style=for-the-badge)](LICENSE)

---

**`$POOP` +2.47%** &nbsp;&nbsp; | &nbsp;&nbsp; **`$TIME` +0.83%** &nbsp;&nbsp; | &nbsp;&nbsp; **`$FLUSH` +5.12%** &nbsp;&nbsp; | &nbsp;&nbsp; **`$BREAK` +1.94%**

---

</div>

## :memo: EXECUTIVE SUMMARY

FuckCorpo is a satirical PWA that tracks money earned during bathroom breaks at work. Enter your salary, start the timer when nature calls, and watch your "bathroom earnings" tick up in real time. Think of it as a stock ticker for your most productive meetings -- the ones you attend solo, seated comfortably, behind a locked door.

Built with the polished aesthetic of Wall Street trading floors and Fortune 500 annual reports, but subverted to celebrate the one thing corporate America can never fully optimize: **your bathroom time**.

> *"SHAREHOLDER VALUE: YOU."*

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
| :lock: **100% Private** | All data stays in localStorage. No accounts, no tracking, no analytics. Your bathroom habits are yours alone. |

---

## :wrench: TECHNOLOGY INFRASTRUCTURE

| Layer | Technology | Purpose |
|---|---|---|
| **Framework** | React 19 | UI component architecture |
| **Build Tool** | Vite 7 | Lightning-fast dev server & builds |
| **Charts** | Chart.js + react-chartjs-2 | Earnings visualizations & dashboards |
| **Routing** | react-router-dom 7 | SPA navigation |
| **Icons** | lucide-react | Clean, professional iconography |
| **PWA** | vite-plugin-pwa + Workbox | Offline capability & installability |
| **Storage** | localStorage | Zero-dependency, 100% private data |

---

## :briefcase: ONBOARDING GUIDE

### Prerequisites

- Node.js 18+
- npm 9+

### Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/fuck_corpo2.git

# Enter the corporate headquarters
cd fuck_corpo2

# Install dependencies (the only corporate expense)
npm install

# Launch the development server
npm run dev
```

Then open [http://localhost:5173](http://localhost:5173) and begin maximizing your bathroom ROI.

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

```
src/
├── main.jsx                          # Application entry point
├── App.jsx                           # Root component & routing
├── App.css                           # Global app styles
├── index.css                         # Base styles & CSS variables
│
├── components/
│   ├── Application.jsx               # Corporate job application flow
│   ├── Application.css
│   ├── layout/
│   │   ├── Layout.jsx                # Main layout wrapper
│   │   ├── Layout.css
│   │   ├── Navbar.jsx                # Top navigation bar
│   │   ├── Navbar.css
│   │   ├── Ticker.jsx                # Stock ticker tape component
│   │   └── Ticker.css
│   └── shared/
│       ├── AnimatedCurrency.jsx      # Animated dollar amount display
│       ├── Button.jsx                # Styled button component
│       ├── Button.css
│       ├── Card.jsx                  # Premium card component
│       ├── Card.css
│       ├── PageTransition.jsx        # Fade & slide page transitions
│       ├── PageTransition.css
│       ├── Toast.jsx                 # Notification toast system
│       └── Toast.css
│
├── pages/
│   ├── Landing.jsx                   # Hero landing page
│   ├── Landing.css
│   ├── Dashboard.jsx                 # Earnings dashboard & charts
│   ├── Dashboard.css
│   ├── Timer.jsx                     # Live break timer
│   ├── Timer.css
│   ├── Achievements.jsx              # Badge collection & progress
│   ├── Achievements.css
│   ├── Settings.jsx                  # Salary, preferences & data mgmt
│   └── Settings.css
│
├── context/
│   ├── AppContext.jsx                # Global state (salary, breaks, theme)
│   └── ToastContext.jsx              # Toast notification state
│
├── hooks/
│   ├── useCountUp.js                 # Animated number count-up hook
│   └── useSound.js                   # Cha-ching sound effect hook
│
└── utils/
    ├── calculations.js               # Salary-to-per-minute conversions
    ├── funFacts.js                    # Satirical facts & comparisons
    └── storage.js                     # localStorage read/write helpers
```

---

## :rocket: BUILD & DEPLOYMENT

```bash
# Production build
npm run build

# Preview the production build locally
npm run preview

# Lint the codebase
npm run lint
```

The production build outputs to `dist/` with full PWA support -- service worker, manifest, and offline caching included.

---

## :handshake: CONTRIBUTING

Contributions welcome. Whether you are fixing bugs, adding features, or improving the satirical copy, we appreciate the help.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/bathroom-innovation`)
3. Commit your changes (`git commit -m "Add bidet earnings multiplier"`)
4. Push to the branch (`git push origin feature/bathroom-innovation`)
5. Open a Pull Request

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
