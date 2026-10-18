const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: false, args: ['--autoplay-policy=no-user-gesture-required'] });
  const page = await browser.newPage({ viewport: { width: 1100, height: 820 } });
  const out = [];
  page.on('console', m => { const t = m.text(); if (t.startsWith('-- "C')) out.push(t.slice(5, -1)); });
  await page.goto('http://127.0.0.1:8791/');
  await page.waitForSelector('#loading', { state: 'detached', timeout: 60000 });
  await page.waitForTimeout(8000);
  await page.mouse.click(38 + 510, 26 + 550); await page.waitForTimeout(4000);
  await page.mouse.click(38 + 768, 26 + 589); await page.waitForTimeout(9000);
  const I = 'sprite(2).scriptInstanceList[2]';
  const cmd = `put "C" && (the milliseconds mod 100000) && integer(${I}.pCam.cam.worldPosition.distanceTo(${I}.pBoarder[1].player.worldPosition)) && integer(${I}.pBoarder[1].speed) && integer(gHavok.simTime * 1000) && ${I}.pFPS.count`;
  for (let k = 0; k < 60; k++) { await page.evaluate(c => window.DirPlayerDebug.eval_command(c), cmd); await page.waitForTimeout(100); }
  await page.waitForTimeout(300);
  console.log(out.join('\n'));
  await browser.close();
})();
