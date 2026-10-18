const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: false });
  const page = await browser.newPage({ viewport: { width: 1100, height: 820 } });
  await page.addInitScript(() => { const o = CanvasRenderingContext2D.prototype.getImageData; window.__gid = { n: 0, ms: 0, sizes: {} }; CanvasRenderingContext2D.prototype.getImageData = function (...a) { const t = performance.now(); const r = o.apply(this, a); window.__gid.n++; window.__gid.ms += performance.now() - t; const k = a[2] + "x" + a[3]; window.__gid.sizes[k] = (window.__gid.sizes[k] || 0) + 1; return r; }; });
  await page.goto('http://127.0.0.1:' + (process.argv[2] || '8790') + '/');
  await page.waitForSelector('#loading', { state: 'detached', timeout: 60000 });
  await page.waitForTimeout(2000);
  await page.mouse.click(38 + 510, 26 + 550); await page.waitForTimeout(5000);
  await page.mouse.click(38 + 768, 26 + 589); await page.waitForTimeout(12000);
  // record frame deltas + long tasks
  await page.evaluate(() => {
    window.__d = []; window.__lt = []; let last = performance.now();
    const f = (t) => { window.__d.push([t, t - last]); last = t; requestAnimationFrame(f); }; requestAnimationFrame(f);
    new PerformanceObserver(l => l.getEntries().forEach(e => window.__lt.push([e.startTime, e.duration]))).observe({ entryTypes: ['longtask'] });
  });
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Profiler.enable'); await cdp.send('Profiler.setSamplingInterval', { interval: 200 }); await cdp.send('Profiler.start');
  // steer around a bit
  for (let i = 0; i < 10; i++) { await page.keyboard.down(i % 2 ? 'ArrowLeft' : 'ArrowRight'); await page.waitForTimeout(1000); await page.keyboard.up(i % 2 ? 'ArrowLeft' : 'ArrowRight'); await page.waitForTimeout(1000); }
  const { profile } = await cdp.send("Profiler.stop");
  console.log("GID", JSON.stringify(await page.evaluate(() => window.__gid)), "tempo", await page.evaluate(() => window.__dirplayerFrameTempo));
  const { d, lt } = await page.evaluate(() => ({ d: window.__d, lt: window.__lt }));
  const deltas = d.map(x => x[1]).slice(1).sort((a, b) => a - b);
  const pct = p => deltas[Math.floor(deltas.length * p)].toFixed(1);
  console.log(`frames ${deltas.length} in 20s | median ${pct(0.5)}ms p95 ${pct(0.95)}ms p99 ${pct(0.99)}ms max ${deltas[deltas.length-1].toFixed(0)}ms | >50ms: ${deltas.filter(x=>x>50).length} | >100ms: ${deltas.filter(x=>x>100).length}`);
  console.log('long tasks:', lt.length, 'durations:', lt.map(x => x[1].toFixed(0)).join(',').slice(0, 300));
  const self = {}; const byId = {}; profile.nodes.forEach(n => byId[n.id] = n);
  profile.samples.forEach((id, i) => { const n = byId[id]; const k = (n.callFrame.functionName || '(anon)').slice(0, 90); self[k] = (self[k] || 0) + (profile.timeDeltas[i] || 0); });
  console.log(Object.entries(self).sort((a, b) => b[1] - a[1]).slice(0, 14).map(([k, v]) => (v / 1000).toFixed(0) + 'ms ' + k).join('\n'));
  await page.screenshot({ path: './shots/lag.png' });
  await browser.close();
})();
