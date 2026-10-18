const { chromium } = require('playwright');
const out = process.argv[2];
const clicks = JSON.parse(process.argv[3] || '[]'); // [[x,y,waitMs,label],...] in stage coords
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: false, args: ['--autoplay-policy=no-user-gesture-required'] });
  const page = await browser.newPage({ viewport: { width: 1100, height: 820 } });
  const logs = [];
  page.on('console', m => logs.push(m.type() + ': ' + m.text()));
  page.on('pageerror', e => logs.push('PAGEERROR: ' + e.message));
  await page.goto('http://127.0.0.1:8790/');
  await page.waitForTimeout(30000);
  const box = await page.evaluate(() => { const c=[...document.querySelectorAll('canvas')].sort((a,b)=>b.width*b.height-a.width*a.height)[0]; const r=c.getBoundingClientRect(); return {x:r.x,y:r.y,w:r.width,h:r.height}; });
  await page.screenshot({ path: `${out}/s0.png` });
  let i = 1;
  for (const [x, y, w, label] of clicks) {
    if (label && label.startsWith('key:')) await page.keyboard.press(label.slice(4));
    else await page.mouse.click(box.x + x * box.w / 1024, box.y + y * box.h / 768);
    await page.waitForTimeout(w);
    await page.screenshot({ path: `${out}/s${i++}.png` });
  }
  console.log(JSON.stringify(box));
  require("fs").writeFileSync(out + "/console.log", logs.join("\n"));
  await browser.close();
})();
