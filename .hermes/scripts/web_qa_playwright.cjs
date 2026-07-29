const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const baseUrl='http://127.0.0.1:8787';
const outDir=path.resolve(__dirname,'..','web-proof'); fs.mkdirSync(outDir,{recursive:true});
const legacyPayload={salary:{amount:65000,type:'annual',currency:'EUR'},breaks:[{id:'break-0',category:'Bathroom',duration:600000,timestamp:'2026-03-01T09:00:00.000Z'},{id:'break-1',category:'Bathroom',duration:600001,timestamp:'2026-03-02T09:00:00.000Z'}],settings:{theme:'light',currency:'EUR',timezone:'America/New_York',industry:'Technology',state:'NY',soundEnabled:false},achievements:['first_flush'],onboarded:true};
async function shot(p,n){await p.screenshot({path:path.join(outDir,`${n}.png`),fullPage:true});}
(async()=>{
 const browser=await chromium.launch({headless:true});
 const page=await browser.newPage({viewport:{width:390,height:844},deviceScaleFactor:2,isMobile:true});
 const report=[];
 await page.goto(baseUrl,{waitUntil:'networkidle'}); await page.evaluate(()=>localStorage.clear()); await page.reload({waitUntil:'networkidle'}); await page.waitForTimeout(2500); await shot(page,'01-fresh-landing');
 await page.evaluate((payload)=>{localStorage.clear(); localStorage.setItem('fuckcorpo_data',JSON.stringify(payload));},legacyPayload); await page.reload({waitUntil:'networkidle'}); await page.waitForTimeout(3500); await shot(page,'02-after-v0-migration');
 const storage=await page.evaluate(()=>{const entries=Object.fromEntries([...Array(localStorage.length).keys()].map(i=>{const k=localStorage.key(i);return [k,localStorage.getItem(k)]})); const dec=v=>{if(v==null)return null; try{return JSON.parse(v)}catch{return v}}; const pick=n=>dec(entries[n]??entries[`flutter.${n}`]??null); return {keys:Object.keys(entries).sort(),legacy:entries.fuckcorpo_data,v1:pick('fuckcorpo_state_v1'),marker:pick('fuckcorpo_migrated_from_v0'),backup:entries.fuckcorpo_data_backup??null};});
 report.push(`legacy_preserved=${storage.legacy===JSON.stringify(legacyPayload)}`); report.push(`v1_written=${!!storage.v1}`); report.push(`marker_true=${storage.marker==='true'}`); report.push(`backup_absent=${storage.backup===null}`); if(storage.v1){const parsed=JSON.parse(storage.v1); report.push(`migrated_salary=${parsed.salary?.amount}`); report.push(`migrated_currency=${parsed.settings?.currency}`); report.push(`migrated_break_count=${parsed.breaks?.length}`); report.push(`migrated_onboarded=${parsed.onboarded}`);} report.push(`localStorage_keys=${storage.keys.join(',')}`);
 // CSS pixel coordinates for fixed bottom nav in the 390x844 viewport.
 await page.mouse.click(147,800); await page.waitForTimeout(1200); await shot(page,'03-dashboard');
 await page.mouse.click(240,800); await page.waitForTimeout(1200); await shot(page,'04-achievements');
 await page.mouse.click(329,800); await page.waitForTimeout(1200); await shot(page,'05-settings');
 await page.mouse.click(58,800); await page.waitForTimeout(1200); await shot(page,'06-timer');
 await page.evaluate(()=>{localStorage.clear(); localStorage.setItem('fuckcorpo_data','{not json');}); await page.reload({waitUntil:'networkidle'}); await page.waitForTimeout(2500); await shot(page,'07-corrupt-v0-backup');
 const corrupt=await page.evaluate(()=>{const entries=Object.fromEntries([...Array(localStorage.length).keys()].map(i=>{const k=localStorage.key(i);return [k,localStorage.getItem(k)]})); const dec=v=>{if(v==null)return null; try{return JSON.parse(v)}catch{return v}}; return {backup:entries.fuckcorpo_data_backup??null, marker:dec(entries['flutter.fuckcorpo_migrated_from_v0']??entries.fuckcorpo_migrated_from_v0??null), v1:dec(entries['flutter.fuckcorpo_state_v1']??entries.fuckcorpo_state_v1??null)};});
 report.push(`corrupt_backup_written=${corrupt.backup==='{not json'}`); report.push(`corrupt_marker_true=${corrupt.marker==='true'}`); report.push(`corrupt_v1_absent=${corrupt.v1===null}`);
 fs.writeFileSync(path.join(outDir,'web-qa-report.txt'),report.join('\n')+'\n'); console.log(report.join('\n'));
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
