const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: false });
  const page = await browser.newPage({ viewport: { width: 1100, height: 820 } });
  const logs = [];
  page.on('console', m => { const t = m.text(); if (t.startsWith('--') || /error|Error/.test(t)) logs.push(t.slice(0, 300)); });
  await page.goto('http://127.0.0.1:8791/');
  await page.waitForSelector('#loading', { state: 'detached', timeout: 60000 });
  await page.waitForTimeout(8000);
  await page.mouse.click(38 + 510, 26 + 550); await page.waitForTimeout(5000);
  await page.mouse.click(38 + 768, 26 + 589); await page.waitForTimeout(20000);
  const ev = async (cmd, wait = 400) => { logs.push(">> " + cmd.slice(0, 60)); await page.evaluate(c => window.DirPlayerDebug.eval_command(c), cmd); await page.waitForTimeout(wait); };
  const I = 'sprite(2).scriptInstanceList[2]';
  await ev(`put ${I}.pWeapon.type`);

  await ev(`put gGame.mode && gGame.challenge`);
  // give player 1 a mortar using an existing pickup icon
  await ev(`gTmpI = 1`);
  await ev(`put "mortar idx" && gTmpI`);
  await ev(`gTmpIcon = ${I}.pWeapon.icon[gTmpI]`);
  await ev(`gTmpIcon.transform = transform()`);
  await ev(`${I}.pBoarder[1].player.addChild(gTmpIcon, #preserveParent)`);
  await ev(`gTmpIcon.translate(0, 750, 0)`);
  await ev(`${I}.pBoarder[1].icon = gTmpIcon`);
  await ev(`${I}.pBoarder[1].weapon = #mortar`);
  await ev(`put "player" && ${I}.pBoarder[1].player.worldPosition && "icon" && gTmpIcon.worldPosition`);
  await page.screenshot({ path: process.argv[2] + '/bomb0.png' });
  await ev(`put "models before" && sprite(2).member.model.count && sprite(2).member.modelResource.count`);
  await page.keyboard.press('Space');
  for (let k = 1; k <= 40; k++) {
    await ev(`put "t${k}"`, 0);
    await ev(`put gTimeFactor`, 0);
    await ev(`put ${I}.pCam.mode`, 0);
    await ev(`put ${I}.pBoarder[1].crash`, 0);
    await ev(`put sound(1).volume`, 0);
    await ev(`put sound(2).volume`, 0);
    await ev(`put gPausedMusicState`, 300);
  }
  await ev(`put "models after" && sprite(2).member.model.count && sprite(2).member.modelResource.count`);
  await page.screenshot({ path: process.argv[2] + '/bomb2.png' });
  console.log(logs.join('\n'));
  await browser.close();
})();
