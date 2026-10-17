const assert=require('node:assert/strict');
const {openCity}=require('./city_browser.cjs');
(async()=>{
 const {browser,page,errors,data,ready,click}=await openCity();
 try {
  let drained=false;
  for(let frame=0;frame<900;frame++) {
   const state=JSON.parse((await data()).streetJunction||'{}');
   if(state.bodies) {
    const entries=Object.entries(state.bodies);
    assert.equal(entries.length,3);
    let inside=0;
    for(const [id,a] of entries) {
     if((id==='branch'?a.y>290.1:a.x>780.1)&&a.x<890) inside++;
     for(const [other,b] of entries) {
      if(id===other) continue;
      assert.ok(Math.hypot(a.x-b.x,a.y-b.y)>=31,'Native junction bodies must remain separated');
      if(a.y>=349.9&&b.y>=349.9) assert.ok(Math.abs(a.x-b.x)>=41.8,'Shared-lane headway');
     }
    }
    assert.ok(inside<=1,'Only one conflicting approach may occupy the box');
    if(state.bodies.following.x>925.8&&state.bodies.branch.x>967.8&&!state.owner) {
     assert.deepEqual(state.admitted,['main','branch','following']);drained=true;break;
    }
   }
   await page.waitForTimeout(50);
  }
  assert.ok(drained,'Finite native queue must drain');
  await click('settings');await click('save');await page.waitForTimeout(3000);
  console.log('JUNCTION_SAVED',JSON.stringify({notice:(await data()).sandboxNotice,bodies:JSON.parse((await data()).streetJunction)}));
  const before=JSON.parse((await data()).streetJunction).bodies;
  await page.reload();await ready();await click('settings');await click('load');
  console.log('JUNCTION_LOADED',JSON.stringify({notice:(await data()).sandboxNotice,bodies:JSON.parse((await data()).streetJunction)}));
  await page.waitForFunction(()=>JSON.parse(document.documentElement.dataset.streetJunction||'{}').bodies?.following.x>900);
  const after=JSON.parse((await data()).streetJunction).bodies;
  for(const id of Object.keys(before)) assert.ok(Math.hypot(after[id].x-before[id].x,after[id].y-before[id].y)<2);
  assert.deepEqual(errors,[]);
  console.log('WEB_JUNCTION_TRAFFIC_PASS actual exported bodies, FIFO admission, conflict exclusion, headway, queue drain and saved positions');
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
