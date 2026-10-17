const { chromium } = require('playwright');
const fs = require('node:fs');

async function openCity() {
  fs.mkdirSync('/tmp/od2d-city-evidence', { recursive: true });
  const browser = await chromium.launch({ headless: true, args: [
    '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--no-sandbox'
  ] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  const data = () => page.evaluate(() => ({ ...document.documentElement.dataset }));
  const ready = () => page.waitForFunction(() => document.documentElement.dataset.playerActions,
    null, { timeout: 60000 });
  const click = async id => {
    for (let attempt = 0; attempt < 12; attempt++) {
      const d = await data();
      const point = JSON.parse(d.playerActions)[id];
      if (!point || point.disabled) throw Error('No active Player action: ' + id);
      const viewport = JSON.parse(d.playerViewport);
      const canvas = await page.locator('canvas').boundingBox();
      const isTab = ['requests', 'map', 'gear', 'contacts', 'settings'].includes(id);
      const clipTop = point.clipTop ?? 145;
      const clipBottom = Math.min(point.clipBottom ?? viewport[1] - 30, viewport[1] - 30);
      if (!isTab && (point.y > clipBottom - 2 || point.y < clipTop + 2)) {
        await page.mouse.move(canvas.x + 180 * canvas.width / viewport[0],
          canvas.y + (clipTop + clipBottom) / 2 * canvas.height / viewport[1]);
        await page.mouse.wheel(0, point.y > clipBottom - 2 ? 220 : -220);
        await page.waitForTimeout(150);
        continue;
      }
      await page.mouse.click(canvas.x + point.x * canvas.width / viewport[0],
        canvas.y + point.y * canvas.height / viewport[1]);
      await page.waitForFunction(previous => Number(document.documentElement.dataset.playerActionSerial) > previous, Number(d.playerActionSerial));
      if (isTab) await page.waitForFunction(tab => document.documentElement.dataset.playerTab === tab, id);
      if (id === 'english' || id === 'arabic') await page.waitForFunction(locale =>
        document.documentElement.dataset.playerLocale === locale, id === 'arabic' ? 'ar' : 'en');
      return;
    }
    throw Error('Could not scroll to Player action: ' + id);
  };
  const shot = name => page.screenshot({ path: '/tmp/od2d-city-evidence/' + name + '.png' });
  await page.goto((process.env.OD2D_WEB_URL||'http://127.0.0.1:8765/index.html'));
  await ready();
  return { browser, page, errors, data, ready, click, shot };
}
module.exports = { openCity };
