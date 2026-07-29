const { chromium } = require('playwright');
(async()=>{
const browser=await chromium.launch({headless:true}); const page=await browser.newPage();
await page.goto('http://127.0.0.1:8787/', {waitUntil:'networkidle'});
await page.evaluate(()=>localStorage.clear());
await page.evaluate(()=>localStorage.setItem('fuckcorpo_data', JSON.stringify({salary:{amount:65000,type:'annual',currency:'EUR'},breaks:[{id:'break-0',category:'Bathroom',duration:600000,timestamp:'2026-03-01T09:00:00.000Z'}],settings:{currency:'EUR'},onboarded:true})));
await page.reload({waitUntil:'networkidle'}); await page.waitForTimeout(5000);
const data=await page.evaluate(()=>Object.fromEntries([...Array(localStorage.length).keys()].map(i=>{const k=localStorage.key(i);return [k,localStorage.getItem(k)]})));
console.log(JSON.stringify(data,null,2));
await browser.close();
})();
