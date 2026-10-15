const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
 const page=await browser.newPage({viewport:{width:1280,height:720}});
 const errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 try{
  await page.goto('http://127.0.0.1:8765/index.html',{waitUntil:'domcontentloaded'});
  const ready=()=>page.waitForFunction(()=>document.documentElement.dataset.sandboxReady==='true',null,{timeout:45000});
  await ready();
  if(await page.evaluate(()=>document.documentElement.dataset.sandboxKnownCabs)!=='0')
   throw new Error('Unknown driver is incorrectly recognized.');
  await page.mouse.click(90,455); // Accept first real local systemic demand.
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxPhase==='enroute',null,{timeout:15000});
  for(let i=0;i<12;i++){
   if(await page.evaluate(()=>document.documentElement.dataset.sandboxPhase==='seeking'))break;
   await page.mouse.click(90,557);
  }
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxKnownCabs==='1' && document.documentElement.dataset.sandboxSettlements==='1',null,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/driver-remembered-web.png'});
  let index=-1;
  for(let i=0;i<60;i++){
   index=+await page.evaluate(()=>document.documentElement.dataset.sandboxReturningIndex);
   if(index>=0)break;
   await page.mouse.click(90,557); // Real independent time and offers
  }
  if(index<0)throw new Error('No accessible repeat request after real fare.');
  await page.mouse.click(125,176+index*24);
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxSelectedRecognizes==='true',null,{timeout:15000});
  await page.mouse.click(336,455);
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxDialogueRecognizes==='true',null,{timeout:15000});
  const text=await page.evaluate(()=>document.documentElement.dataset.sandboxDialogueText);
  if(!text.includes('recognizes your taxi')||!text.includes("Rru'ka"))
   throw new Error('Missing grounded alien return line or magical translation.');
  await page.screenshot({path:'/tmp/od2d-ink-evidence/driver-returning-web.png'});
  await page.mouse.click(95,610);
  await page.waitForTimeout(2200);
  await page.reload({waitUntil:'domcontentloaded'});
  await ready();
  await page.mouse.click(250,610);
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxDialogueRecognizes==='true',null,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/driver-reloaded-web.png'});
  if(errors.length)throw new Error(errors.join('\n'));
  console.log('SANDBOX_DRIVER_WEB_PASS: real returning NPC, alien dialogue, witnessed memory and reload');
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
