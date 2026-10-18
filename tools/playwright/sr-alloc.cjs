const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: false, args: ['--autoplay-policy=no-user-gesture-required'] });
  const page = await browser.newPage({ viewport: { width: 1100, height: 820 } });
  await page.goto('http://127.0.0.1:8790/');
  await page.waitForSelector('#loading', { state: 'detached', timeout: 60000 });
  await page.waitForTimeout(8000);
  await page.mouse.click(38 + 510, 26 + 550); await page.waitForTimeout(4000);
  await page.mouse.click(38 + 768, 26 + 589);
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('HeapProfiler.enable');
  const prof = async (label) => {
    await cdp.send('HeapProfiler.startSampling', { samplingInterval: 32768, includeObjectsCollectedByMajorGC: true, includeObjectsCollectedByMinorGC: true });
    await page.waitForTimeout(6000);
    const { profile } = await cdp.send('HeapProfiler.stopSampling');
    const tot = {};
    const walk = (n, stack) => { const name = (n.callFrame.functionName || '(anon)') + ' ' + (n.callFrame.url || '').split('/').pop() + ':' + n.callFrame.lineNumber; const s = [...stack, name]; if (n.selfSize) { const k = s.slice(-3).join(' < '); tot[k] = (tot[k] || 0) + n.selfSize; } (n.children || []).forEach(c => walk(c, s)); };
    walk(profile.head, []);
    const all = Object.values(tot).reduce((a, b) => a + b, 0);
    console.log(`== ${label}: allocated ${(all / 1e6).toFixed(0)} MB in 6s`);
    console.log(Object.entries(tot).sort((a, b) => b[1] - a[1]).slice(0, 6).map(([k, v]) => `${(v / 1e6).toFixed(0)}MB  ${k.slice(0, 230)}`).join('\n'));
  };
  await page.waitForTimeout(8000); await prof('race 8-14s');
  await page.waitForTimeout(16000); await prof('race 30-36s');
  await browser.close();
})();
