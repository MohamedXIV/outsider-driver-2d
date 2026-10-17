const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({
    headless: true,
    args: ['--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader',
      '--enable-unsafe-swiftshader', '--disable-dev-shm-usage']
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  try {
    const response = await page.goto((process.env.OD2D_WEB_URL||'http://127.0.0.1:8765/index.html'),
      { waitUntil: 'domcontentloaded', timeout: 30000 });
    if (!response || !response.ok()) throw new Error('Web page did not respond successfully.');
    await page.locator('canvas').first().waitFor({ timeout: 30000 });
    await page.waitForTimeout(9000);
    await page.screenshot({ path: '/tmp/p0-evidence/web-browser.png' });
    console.log('Browser loaded Godot HTML canvas; screenshot saved.');
    if (errors.length) throw new Error(errors.join('\n'));
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
