const assert = require('node:assert/strict');
const fs = require('node:fs');
const { openCity } = require('./city_browser.cjs');

(async () => {
  const { browser, page, errors, data, click, shot } = await openCity();
  const progress = setInterval(() => data().then(d => console.log('ROUTE_PROGRESS',
    d.sandboxMinute, d.playerRouteMinutes, d.playerTravelling)).catch(() => {}), 10000);
  const sequence = async name => {
    const frames = [];
    for (let frame = 0; frame < 3; frame++) {
      const d = await data();
      const pose = JSON.parse(d.streetTaxiPose);
      assert.equal(pose.id, 'player');
      assert.ok([...pose.world, ...pose.render, pose.heading].every(Number.isFinite));
      assert.equal(d.streetPopulation, '9');
      const previous = frames.at(-1);
      if (previous && pose.hold && previous.hold === pose.hold &&
          previous.segment === pose.segment && previous.elapsed === pose.elapsed) {
        assert.ok(Math.hypot(...pose.render.map((value, i) => value - previous.render[i])) < .01,
          'A World-owned crossing hold must freeze the exported lane pose');
      }
      const actors = JSON.parse(d.actorLifecycle);
      assert.equal(new Set(actors.map(actor => actor.id)).size, actors.length);
      for (const actor of actors) {
        assert.ok([...actor.world, ...actor.render, ...actor.viewport].every(Number.isFinite));
        assert.equal(typeof actor.visible, 'boolean');
      }
      frames.push({ ...pose, actors });
      await shot(`${name}-${frame}`);
      await page.waitForTimeout(100);
    }
    fs.writeFileSync(`/tmp/od2d-city-evidence/${name}.json`, JSON.stringify(frames, null, 2));
  };
  try {
    await click('talk');
    await click('common');
    await page.waitForTimeout(1000);
    await click('map');
    await click('via');
    await page.keyboard.press('Home');
    for (let i = 0; i < 6; i++) await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter');
    // OptionButton selection is published on a deferred Godot frame.
    await page.waitForFunction(() => Boolean(document.documentElement.dataset.playerPlannedVia));
    const selectedVia = (await data()).playerPlannedVia;
    assert.ok(selectedVia);
    await click('plan_fare');
    assert.equal((await data()).sandboxRouteWaypoint, selectedVia);
    await click('choice_1');
    await page.waitForFunction(() => document.documentElement.dataset.playerTravelling === 'true');
    const long = await data();
    assert.ok(long.sandboxRouteNodes.split(',').includes(selectedVia));
    const longMinutes = Number(long.playerRouteMinutes);
    await click('talk');
    await shot('web-long-route');
    await sequence('web-driving-sequence');
    await page.waitForFunction(() => document.documentElement.dataset.playerTravelling === 'false',
      null, { timeout: 240000 });
    await click('choice_2');
    for (let i = 0; i < 60; i++) {
      const actions = JSON.parse((await data()).playerActions);
      if (actions.accept && !actions.accept.disabled) break;
      await click('wait'); // Real player wait command; demand still comes from NPC state.
    }
    await click('talk');
    await click('choice_1');
    await page.waitForFunction(() => document.documentElement.dataset.playerTravelling === 'true');
    const short = await data();
    const shortMinutes = Number(short.playerRouteMinutes);
    assert.ok(shortMinutes > 0 && shortMinutes < longMinutes);
    await click('talk');
    await shot('web-short-route');
    await page.waitForFunction(() => document.documentElement.dataset.playerTravelling === 'false',
      null, { timeout: 180000 });
    assert.equal((await data()).sandboxSettlements, '2');
    await click('choice_2');
    assert.deepEqual(errors, []);
    console.log('WEB_TWO_ROUTES_PASS', JSON.stringify({
      selectedVia, longMinutes, longMetres: long.playerRouteMetres, longNodes: long.sandboxRouteNodes,
      shortMinutes, shortMetres: short.playerRouteMetres, shortNodes: short.sandboxRouteNodes
    }));
  } finally {
    clearInterval(progress);
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
