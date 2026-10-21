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
    await page.waitForFunction(()=>document.documentElement.dataset.streetSeed==='29'&&JSON.parse(document.documentElement.dataset.streetActors||'[]').length===2);
    const initial=await actors();
    assert.deepEqual(initial.map(a=>a.id).sort(),['npc:04','npc:08']);
    assert.equal((await data()).streetPopulation,'9');
    assert.ok(initial.every(a=>a.native));
    await page.waitForFunction(initial=>JSON.parse(document.documentElement.dataset.streetActors||'[]').some(a=>{
      const start=initial.find(p=>p.id===a.id);return start&&a.trip.status==='walking'&&Math.hypot(a.x-start.x,a.y-start.y)>5;
    }),initial);
    // Save immediately through the real visible Debug control. Screenshots
    // and UI navigation must not consume the short live-walk save window.
    const d=await data(),point=JSON.parse(d.debugControls).save;
    const box=await page.locator('canvas').boundingBox(),viewport=JSON.parse(d.playerViewport);
    await page.mouse.click(box.x+point.x*box.width/viewport[0],box.y+point.y*box.height/viewport[1]);
    await page.waitForFunction(previous=>Number(document.documentElement.dataset.debugActionSerial)>previous,Number(d.debugActionSerial));
    assert.equal((await data()).debugNotice,'Sandbox saved.');
    const saved=JSON.parse((await data()).streetSavedActors);
    assert.ok(saved.some(a=>a.trip.status==='walking'),'Save must exercise live native movement');
    assert.ok(saved.some(a=>{const start=initial.find(p=>p.id===a.id);return Math.hypot(a.x-start.x,a.y-start.y)>5;}));
    await page.keyboard.press('F3');
    await page.waitForFunction(()=>document.documentElement.dataset.playerMode==='true');
    await shot('multi-two-residents-native');
    await page.waitForTimeout(3000);
    await page.reload();await ready();
    await click('settings');await click('load');
    await page.waitForFunction(()=>document.documentElement.dataset.sandboxSeed==='29'&&JSON.parse(document.documentElement.dataset.streetActors||'[]').length===2);
    const restored=JSON.parse((await data()).streetRestoredActors);
    assert.deepEqual(restored.map(a=>a.id).sort(),['npc:04','npc:08']);
    assert.equal((await data()).streetPopulation,'9');
    for(const a of restored) {
      const old=saved.find(b=>b.id===a.id);
      assert.equal(a.trip.started,old.trip.started);
      assert.ok(Math.hypot(a.x-old.x,a.y-old.y)<.1,'Restored actor must retain its own saved position at the load boundary');
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
    assert.ok(end.some(a=>a.x>560),'A genuine resident must physically reach the adjacent authored block');
    assert.ok(events.filter(e=>e.kind==='local_pedestrian_departed').every(e=>e.minute>480),'Departure must originate in ordinary World ticks');
    require('node:fs').writeFileSync('/tmp/od2d-city-evidence/living-streets-ledger.json',JSON.stringify({seed:29,saved,restored,end,events},null,2));
    assert.ok(Math.hypot(end[0].x-end[1].x,end[0].y-end[1].y)>=14);
    await shot('multi-two-residents-arrived');
    assert.deepEqual(errors,[]);
    console.log('WEB_TWO_RESIDENTS_PASS natural seed29 identities, independent native actors, live save/reload, narrow viewport and exactly-once arrivals');
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
