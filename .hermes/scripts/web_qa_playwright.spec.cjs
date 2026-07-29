const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

const baseUrl = 'http://127.0.0.1:8787';
const outDir = path.resolve(__dirname, '..', 'web-proof');
const report = [];
fs.mkdirSync(outDir, { recursive: true });

const legacyPayload = {
  salary: { amount: 65000, type: 'annual', currency: 'EUR' },
  breaks: [
    { id: 'break-0', category: 'Bathroom', duration: 600000, timestamp: '2026-03-01T09:00:00.000Z' },
    { id: 'break-1', category: 'Bathroom', duration: 600001, timestamp: '2026-03-02T09:00:00.000Z' },
  ],
  settings: { theme: 'light', currency: 'EUR', timezone: 'America/New_York', industry: 'Technology', state: 'NY', soundEnabled: false },
  achievements: ['first_flush'],
  onboarded: true,
};

async function visibleText(page) { return (await page.locator('body').innerText()).replace(/\s+/g, ' ').trim(); }
async function shot(page, name) { await page.screenshot({ path: path.join(outDir, `${name}.png`), fullPage: true }); }

test.use({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true });

test('Flutter web hosted smoke and v0 migration bridge', async ({ page }) => {
  page.on('console', msg => { if (msg.type() === 'error') report.push(`console-error: ${msg.text()}`); });
  page.on('pageerror', err => report.push(`pageerror: ${err.message}`));

  await page.goto(baseUrl, { waitUntil: 'networkidle' });
  await page.evaluate(() => localStorage.clear());
  await page.reload({ waitUntil: 'networkidle' });
  await page.waitForTimeout(2500);
  await shot(page, '01-fresh-landing');
  let text = await visibleText(page);
  expect(text).toContain('APPLICATION FOR EMPLOYMENT');
  report.push('fresh_has_application=true');

  await page.evaluate((payload) => { localStorage.clear(); localStorage.setItem('fuckcorpo_data', JSON.stringify(payload)); }, legacyPayload);
  await page.reload({ waitUntil: 'networkidle' });
  await page.waitForTimeout(3500);
  await shot(page, '02-after-v0-migration');
  text = await visibleText(page);
  const storage = await page.evaluate(() => ({
    legacy: localStorage.getItem('fuckcorpo_data'),
    v1: localStorage.getItem('fuckcorpo_state_v1'),
    marker: localStorage.getItem('fuckcorpo_migrated_from_v0'),
    backup: localStorage.getItem('fuckcorpo_data_backup'),
  }));
  expect(text).toMatch(/START BREAK|Bathroom|Dashboard|Settings/);
  expect(storage.legacy).toBe(JSON.stringify(legacyPayload));
  expect(storage.v1).toBeTruthy();
  expect(storage.marker).toBe('true');
  expect(storage.backup).toBeNull();
  const parsed = JSON.parse(storage.v1);
  report.push(`migration_routed_to_shell=true`);
  report.push(`legacy_preserved=true`);
  report.push(`v1_written=true`);
  report.push(`marker_true=true`);
  report.push(`backup_absent=true`);
  report.push(`migrated_salary=${parsed.salary?.amount}`);
  report.push(`migrated_currency=${parsed.settings?.currency}`);
  report.push(`migrated_break_count=${parsed.breaks?.length}`);
  report.push(`migrated_onboarded=${parsed.onboarded}`);

  for (const [label, regex, name] of [
    ['Dashboard', /DASHBOARD|Earnings|Today/i, '03-dashboard'],
    ['Achievements', /INVESTOR ACHIEVEMENTS|unlocked|First Flush/i, '04-achievements'],
    ['Settings', /EXECUTIVE COMPENSATION|Compensation Package|Export Data|Import Data/i, '05-settings'],
    ['Timer', /START BREAK|Quick Log|Today/i, '06-timer'],
  ]) {
    await page.getByText(label, { exact: true }).last().click();
    await page.waitForTimeout(1200);
    await shot(page, name);
    text = await visibleText(page);
    expect(text).toMatch(regex);
    report.push(`${name}_ok=true`);
  }

  await page.evaluate(() => { localStorage.clear(); localStorage.setItem('fuckcorpo_data', '{not json'); });
  await page.reload({ waitUntil: 'networkidle' });
  await page.waitForTimeout(2500);
  await shot(page, '07-corrupt-v0-backup');
  const corruptStorage = await page.evaluate(() => ({
    backup: localStorage.getItem('fuckcorpo_data_backup'),
    marker: localStorage.getItem('fuckcorpo_migrated_from_v0'),
    v1: localStorage.getItem('fuckcorpo_state_v1'),
  }));
  text = await visibleText(page);
  expect(text).toMatch(/APPLICATION FOR EMPLOYMENT|BEGIN APPLICATION/);
  expect(corruptStorage.backup).toBe('{not json');
  expect(corruptStorage.marker).toBe('true');
  expect(corruptStorage.v1).toBeNull();
  report.push('corrupt_does_not_brick=true');
  report.push('corrupt_backup_written=true');
  report.push('corrupt_marker_true=true');
  report.push('corrupt_v1_absent=true');

  fs.writeFileSync(path.join(outDir, 'web-qa-report.txt'), report.join('\n') + '\n');
});
