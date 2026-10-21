// Matched-host diagnostic only: do not alter the established Web acceptance.
// Drive the SAME genuine 88-world-minute passenger service route on both SHAs.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { openCity } = require(process.env.OD2D_BROWSER_MODULE);
(async () => {
  const {browser,page,data,ready,click,shot,errors}=await openCity();
  const name=process.env.OD2D_PROBE_LABEL || 'unlabelled';
  const started=performance.now();
  let timer=null;
  let samples=[];
  let result=null;
  const record=async()=> {
    const d=await data();
    const pose=JSON.parse(d.streetTaxiPose||'{}');
    const sample={
      seconds:Math.round((performance.now()-started)/1000),
      minute:Number(d.sandboxMinute),
      remaining:Number(d.playerRouteMinutes),
      travelling:d.playerTravelling==='true',
      segment:Number(pose.segment??-1),
      edgeElapsed:Number(pose.elapsed??-1),
      hold:String(pose.hold||''),
      taxiVisible:pose.render||[]
    };
    samples.push(sample);
    console.log('MATCHED_ROUTE_PROGRESS',name,JSON.stringify(sample));
    return sample;
  };
  try {
    await click('talk');
    await click('common');
    await page.waitForTimeout(1000);
    await click('map');
    await click('via');
    await page.keyboard.press('Home');
    for(let i=0;i<24;i++) await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter');
    await page.waitForFunction(()=>Boolean(document.documentElement.dataset.playerPlannedVia));
    assert.equal((await data()).playerPlannedVia,'east_ramp_foot');
    await click('plan_fare');
    assert.equal((await data()).sandboxRouteWaypoint,'east_ramp_foot');
    await click('choice_1');
    await page.waitForFunction(()=>document.documentElement.dataset.playerTravelling==='true');
    const long=await data();
    const metrics={
      plannedMinutes:Number(long.playerRouteMinutes),
      plannedMetres:Number(long.playerRouteMetres),
      nodes:long.sandboxRouteNodes.split(','),
      initialWorldMinute:Number(long.sandboxMinute)
    };
    for (const node of ['east_service','east_ramp_foot','east_ramp_top'])
      assert.ok(metrics.nodes.includes(node),'Route must include service ascent: '+node);
    await click('talk');
    await click('settings');
    await click('save');
    assert.equal((await data()).playerNotice,'Sandbox saved.');
    await page.waitForTimeout(3000);
    await page.reload();
    await ready();
    await click('settings');
    await click('load');
    await page.waitForFunction(()=>document.documentElement.dataset.playerTravelling==='true');
    assert.equal((await data()).sandboxRouteNodes,metrics.nodes.join(','));
    assert.equal((await data()).sandboxSettlements,'0');
    await click('requests');
    await record();
    const routeStart=performance.now();
    timer=setInterval(()=>{record().catch(err=>console.error('PROBE_SAMPLE_ERROR',String(err)))},10000);
    await page.waitForFunction(()=>document.documentElement.dataset.playerTravelling==='false',
      null,{timeout:900000});
    clearInterval(timer);timer=null;
    const final=await record();
    const d=await data();
    assert.equal(d.sandboxSettlements,'1','A completed authentic passenger fare settles exactly once');
    assert.deepEqual(errors,[]);
    await shot('matched-long-route-'+name);
    result={name,base:process.env.OD2D_SHA,metrics,
      travelWallSeconds:(performance.now()-routeStart)/1000,
      totalWallSeconds:(performance.now()-started)/1000,
      final,settlements:Number(d.sandboxSettlements),samples,pass:true};
    console.log('MATCHED_ROUTE_PASS',name,JSON.stringify({
      sha:result.base,travelWallSeconds:result.travelWallSeconds,
      totalWallSeconds:result.totalWallSeconds,
      minutes:metrics.plannedMinutes,metres:metrics.plannedMetres,
      sampleCount:samples.length
    }));
  } catch(err) {
    console.error('MATCHED_ROUTE_FAIL',name,String(err));
    const d=await data().catch(()=>({}));
    result={name,base:process.env.OD2D_SHA,
      totalWallSeconds:(performance.now()-started)/1000,
      error:String(err),lastData:{minute:d.sandboxMinute,remaining:d.playerRouteMinutes,
        travelling:d.playerTravelling,settlements:d.sandboxSettlements},
      samples,pass:false};
    throw err;
  } finally {
    if(timer)clearInterval(timer);
    fs.writeFileSync(process.env.OD2D_PROBE_JSON,JSON.stringify(result||{name,samples,pass:false},null,2));
    await browser.close();
  }
})().catch(err=>{console.error(err);process.exitCode=1;});
