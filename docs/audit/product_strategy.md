# Product Strategy

Read from the code, the two specification documents, and the git history. Analysis date: 2026-07-28.

A caveat up front: everything below is inferred. There is no roadmap, no issue tracker, no analytics, and no user research in this repository. Section 5 lists what would sharpen this materially.

---

## 1. What this project is trying to be

**The premise.** A satirical, mobile-first PWA that converts time spent on bathroom breaks into a running dollar figure, using the corporate financial vocabulary it is mocking. The product is a joke with a real point underneath: your time has a price, and you are entitled to it.

**The wedge is the number.** The single valuable moment is the first one, when a user enters their salary and watches money accumulate in real time while they sit somewhere they were previously told not to linger. Everything else in the app is scaffolding around that moment. The `$POOP` ticker, the CONFIDENTIAL watermark, the "QUARTERLY EARNINGS REPORT" heading, the corporate memo generator, the CEO comparison at `Achievements.jsx:177-208` all exist to make the number feel official.

**Who it is for.** Hourly and salaried workers whose break time is monitored or discouraged: retail, food service, warehouse, call centre, healthcare. The industry list at `Settings.jsx:13-23` names exactly these. The design specification's Playfair Display and Wall Street Journal styling is not decoration; it is the whole joke, appropriating the visual authority of the institution being satirised.

**How it intends to spread.** The specification is explicit that virality is the growth model: shareable earnings graphics, social-optimised images, anonymous leaderboards by industry and state. The shipped implementation reaches for this once, in the Copy to Clipboard ASCII earnings statement at `Achievements.jsx:68-94`.

**The honest read on positioning.** This is a novelty product with an unusually strong hook and no retention mechanism yet. The distance between "I tried this and screenshotted it" and "I open this every day" is the entire strategic question, and nothing shipped answers it.

---

## 2. Where it is versus where it should be

The build is more complete than the git history suggests. Roughly 4,600 lines of hand-written source deliver a coherent, opinionated, on-brand application. Core tracking, calculation, visualisation, and achievements all work. The gap is not effort; it is that the last mile of each feature is unfinished, and the community half of the specification is absent.

### Shipped against the feature specification

| Specification area | Status | Note |
|---|---|---|
| Quick log | Shipped | `Timer.jsx:95-111` |
| Live timer | Shipped, fragile | Does not survive reload or navigation (F-012) |
| Automatic tracking | Not built | |
| Salary calculator | Shipped | Four salary types, no contract or variable-hours support |
| Break categories | Shipped, fixed set | No custom categories as specified |
| Running totals | Shipped | Day, week, month, year, lifetime |
| Leaderboards | **Not built** | Requires a backend that does not exist |
| Achievements | Shipped | 11 badges; no streak tracking, so "Consistency Champion" is a count not a streak |
| Shareable images | **Not built** | Only ASCII to clipboard. This is the growth mechanism. |
| Comparisons | Shipped | 7 items, `calculations.js:103-111` |
| Personal dashboard | Shipped | Peak hours, 7-day trend, category split. No day-of-week pattern, no monthly trend |
| Comparative data (industry, state) | **Not built** | Requires backend. Industry and state are collected but never used |
| Fun stats | Shipped | |
| Offline mode | Shipped | Service worker precache works |
| Optional account and sync | **Not built** | |
| Anonymous mode | **Not built** | |
| Export data | Shipped | Import is unvalidated (F-007) |
| Currency options | Shipped in UI, **non-functional** | F-003. Six currencies, none apply |
| Timezone settings | Collected, **never used** | F-018 |
| Labor rights info | Partially shipped | One static OSHA paragraph in Settings. Specification calls for per-state rights |
| CEO comparison | Shipped | Strongest satirical asset in the build |
| Fun facts | Shipped | Rotating, 10s interval |
| PWA installable | **Broken** | F-002. Missing icons, so it cannot be installed |
| Dark and light mode | Dark works, **light does not persist** | F-005 |

### The four gaps that matter strategically

1. **The product cannot be installed.** It is specified as a PWA because people use phones in bathrooms, and the manifest icons do not exist. The primary distribution channel is closed by three missing files (F-002). This is the highest return-on-effort item in the entire repository.

2. **The share loop is stubbed.** Growth depends on shareable images. What ships is ASCII text to a clipboard, which nobody posts to Instagram. The earnings statement card at `Achievements.jsx:132-173` is already designed and rendered; converting it to a downloadable image is a contained piece of work with disproportionate strategic payoff.

3. **Data is collected for features that do not exist.** Industry, state, and timezone are captured during onboarding and never read. They exist because the specification's leaderboards need them. Right now they are pure friction in the signup flow and a privacy cost with no user benefit (F-013, F-018). Either build the feature or stop asking.

4. **There is no reason to return tomorrow.** No streaks, no notifications, no daily goal, no weekly digest. Achievements unlock once and are done. The product has a magnificent first session and no second one.

### Engineering readiness gap

Separately from product scope: no tests, no CI, lint failing on `main`, 19 dependency advisories, and no error reporting. At the current size these are survivable. At the point a backend and a second contributor arrive, they are the constraint. Detail in `findings.md`.

---

## 3. Recommended order

Horizons align with `report.md`.

### First, make what exists actually work (1 to 2 weeks)

Nothing new. Close the gap between what the UI promises and what it does.

1. Add the three PWA icons. Unlocks installation, the entire distribution model.
2. Fix the currency setting (F-003). A visible feature that does nothing is worse than an absent one.
3. Persist the running timer (F-012). Protects the core interaction on the device it was designed for.
4. Fix light mode persistence (F-005) and the dashboard category colours (F-006).
5. Validate imports and add an error boundary (F-007, F-014). Removes the only path to a permanently broken install.
6. Upgrade `react-router-dom`, run `npm audit fix`, clear the five lint errors.
7. Add Vitest with coverage of `calculations.js`, plus a CI workflow. Do this before the backend, not after.

Rationale: every item is a correctness fix on a feature already built and already advertised. The cheapest possible improvement to perceived quality.

### Second, close the growth loop (2 to 4 weeks)

1. **Shareable image generation.** Render the existing earnings statement to canvas and offer download plus Web Share API. This is the single highest-leverage feature not yet built.
2. **Streaks and a daily hook.** Consecutive-day tracking, a visible streak counter, and one honest reason to open the app tomorrow. Make "Consistency Champion" mean what its name says.
3. **Per-state labour rights content.** Static, no backend required, genuinely useful, and it converts the product from a joke into something worth keeping installed. It is also the clearest expression of the stated pro-worker positioning.
4. **Onboarding trim.** Stop collecting industry, state, and timezone until a feature reads them, or move them behind an optional "help build the leaderboard" step with an honest explanation.

Rationale: this horizon answers the retention question and the acquisition question, and requires no infrastructure.

### Third, the community layer (backend required)

Only after the above. This is where the architecture changes shape.

1. Anonymous, aggregate-only leaderboards by industry and state. Submit a hashed device identifier plus bucketed statistics; never store raw salary server-side.
2. Optional account and cross-device sync.
3. Comparative dashboards: industry and state averages, the heatmap the specification describes.

Sequencing note: the moment a second writer exists, the design issues in `findings.md` (F-006, F-008, F-009) stop being cosmetic. Fix the store seams in the first horizon while they are cheap.

---

## 4. Future enhancements and strategic angles

**Highest confidence.**

- **Shareable image is the product's growth engine.** The visual system is already distinctive enough that a generated card is recognisable in a feed. This is the closest thing to a free acquisition channel available.
- **Labour rights content is the moat.** Anyone can clone the calculator in a weekend. A well-maintained, per-state, genuinely accurate break-rights reference is real work and real value, and it earns the product a place on a phone after the joke wears off. It also aligns the business with the stated politics rather than against them.
- **Browser extension** (named in the specification) suits desk workers, a segment the mobile PWA serves poorly.

**Worth considering.**

- **Aggregate data as the asset.** Anonymised break-economics data across industries and regions is genuinely newsworthy. A quarterly "State of the Break" report is earned media that no competitor can replicate without the same user base, and it reinforces the satirical brand rather than diluting it.
- **Union and labour-organisation partnerships.** A distribution channel that matches the positioning. Low cost, high alignment.
- **Salary transparency adjacency.** The app already holds salary, industry, and region. That is the seed of a compensation-comparison feature with far broader appeal than the bathroom joke. It is also the highest-risk pivot, because it changes the privacy posture completely and would require the security work in `findings.md` to be finished first.

**Be sceptical of.**

- **B2B or enterprise anything.** The product's entire premise is adversarial to employers. There is no credible buyer.
- **Ads.** The specification lists an ad-free version as monetisation, which implies ads. Ads on a privacy-positioned worker-solidarity product would undercut the only durable differentiator it has. If monetisation is needed, a small one-time payment for custom achievements and advanced analytics is more consistent with the brand.
- **Premium tiers before retention exists.** Nothing is worth paying for until someone has come back a fourth time.

**What I do not know:** whether this is a portfolio piece, a side project, or a launch candidate. That single answer changes the recommendation more than anything else in this document. The two-commit, one-author, five-months-dormant history reads as a build-in-a-weekend project rather than an operating product, so the first horizon is scoped as "make the existing surface honest" rather than "prepare for scale".

---

## 5. Questions for the owner

1. Is this a launch candidate, a portfolio piece, or an experiment? This determines whether the engineering readiness findings are urgent or academic.
2. Has it ever been deployed, and to where? No deployment configuration exists in the repository.
3. Are the leaderboards a real commitment or aspiration? If real, the backend decision should be made before more client state accretes. If not, the unused onboarding fields should be removed.
4. Is monetisation a goal at all, or is this deliberately non-commercial? The advice differs sharply.
5. Who else will work on this? A second contributor makes the test suite and CI immediately load-bearing rather than nice to have.
6. Is there any usage data at all, even anecdotal? The retention question is currently unanswerable from inside the repository.

---
generated_by: codebase-audit skill v1.1
generated_on: 2026-07-28
project: C:\Users\Ziggy\Dropbox\GitHub\fuck_corpo
project_type: node
verification: full
---
