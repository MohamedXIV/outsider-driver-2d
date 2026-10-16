const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true,
    args: ['--enable-webgl','--use-gl=angle','--use-angle=swiftshader',
      '--enable-unsafe-swiftshader','--disable-dev-shm-usage'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  const ready = () => page.waitForFunction(() => document.documentElement.dataset.sandboxReady === 'true',
    null, { timeout: 45000 });
  const wait = (fn) => page.waitForFunction(fn, null, { timeout: 18000 });
  const data = () => page.evaluate(() => ({...document.documentElement.dataset}));
  const click = async (key) => {
    const d = await data(); const pt = JSON.parse(d[key]);
    if (!pt || pt[0] <= 0 || pt[1] <= 0) throw new Error('Unavailable hitbox: ' + key);
    await page.mouse.click(pt[0], pt[1]);
  };
  try {
    await page.goto('http://127.0.0.1:8765/index.html', {waitUntil:'domcontentloaded'});
    await ready();
    await wait(() => !!document.documentElement.dataset.sandboxDistrictPoint);
    let d = await data();
    if (d.sandboxSeed !== '8' || JSON.parse(d.sandboxInstalled).join(',') !== 'trade')
      throw new Error('Common is not the free preinstalled language.');
    await click('sandboxOfferTalkPoint');
    await wait(() => document.documentElement.dataset.sandboxDialogue === 'true');
    d = await data();
    if (d.sandboxDialogueUnderstood !== 'false' || d.sandboxSelectedLanguage !== 'local')
      throw new Error('Missing baseline untranslated Local passenger.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-local-uninstalled.png'});
    await click('sandboxCommonPoint');
    await wait(() => document.documentElement.dataset.sandboxCommonRequested === 'true');
    d = await data();
    if (d.sandboxDialogueUnderstood !== 'false')
      throw new Error('Unwilling or unable NPC magically switched to Common.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-common-refused.png'});
    await page.mouse.click(95,610);
    await page.waitForTimeout(2200);
    await page.reload({waitUntil:'domcontentloaded'});
    await ready();
    await page.mouse.click(250,610);
    await wait(() => document.documentElement.dataset.sandboxDialogueIntent === 'restored');
    d = await data();
    if (d.sandboxCommonRequested !== 'true' || d.sandboxDialogueUnderstood !== 'false')
      throw new Error('Refused Common request lost across Web persistent reload.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-common-reloaded.png'});

    // Physical travel button routes through the same charged, timed SandboxWorld.reposition.
    await click('sandboxMarketTravelPoint');
    await wait(() => document.documentElement.dataset.sandboxDistrict === 'market');
    d = await data();
    if (d.sandboxCredits !== '11') throw new Error('Market travel was free or charged incorrectly.');
    if (d.sandboxSelectedLanguage !== 'local') throw new Error('No actual Local market passenger.');
    await click('sandboxOfferTalkPoint');
    await wait(() => document.documentElement.dataset.sandboxDialogue === 'true' &&
      document.documentElement.dataset.sandboxDialogueUnderstood === 'false');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-market-prepurchase.png'});
    await click('sandboxBuyLocalPoint');
    await wait(() => JSON.parse(document.documentElement.dataset.sandboxOwned).includes('local'));
    d = await data();
    if (d.sandboxCredits !== '3' || JSON.parse(d.sandboxInstalled).includes('local') ||
      JSON.parse(d.sandboxMarketStock).local !== 0)
      throw new Error('Market purchase was not physical, priced or inventory-only.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-module-inventory.png'});
    await click('sandboxInstallLocalPoint');
    await wait(() => JSON.parse(document.documentElement.dataset.sandboxInstalled).includes('local') &&
      document.documentElement.dataset.sandboxDialogue === 'false');
    await click('sandboxOfferTalkPoint');
    await wait(() => document.documentElement.dataset.sandboxDialogue === 'true' &&
      document.documentElement.dataset.sandboxDialogueUnderstood === 'true');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-local-installed.png'});
    // Save active contextual Ink BEFORE deciding; replay it after a Chromium reload.
    await page.mouse.click(95,610);
    await page.waitForTimeout(2200);
    await page.reload({waitUntil:'domcontentloaded'});
    await ready();
    await page.mouse.click(250,610);
    await wait(() => document.documentElement.dataset.sandboxDialogueIntent === 'restored' &&
      document.documentElement.dataset.sandboxDialogueUnderstood === 'true');
    d = await data();
    if (d.sandboxCredits !== '3' || !JSON.parse(d.sandboxInstalled).includes('local'))
      throw new Error('Module payment/installation lost after mid-Ink reload.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-installed-restored.png'});
    // Ink choice index 1 = Agree. Use the real post-layout button center.
    await wait(() => {
      const s = document.documentElement.dataset.sandboxInkAcceptPoint;
      if (!s) return false;
      const p = JSON.parse(s); return p[0] > 0 && p[1] > 0;
    });
    await click('sandboxInkAcceptPoint');
    await wait(() => document.documentElement.dataset.sandboxPhase === 'enroute');
    await page.mouse.click(120,557);
    await wait(() => document.documentElement.dataset.sandboxSettlements === '1');
    d = await data();
    if (+d.sandboxCredits <= 3) throw new Error('Fare failed to settle after translation purchase.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-installed-fare.png'});
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('SANDBOX_WEB_PASS: Common preloaded, refused fallback, physical market, inventory-install, translated Ink, Web reload & fare');
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
