const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--enable-webgl',
 '--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
 const page=await browser.newPage({viewport:{width:1280,height:720}});
 const errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 try {
  await page.goto('http://127.0.0.1:8765/index.html',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxReady==='true',null,{timeout:45000});
  await page.mouse.click(485,400); // existing real Depot map pin
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxRouteWaypoint==='depot',
    null,{timeout:15000});
  await page.mouse.click(110,452); // accept real generated Docks->Shelter offer
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxRiderStatus==='pending' &&
    document.documentElement.dataset.sandboxRiderVia==='market',null,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/rider-request-web.png'});
  const honor = JSON.parse(await page.evaluate(() => document.documentElement.dataset.sandboxHonorRiderPoint));
  if (!Array.isArray(honor) || honor.some(n => !Number.isFinite(n) || n <= 0))
    throw new Error('Missing real Godot Honor rider control bounds: ' + JSON.stringify(honor));
  await page.mouse.click(honor[0], honor[1]); // actual resized RoutePanel choice
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxRiderStatus==='accepted' &&
    document.documentElement.dataset.sandboxPendingRoute.includes('market'),null,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/rider-queued-web.png'});
  await page.mouse.click(95,610); // save queued choice
  await page.waitForTimeout(2200);
  await page.reload({waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxReady==='true',null,{timeout:45000});
  await page.mouse.click(250,610); // reload queued route + NPC answer
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxRiderStatus==='accepted' &&
    document.documentElement.dataset.sandboxPendingRoute.includes('market'),null,{timeout:15000});
  await page.mouse.click(120,557); // +20m: at depot, then docks (real physical edge)
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxRouteNodes.includes('market') &&
    document.documentElement.dataset.sandboxRouteNodes.includes('docks') &&
    document.documentElement.dataset.sandboxDistrict==='docks',null,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/rider-junction-web.png'});
  await page.mouse.click(120,557); // market then shelter
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxPhase==='seeking' &&
    document.documentElement.dataset.sandboxSettlements==='1' &&
    document.documentElement.dataset.sandboxDistrict==='shelter',null,{timeout:15000});
  if(errors.length)throw new Error(errors.join('\n'));
  await page.screenshot({path:'/tmp/od2d-ink-evidence/rider-arrived-web.png'});
  console.log('SANDBOX_REROUTE_WEB_PASS: passenger choice, physical next-junction reroute, saved fare');
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
