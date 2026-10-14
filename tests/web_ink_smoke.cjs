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
    await page.mouse.click(170, 470);
    await page.waitForFunction(() => document.documentElement.dataset.inkChoice === 'selected',
      null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/ink-web-choice.png' });
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('P1_INK_WEB_PASS: real Godot Web Ink story and player choice');
  } finally {
    await browser.close();
  }
})().catch(e => { console.error(e); process.exitCode = 1; });
