const assert = require('node:assert/strict');
const { openCity } = require('./city_browser.cjs');

(async () => {
  const { browser, page, data, ready, click, shot, errors } = await openCity();
  try {
    // The real default Seed-8 garage fare is an independently generated
    // street offer; no test command or manufactured passenger is used.
    await click('talk');
    await click('common');
    await page.waitForFunction(() => document.documentElement.dataset.sandboxDialogueUnderstood === 'true');
    await click('choice_1');
    await page.waitForFunction(() => document.documentElement.dataset.playerTravelling === 'true');
    await click('requests');
    await page.waitForFunction(() =>
      document.documentElement.dataset.playerRiderStatus === 'pending' &&
      !!JSON.parse(document.documentElement.dataset.playerActions || '{}').reply_silent,
      null, { timeout: 120000 });
    const prompt = await data();
    assert.ok(prompt.playerRiderQuestion.length > 3);
    await shot('web-passenger-speaks-first-en');

    // Pending initiative must survive real IndexedDB-backed Save/Reload,
    // without the passenger restarting the same question from the beginning.
    await click('settings');
    await click('save');
    assert.equal((await data()).playerNotice, 'Sandbox saved.');
    await page.waitForTimeout(3000);
    await page.reload(); await ready();
    await click('settings'); await click('load');
    await click('requests');
    await page.waitForFunction(() => document.documentElement.dataset.playerRiderStatus === 'pending');
    assert.equal((await data()).playerRiderQuestion, prompt.playerRiderQuestion);
    await click('settings');
    await click('arabic');
    await click('requests');
    const arabic = await data();
    assert.equal(arabic.playerLocale, 'ar');
    assert.ok(arabic.playerRiderQuestion.length > 3);
    assert.notEqual(arabic.playerRiderQuestion, prompt.playerRiderQuestion);
    await shot('web-passenger-speaks-first-ar');

    // The real player-facing button, not a debug API, dispatches exactly one
    // World event; the question disappears and cannot be repeated.
    await click('reply_silent');
    await page.waitForFunction(() => document.documentElement.dataset.playerRiderStatus === 'answered');
    assert.ok(!JSON.parse((await data()).playerActions).reply_silent);
    await shot('web-passenger-answer-recorded');
    assert.deepEqual(errors, []);
    console.log('WEB_RIDER_INITIATIVE_PASS live seeded passenger speaks first, pending Save/Load, Arabic reply, once-only World response');
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
