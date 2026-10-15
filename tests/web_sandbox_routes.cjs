const { chromium } = require('playwright');
(async () => {
  const browser=await chromium.launch({headless:true,args:[
    '--enable-webgl','--use-gl=angle','--use-angle=swiftshader',
    '--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  const page=await browser.newPage({viewport:{width:1280,height:720}});
  const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
  try {
    await page.goto('http://127.0.0.1:8765/index.html',{waitUntil:'domcontentloaded'});
    await page.waitForFunction(()=>document.documentElement.dataset.sandboxReady==='true',null,{timeout:45000});
    const initial=await page.evaluate(()=>document.documentElement.dataset.sandboxRoutePreview);
    if(!initial.includes('docks')||!initial.includes('shelter')||!initial.includes('20 min'))
      throw new Error('Initial route preview is not a real connected map-pin route: '+initial);
    await page.screenshot({path:'/tmp/od2d-ink-evidence/route-default-web.png'});
    await page.mouse.click(734,260); // Route panel waypoint selector.
    await page.keyboard.press('End');
    await page.keyboard.press('Enter');
    await page.waitForFunction(()=>{
      const d=document.documentElement.dataset;
      return d.sandboxRouteWaypoint==='depot' && d.sandboxRoutePreview.includes('30 min');
    },null,{timeout:15000});
    await page.screenshot({path:'/tmp/od2d-ink-evidence/route-via-depot-web.png'});
    await page.mouse.click(110,452); // Accepted ride in the DockPanel.
    await page.waitForFunction(()=>{
      const d=document.documentElement.dataset;
      return d.sandboxPhase==='enroute' && d.sandboxRouteNodes.includes('depot');
    },null,{timeout:15000});
    await page.mouse.click(120,557); // +20m, halfway along second segment.
    await page.waitForFunction(()=>document.documentElement.dataset.sandboxRouteElapsed==='10',null,{timeout:15000});
    const transit=await page.evaluate(()=>{
      const d=document.documentElement.dataset;
      return {district:d.sandboxDistrict,segment:d.sandboxRouteSegment,elapsed:d.sandboxRouteElapsed};
    });
    if(transit.district!=='depot'||transit.segment!=='1')
      throw new Error('Taxi did not progress along real route graph '+JSON.stringify(transit));
    await page.screenshot({path:'/tmp/od2d-ink-evidence/route-mid-web.png'});
    await page.mouse.click(95,610); // Save world mid-edge
    await page.waitForTimeout(2200);
    await page.reload({waitUntil:'domcontentloaded'});
    await page.waitForFunction(()=>document.documentElement.dataset.sandboxReady==='true',null,{timeout:45000});
    await page.mouse.click(250,610); // Restore
    await page.waitForFunction(()=>document.documentElement.dataset.sandboxRouteElapsed==='10',null,{timeout:15000});
    await page.mouse.click(120,557);
    await page.waitForFunction(()=>{
      const d=document.documentElement.dataset;
      return d.sandboxPhase==='seeking' && d.sandboxSettlements==='1' && d.sandboxDistrict==='shelter';
    },null,{timeout:15000});
    await page.screenshot({path:'/tmp/od2d-ink-evidence/route-arrived-web.png'});
    if(errors.length)throw new Error(errors.join('\n'));
    console.log('SANDBOX_ROUTES_WEB_PASS: choice, mid-edge travel, save/reload and single fare');
  }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
