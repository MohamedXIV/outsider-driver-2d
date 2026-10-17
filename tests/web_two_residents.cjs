const assert=require('node:assert/strict');
const {openCity}=require('./city_browser.cjs');
(async()=>{
  const {browser,page,errors,data,ready,click,shot}=await openCity();
  const actors=async()=>JSON.parse((await data()).streetActors||'[]');
  try {
    await page.keyboard.press('F3');
    await page.waitForFunction(()=>document.documentElement.dataset.playerMode==='false');
    for(let seed=9;seed<=29;seed++) {
      const d=await data(), point=JSON.parse(d.streetNewSeedPoint);
      const box=await page.locator('canvas').boundingBox();
      const viewport=JSON.parse(d.playerViewport);
      await page.mouse.click(box.x+point[0]*box.width/viewport[0],box.y+point[1]*box.height/viewport[1]);
      await page.waitForFunction(expected=>document.documentElement.dataset.sandboxSeed===String(expected),seed);
    }
    await page.waitForFunction(()=>JSON.parse(document.documentElement.dataset.streetActors||'[]').length===2);
    const initial=await actors();
    assert.deepEqual(initial.map(a=>a.id).sort(),['npc:04','npc:08']);
    assert.equal((await data()).streetPopulation,'9');
    assert.ok(initial.every(a=>a.native));
    await page.keyboard.press('F3');
    await page.waitForFunction(()=>document.documentElement.dataset.playerMode==='true');
    await shot('multi-two-residents-native');
    await click('settings');await click('save');
    const saved=await actors();
    assert.ok(saved.some(a=>a.trip.status==='walking'),'Save must exercise live native movement');
    await page.waitForTimeout(3000);
    await page.reload();await ready();
    await click('settings');await click('load');
    await page.waitForFunction(()=>document.documentElement.dataset.sandboxSeed==='29'&&JSON.parse(document.documentElement.dataset.streetActors||'[]').length===2);
    const restored=await actors();
    assert.deepEqual(restored.map(a=>a.id).sort(),['npc:04','npc:08']);
    assert.equal((await data()).streetPopulation,'9');
    for(const a of restored) {
      const old=saved.find(b=>b.id===a.id);
      assert.equal(a.trip.started,old.trip.started);
      assert.ok(Math.hypot(a.x-old.x,a.y-old.y)<65,'Restored actor must retain its own saved position');
    }
    await page.setViewportSize({width:720,height:900});
    await page.waitForFunction(()=>JSON.parse(document.documentElement.dataset.playerViewport)[0]===720);
    await shot('multi-two-residents-restored-narrow');
    await page.waitForFunction(()=>Object.values(JSON.parse(document.documentElement.dataset.streetTrips||'{}')).length===2&&Object.values(JSON.parse(document.documentElement.dataset.streetTrips)).every(t=>t.status==='arrived'),null,{timeout:60000});
    const events=JSON.parse((await data()).streetEvents);
    for(const id of ['npc:04','npc:08']) {
      assert.equal(events.filter(e=>e.kind==='local_pedestrian_departed'&&e.subject===id).length,1);
      assert.equal(events.filter(e=>e.kind==='local_pedestrian_arrived'&&e.subject===id).length,1);
    }
    const end=await actors();
    assert.ok(Math.hypot(end[0].x-end[1].x,end[0].y-end[1].y)>=14);
    await shot('multi-two-residents-arrived');
    assert.deepEqual(errors,[]);
    console.log('WEB_TWO_RESIDENTS_PASS natural seed29 identities, independent native actors, live save/reload, narrow viewport and exactly-once arrivals');
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
