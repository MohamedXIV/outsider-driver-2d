const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true,
    args: ['--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader',
      '--enable-unsafe-swiftshader', '--disable-dev-shm-usage'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  try {
    await page.goto('http://127.0.0.1:8765/index.html', { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => document.documentElement.dataset.ridePhase === 'waiting',
      null, { timeout: 60000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/ride-before-pickup.png' });
    await page.mouse.click(615, 614); // Pick up visitor
    await page.waitForFunction(() => document.documentElement.dataset.inkReady === 'true' &&
      document.documentElement.dataset.ridePhase === 'traveling', null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/ride-with-passenger.png' });
    await page.mouse.click(170, 467); // Authored first Ink response
    await page.waitForFunction(() => document.documentElement.dataset.inkChoice === 'selected',
      null, { timeout: 15000 });
    await page.waitForFunction(() => document.documentElement.dataset.ridePhase === 'arrived',
      null, { timeout: 60000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/arrived.png' });
    await page.mouse.click(614, 614); // We've arrived (safe exit)
    await page.waitForFunction(() => document.documentElement.dataset.ridePhase === 'completed',
      null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/after-dropoff.png' });
    // Godot Web saves through user://. Verify persistence across a full reload.
    await page.waitForTimeout(2200);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => document.documentElement.dataset.ridePhase === 'waiting',
      null, { timeout: 60000 });
    await page.mouse.click(743, 615); // Load v1 save
    await page.waitForFunction(() => document.documentElement.dataset.ridePhase === 'completed',
      null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/restored-completed.png' });
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('P1_RIDE_WEB_PASS: pickup, Ink choice, arrival, single dropoff, save and reload restore');
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
