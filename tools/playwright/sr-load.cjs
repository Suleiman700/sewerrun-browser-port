const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: false });
  const page = await browser.newPage({ viewport: { width: 1100, height: 820 } });
  const t0 = Date.now(); const ev = [];
  page.on('console', m => { const t = m.text(); if (!/GL Driver|Flash data/.test(t)) ev.push(((Date.now()-t0)/1000).toFixed(1) + 's ' + t.slice(0,120)); });
  page.on('requestfinished', async r => { const s = await r.sizes().catch(()=>({})); ev.push(((Date.now()-t0)/1000).toFixed(1) + 's NET ' + r.url().split('/').pop() + ' ' + ((s.responseBodySize||0)/1e6).toFixed(1) + 'MB'); });
  await page.goto('http://127.0.0.1:8790/');
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Profiler.enable'); await cdp.send('Profiler.setSamplingInterval', { interval: 500 }); await cdp.send('Profiler.start');
  await page.waitForTimeout(30000);
  const { profile } = await cdp.send('Profiler.stop');
  const self = {}; const byId = {}; profile.nodes.forEach(n => byId[n.id] = n);
  profile.samples.forEach((id, i) => { const n = byId[id]; const k = (n.callFrame.functionName || '(anon)').slice(0, 110); self[k] = (self[k] || 0) + (profile.timeDeltas[i] || 0); });
  console.log(ev.join('\n'));
  console.log('--- top CPU (first 30s)');
  console.log(Object.entries(self).sort((a, b) => b[1] - a[1]).slice(0, 18).map(([k, v]) => (v / 1000).toFixed(0) + 'ms ' + k).join('\n'));
  await browser.close();
})();
