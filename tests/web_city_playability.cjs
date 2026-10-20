const assert = require('node:assert/strict');
const { openCity } = require('./city_browser.cjs');

(async () => {
  const { browser, page, errors, data, ready, click, shot } = await openCity();
  try {
    assert.equal((await data()).playerMode, 'true');
    await shot('web-default-player');
    await click('talk');
    assert.equal((await data()).sandboxDialogueUnderstood, 'false');
    await shot('web-player-dialogue');
    await click('common');
    await page.waitForTimeout(1000);
    assert.equal((await data()).sandboxDialogueUnderstood, 'true');
    await click('choice_1');
    await page.waitForFunction(() => document.documentElement.dataset.playerTravelling === 'true');
    await click('talk');
    await shot('web-player-travel');
    await click('settings');
    await click('save');
    assert.equal((await data()).playerNotice, 'Sandbox saved.');
    await page.waitForTimeout(3000); // Godot's asynchronous IndexedDB flush.
    await page.reload();
    await ready();
    await click('settings');
    await click('load');
    assert.match((await data()).playerNotice, /restored/);
    assert.equal((await data()).playerTravelling, 'true');
    await click('requests');
    await page.waitForFunction(() => document.documentElement.dataset.playerTravelling === 'false',
      null, { timeout: 120000 });
    assert.equal((await data()).sandboxSettlements, '1');
    assert.ok(JSON.parse((await data()).playerActions).choice_2, 'Arrival keeps the Ink exit accessible');
    await shot('web-player-arrival');
    await click('choice_2');
    await page.keyboard.press('F3');
    await page.waitForFunction(() => document.documentElement.dataset.playerMode === 'false');
    await shot('web-debug');
    await page.keyboard.press('F3');
    await page.waitForFunction(() => document.documentElement.dataset.playerMode === 'true');
    await click('settings');
    await click('arabic');
    await shot('web-player-arabic');
    await click('english');
    await click('gear');
    await click('gps');
    await click('buy_local');
    await click('install_local');
    await click('buy_cant');
    await click('install_cant');
    await click('ar_buy');
    await click('ar_wear');
    const equipped = await data();
    assert.deepEqual(JSON.parse(equipped.sandboxInstalled), ['trade', 'local', 'cant']);
    assert.equal(equipped.sandboxAREquipped, 'true');
    assert.equal(equipped.sandboxCredits, '3');
    await shot('web-gear-fitted');
    await click('gear'); // Real tab reselect returns to top, unlike passive refresh.
    await shot('web-gear');
    await page.setViewportSize({ width: 720, height: 900 });
    await page.waitForFunction(() => JSON.parse(document.documentElement.dataset.playerViewport)[0] === 720);
    await click('settings');
    await click('arabic');
    await click('motion');
    await shot('web-small-arabic');
    assert.deepEqual(errors, []);
    console.log('WEB_PLAYER_PASS: live fare, Ink, reload, arrival, modes, physical market, modules, AR, scrolling, narrow Arabic');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
