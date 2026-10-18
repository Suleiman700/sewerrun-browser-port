const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: false });
  const page = await browser.newPage({ viewport: { width: 1100, height: 820 } });
  const logs = [];
  page.on('console', m => { const t = m.text(); if (t.startsWith('--') || /rror/.test(t)) logs.push(t.slice(0, 400)); });
  await page.goto('http://127.0.0.1:8791/');
  await page.waitForSelector('#loading', { state: 'detached', timeout: 60000 });
  await page.waitForTimeout(8000);
  await page.mouse.click(38 + 510, 26 + 550); await page.waitForTimeout(5000);
  await page.mouse.click(38 + 768, 26 + 589); await page.waitForTimeout(20000);
  const cmds = JSON.parse(process.argv[2]);
  for (const c of cmds) { logs.push('>> ' + c.slice(0, 120)); await page.evaluate(x => window.DirPlayerDebug.eval_command(x), c); await page.waitForTimeout(400); }
  await page.screenshot({ path: "./shots/hud.png" });
  console.log(logs.join("\n"));
  await browser.close();
})();
