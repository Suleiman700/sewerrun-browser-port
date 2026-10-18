const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: false, args: ['--autoplay-policy=no-user-gesture-required'] });
  const page = await browser.newPage({ viewport: { width: 1100, height: 820 } });
  const logs = { push: (x) => { if (!/changeWheels|Initialized/.test(x)) console.log(x); } };
  page.on('crash', () => console.log('!!! PAGE CRASHED'));
  page.on('console', m => { const t = m.text(); if (t.startsWith('--') || /rror|panick/.test(t)) logs.push(t.slice(0, 300)); });
  await page.goto('http://127.0.0.1:8791/');
  await page.waitForSelector('#loading', { state: 'detached', timeout: 60000 });
  await page.waitForTimeout(8000);
  await page.mouse.click(38 + 510, 26 + 550); await page.waitForTimeout(4000);
  await page.mouse.click(38 + 768, 26 + 589);
  await page.evaluate(() => { window.__d = []; let last = performance.now(); const f = t => { window.__d.push(t - last); last = t; requestAnimationFrame(f); }; requestAnimationFrame(f); });
  const I = 'sprite(2).scriptInstanceList[2]';
  const t0 = Date.now();
  for (let k = 0; k < 24; k++) {
    // light steering so the rider keeps moving
    const key = k % 4 < 2 ? 'ArrowLeft' : 'ArrowRight';
    await page.waitForTimeout(400);
    const fps = await page.evaluate(() => { const d = window.__d.splice(0); return d.length ? (1000 / (d.reduce((a, b) => a + b, 0) / d.length)).toFixed(0) : 0; });
    const mem = await page.evaluate(() => performance.memory ? (performance.memory.usedJSHeapSize/1e6).toFixed(0) : '?');
    const m = await page.context().newCDPSession(page).then(c => c.send('Memory.getDOMCounters').catch(()=>({})));
    if (k === 3 || k === 20) await page.screenshot({ path: `./shots/long${k}.png` });
    logs.push(`@${((Date.now() - t0) / 1000).toFixed(0)}s fps=${fps} jsHeapMB=${mem}`);
    for (const expr of ['the frameTempo', `${I}.pFPS.rate`, 'gFPSFactor', `integer(${I}.pBoarder[1].speed)`, `${I}.pCam.buffer`]) {
      await page.evaluate(c => window.DirPlayerDebug.eval_command(c), `put ${expr}`);
    }
    await page.waitForTimeout(150);
  }


  await browser.close();
})();
