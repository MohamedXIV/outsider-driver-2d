const assert = require('node:assert/strict');
const {openCity} = require('./city_browser.cjs');

(async () => {
  const {browser,page,data,ready,click,shot,errors} = await openCity();
  try {
    await page.keyboard.press('F3');
    await page.waitForFunction(() => document.documentElement.dataset.playerMode === 'false');
    const first = await data(), point = JSON.parse(first.streetNewSeedPoint);
    const box = await page.locator('canvas').boundingBox(), viewport=JSON.parse(first.playerViewport);
    await page.mouse.click(box.x+point[0]*box.width/viewport[0],box.y+point[1]*box.height/viewport[1]);
    await page.waitForFunction(() => document.documentElement.dataset.sandboxSeed === '9');
    await page.keyboard.press('F3');
    await page.waitForFunction(() => document.documentElement.dataset.playerMode === 'true');
    await click('requests');
    await click('fare_offer:npc:01:480');
    await click('accept');
    await page.waitForFunction(() => document.documentElement.dataset.playerTravelling === 'true');
    await page.waitForFunction(() => document.documentElement.dataset.playerTravelling === 'false',
      null,{timeout:240000});
    const arrived = await data(), trip=JSON.parse(arrived.alightTrip), events=JSON.parse(arrived.alightEvents);
    assert.equal(arrived.sandboxSettlements,'1');
    assert.equal(arrived.sandboxDistrict,'clinic');
    assert.equal(trip.npc_id,'npc:01');
    assert.equal(trip.trip.site,'clinic:intake');
    assert.equal(events.filter(e=>e.kind==='rider_alight_started'&&e.subject==='npc:01').length,1);
    await shot('web-rider-clinic-entrance');
    await page.waitForFunction(() => {
      const t=JSON.parse(document.documentElement.dataset.alightTrip || '{}').trip;
      return t && t.status==='arrived';
    },null,{timeout:30000});
    assert.equal(JSON.parse((await data()).alightEvents).filter(e=>e.kind==='rider_alight_arrived'&&e.subject==='npc:01').length,1);
    await click('settings');
    await click('save');
    assert.equal((await data()).playerNotice,'Sandbox saved.');
    await page.waitForTimeout(3000);
    await page.reload();await ready();
    await click('settings');await click('load');
    const restored=await data();
    assert.equal(JSON.parse(restored.alightTrip).trip.status,'arrived');
    assert.equal(JSON.parse(restored.alightEvents).filter(e=>e.kind==='rider_alight_arrived'&&e.subject==='npc:01').length,1);
    assert.equal(restored.sandboxSettlements,'1');
    await shot('web-rider-clinic-restored');
    assert.deepEqual(errors,[]);
    console.log('WEB_PASSENGER_ALIGHT_PASS seeded genuine fare, physical clinic onward arrival and saved exactly-once provenance');
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
