/**
 * Repeatable React-vs-Flutter parity sweep (parity matrix rows 4.4 - 4.8).
 *
 * Drives both builds from identical seeded state and captures matched
 * screenshot pairs for human comparison, plus whatever structured signal each
 * app can actually give.
 *
 * Why screenshots and not DOM assertions: Flutter web paints to a canvas, so
 * there is no queryable text on the Flutter side. React is a normal DOM app and
 * IS asserted structurally. The Flutter side is a visual artifact reviewed
 * against the React pair, and the verdicts are recorded by a human in
 * docs/migration/qa_parity_sweep.md. This harness makes the sweep repeatable
 * and evidenced; it does not make it automatic.
 *
 * Seeding: both apps are pointed at the same React v0 `fuckcorpo_data` payload.
 * React consumes it natively; Flutter migrates it through the v0 bridge. So the
 * two screenshots are rendering the same salary, settings and break history.
 *
 * Prerequisites (from the repo root):
 *   npx vite build
 *   flutter build web                                   # run inside app/
 *   python .hermes/scripts/parity_static_server.py app/build/web 8787
 *   python .hermes/scripts/parity_static_server.py dist 8788
 *
 * Then, from the repo root:
 *   node .hermes/scripts/parity_sweep.cjs
 */
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

/**
 * Playwright is deliberately NOT a dependency of this repo: package.json
 * belongs to the live React app and this migration must not touch it. So
 * resolve it from wherever it already exists on the machine, global install
 * first, then the npx cache.
 */
function loadPlaywright() {
  const roots = [];
  try {
    roots.push(execSync('npm root -g', { encoding: 'utf8' }).trim());
  } catch { /* npm not on PATH; fall through to the cache scan */ }
  const npxCache = path.join(
    process.env.LOCALAPPDATA || process.env.HOME || '',
    'npm-cache',
    '_npx',
  );
  if (fs.existsSync(npxCache)) {
    for (const entry of fs.readdirSync(npxCache)) {
      roots.push(path.join(npxCache, entry, 'node_modules'));
    }
  }
  for (const root of roots) {
    const candidate = path.join(root, 'playwright');
    if (fs.existsSync(candidate)) return require(candidate);
  }
  throw new Error(
    'playwright not found. Run `npx playwright@1.62.0 --version` once to '
      + 'populate the npx cache, or install it globally.',
  );
}

const { chromium } = loadPlaywright();

const APPS = [
  { id: 'flutter', url: 'http://127.0.0.1:8787' },
  { id: 'react', url: 'http://127.0.0.1:8788' },
];

const VIEWPORTS = [
  { id: 'mobile', width: 390, height: 844, isMobile: true },
  { id: 'desktop', width: 1280, height: 900, isMobile: false },
];

const OUT = path.resolve(__dirname, '..', 'parity-proof');

/**
 * Fixed seed. Deliberately crosses the interesting boundaries: a non-USD
 * currency (row S8 / BUG-002), every break category (row D8 / BUG-005), enough
 * breaks to populate the 7-day chart and trip at least one achievement, and a
 * light-theme setting so the theme row is visible in the capture.
 */
const SEED_DAY = Date.UTC(2026, 6, 20, 14, 0, 0); // 2026-07-20, a fixed Monday.
const CATEGORIES = ['Bathroom', 'Coffee', 'Snack', 'Smoke', 'Walk'];
const seed = {
  salary: { amount: 65000, type: 'annual', currency: 'EUR' },
  breaks: Array.from({ length: 12 }, (_, i) => ({
    id: `break-${i}`,
    category: CATEGORIES[i % CATEGORIES.length],
    duration: (5 + (i % 7)) * 60 * 1000,
    timestamp: new Date(SEED_DAY - i * 20 * 60 * 60 * 1000).toISOString(),
  })),
  settings: {
    theme: 'dark',
    currency: 'EUR',
    timezone: 'America/New_York',
    industry: 'Technology',
    state: 'NY',
    soundEnabled: false,
  },
  achievements: [],
  onboarded: true,
};

/**
 * Every screen state the sweep captures. `scrolls` drives extra captures below
 * the fold: Flutter web scrolls inside the canvas, so a fullPage screenshot
 * only ever returns the viewport and long screens must be walked by hand.
 */
const SCREENS = [
  { name: '01-landing', route: '/', fresh: true, rows: 'O1, O2' },
  { name: '02-timer', route: '/', rows: 'T1, T3, T4, T5' },
  { name: '03-dashboard', route: '/dashboard', scrolls: 3, rows: 'D1-D9' },
  { name: '04-achievements', route: '/achievements', scrolls: 2, rows: 'A1, A3, A4' },
  { name: '05-settings', route: '/settings', scrolls: 3, rows: 'S1-S8' },
];

const SETTLE = 2500;

async function seedStorage(page, url, payload) {
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.evaluate((p) => {
    localStorage.clear();
    if (p) localStorage.setItem('fuckcorpo_data', JSON.stringify(p));
  }, payload);
}

async function capture(page, dir, base, scrolls) {
  fs.mkdirSync(dir, { recursive: true });
  await page.screenshot({ path: path.join(dir, `${base}.png`) });
  for (let i = 1; i <= (scrolls || 0); i += 1) {
    await page.mouse.move(page.viewportSize().width / 2, page.viewportSize().height / 2);
    await page.mouse.wheel(0, page.viewportSize().height * 0.85);
    await page.waitForTimeout(900);
    await page.screenshot({ path: path.join(dir, `${base}-scroll${i}.png`) });
  }
}

/** React is a DOM app, so its rendered text is asserted rather than eyeballed. */
async function reactText(page) {
  return page.evaluate(() => document.body.innerText.replace(/\s+/g, ' ').trim());
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const report = [];
  const reactCopy = {};

  for (const viewport of VIEWPORTS) {
    for (const app of APPS) {
      const context = await browser.newContext({
        viewport: { width: viewport.width, height: viewport.height },
        isMobile: viewport.isMobile,
        hasTouch: viewport.isMobile,
        deviceScaleFactor: 2,
        colorScheme: 'dark',
      });
      const page = await context.newPage();

      for (const screen of SCREENS) {
        await seedStorage(page, app.url, screen.fresh ? null : seed);
        await page.goto(app.url + screen.route, { waitUntil: 'load' });
        await page.waitForTimeout(SETTLE);
        const dir = path.join(OUT, viewport.id, app.id);
        await capture(page, dir, screen.name, screen.scrolls);
        if (app.id === 'react' && viewport.id === 'desktop') {
          reactCopy[screen.name] = await reactText(page);
        }
        report.push(`${viewport.id}/${app.id}/${screen.name} captured (rows ${screen.rows})`);
      }
      await context.close();
    }
  }

  fs.writeFileSync(
    path.join(OUT, 'react-rendered-copy.json'),
    `${JSON.stringify(reactCopy, null, 2)}\n`,
  );

  // Contact sheet: every capture paired React-left / Flutter-right, which is
  // the only practical way to review a canvas-rendered app against a DOM one.
  const rows = [];
  for (const viewport of VIEWPORTS) {
    const dir = path.join(OUT, viewport.id, 'react');
    const shots = fs.existsSync(dir) ? fs.readdirSync(dir).sort() : [];
    for (const shot of shots) {
      rows.push(
        `<tr><th>${viewport.id}<br><small>${shot.replace('.png', '')}</small></th>` +
          `<td><img src="${viewport.id}/react/${shot}"></td>` +
          `<td><img src="${viewport.id}/flutter/${shot}"></td></tr>`,
      );
    }
  }
  fs.writeFileSync(
    path.join(OUT, 'contact-sheet.html'),
    `<!doctype html><meta charset="utf-8"><title>FuckCorpo parity sweep</title>
<style>body{background:#0a1128;color:#fff;font-family:system-ui;margin:24px}
table{border-collapse:collapse}th,td{border:1px solid #1e2749;padding:8px;vertical-align:top}
img{max-width:560px;display:block}th{font-size:12px;color:#778da9}</style>
<h1>Parity sweep: React (left) vs Flutter (right)</h1>
<table><tr><th></th><th>React</th><th>Flutter</th></tr>
${rows.join('\n')}</table>\n`,
  );

  fs.writeFileSync(path.join(OUT, 'parity-sweep-report.txt'), `${report.join('\n')}\n`);
  console.log(report.join('\n'));
  await browser.close();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
