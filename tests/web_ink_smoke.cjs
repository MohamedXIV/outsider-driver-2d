const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({
    headless: true,
    args: ['--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader',
      '--enable-unsafe-swiftshader', '--disable-dev-shm-usage']
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  try {
    await page.goto('http://127.0.0.1:8765/index.html', { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => document.documentElement.dataset.inkReady === 'true',
      null, { timeout: 60000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/ink-web-opening.png' });
    await page.waitForFunction(() => !!document.documentElement.dataset.cabinFrame,
      null, { timeout: 15000 });
    const initialFrame = await page.evaluate(() => document.documentElement.dataset.cabinFrame);
    await page.mouse.click(1030, 119);
    await page.waitForFunction(expected => document.documentElement.dataset.cabinFrame !== expected,
      initialFrame, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/avatar-only.png' });
    await page.mouse.click(1030, 119);
    await page.waitForFunction(expected => document.documentElement.dataset.cabinFrame === expected,
      initialFrame, { timeout: 15000 });
    await page.mouse.click(170, 470);
    await page.waitForFunction(() => document.documentElement.dataset.inkChoice === 'selected',
      null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/ink-web-choice.png' });
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('P1_PRESENTATION_WEB_PASS: Ink choice and persistent cabin-frame setting toggled');
  } finally {
    await browser.close();
  }
})().catch(e => { console.error(e); process.exitCode = 1; });
