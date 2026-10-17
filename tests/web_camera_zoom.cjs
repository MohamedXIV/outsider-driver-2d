const assert = require('node:assert/strict');
const { openCity } = require('./city_browser.cjs');
(async () => {
  const { browser, page, errors, data, click, ready, shot } = await openCity();
  try {
    assert.equal(Number((await data()).playerZoom), 2.6);
    await shot('camera-desktop-close');
    await page.mouse.move(1100, 650);
    await page.mouse.wheel(0, 200);
    await page.waitForTimeout(300);
    assert.equal(Number((await data()).playerZoom), 2.4);
    await page.keyboard.press('-');
    await page.waitForTimeout(200);
    assert.equal(Number((await data()).playerZoom), 2.2);
    await click('settings');
    await click('zoom_out');
    assert.equal(Number((await data()).playerZoom), 2);
    await shot('camera-desktop-wide');
    await click('save');
    await page.waitForTimeout(3000);
    await page.reload(); await ready();
    await click('settings'); await click('load');
    assert.equal(Number((await data()).playerZoom), 2);
    await page.setViewportSize({width:720,height:900});
    await page.waitForTimeout(500);
    await click('zoom_in');
    assert.equal(Number((await data()).playerZoom), 2.2);
    await shot('camera-narrow-wide');
    await click('zoom_reset');
    assert.equal(Number((await data()).playerZoom), 2.6);
    await shot('camera-narrow-close');
    assert.deepEqual(errors, []);
    console.log('WEB_CAMERA_PASS wheel keyboard touch save reload desktop narrow');
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exitCode=1;});
