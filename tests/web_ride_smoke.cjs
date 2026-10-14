const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true,
    args: ['--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader',
      '--enable-unsafe-swiftshader', '--disable-dev-shm-usage'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  const check = async (condition, reason) => {
    if (!(await page.evaluate(condition))) throw new Error(reason);
  };
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  const phase = async value => page.waitForFunction(v => document.documentElement.dataset.ridePhase === v,
    value, { timeout: 60000 });
  try {
    await page.goto('http://127.0.0.1:8765/index.html', { waitUntil: 'domcontentloaded' });
    await phase('waiting');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/ride-before-pickup.png' });
    await page.mouse.click(615, 614); // Pick up visitor
    await page.waitForFunction(() => document.documentElement.dataset.inkReady === 'true' &&
      document.documentElement.dataset.ridePhase === 'traveling', null, { timeout: 15000 });
    await check(() => document.documentElement.dataset.choiceCount === '2', 'Missing original Ink choices');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/ride-with-passenger.png' });
    // Save with an unanswered choice; prove exact playable recovery after a browser reload.
    await page.mouse.click(570, 615); // Save (pickup button disappears during travel)
    await page.waitForTimeout(2200); // Allow Godot Web persistent filesystem to flush.
    await page.reload({ waitUntil: 'domcontentloaded' });
    await phase('waiting');
    await page.mouse.click(743, 615); // Load
    await phase('traveling');
    await check(() => document.documentElement.dataset.choiceCount === '2' &&
      document.documentElement.dataset.rideCredits === '0', 'Unanswered Ink frame or wallet lost on reload');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/restored-midride.png' });
    await page.mouse.click(170, 467); // Authored first Ink response
    await page.waitForFunction(() => document.documentElement.dataset.rideFacts === '1',
      null, { timeout: 15000 });
    await check(() => document.documentElement.dataset.rideCredits === '0', 'Fare paid before dropoff');
    await phase('arrived');
    const before = Number(await page.evaluate(() => document.documentElement.dataset.rideClock));
    await page.waitForTimeout(1200);
    const after = Number(await page.evaluate(() => document.documentElement.dataset.rideClock));
    if (!(after > before)) throw new Error('World time froze at arrival');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/arrived.png' });
    await page.mouse.click(614, 614); // Explicitly enter authored arrival scene
    await page.waitForFunction(() => document.documentElement.dataset.arrivalOffer === 'true' &&
      document.documentElement.dataset.choiceCount === '2', null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/arrival-choices.png' });
    await page.mouse.click(170, 467); // We've arrived (authored Ink ending)
    await phase('completed');
    await check(() => document.documentElement.dataset.rideCredits === '18' &&
      document.documentElement.dataset.rideFacts === '1' &&
      document.documentElement.dataset.rideSuspicion === '0' &&
      document.documentElement.dataset.passengerVisible === 'false' &&
      document.documentElement.dataset.choiceVisible === 'false', 'Completed ride UI or consequences wrong');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/after-dropoff.png' });
    await page.waitForTimeout(2200);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await phase('waiting');
    await page.mouse.click(743, 615); // Restore completed ride
    await phase('completed');
    await check(() => document.documentElement.dataset.rideCredits === '18' &&
      document.documentElement.dataset.rideFacts === '1' &&
      document.documentElement.dataset.rideSuspicion === '0' &&
      document.documentElement.dataset.passengerVisible === 'false', 'Completed consequences failed browser persistence');
    await page.mouse.click(743, 615); // Second Load is idempotent
    await phase('completed');
    await check(() => document.documentElement.dataset.rideCredits === '18', 'Duplicate payment after loading');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/restored-completed.png' });
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('P1_RIDE_WEB_PASS: unfinished Ink recovered, authored arrival, ticking clock, single fare and persistent consequences');
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
