const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--enable-webgl','--use-gl=angle',
  '--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
 const page=await browser.newPage({viewport:{width:1280,height:720}});
 const errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 try {
  await page.goto('http://127.0.0.1:8765/index.html',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxReady==='true',null,{timeout:45000});
  if(await page.evaluate(()=>document.documentElement.dataset.sandboxPeerContacts)!=='0')
   throw new Error('Contact existed before first physical meeting.');
  await page.mouse.click(1137,354); // actual Godot Observer +6h button, 1280x720
  await page.waitForFunction(()=>{
   const d=document.documentElement.dataset;
   return +d.sandboxPeerContacts>0 && +d.sandboxPeerFacts>0 &&
     d.sandboxPeerLast.includes('met');
  },null,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/peer-contacts-web.png'});
  const before=await page.evaluate(()=>{
   const d=document.documentElement.dataset;
   return {contacts:d.sandboxPeerContacts,facts:d.sandboxPeerFacts};
  });
  await page.mouse.click(95,610);
  await page.waitForTimeout(2200);
  await page.reload({waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxReady==='true',null,{timeout:45000});
  await page.mouse.click(250,610);
  await page.waitForFunction(expected=>{
   const d=document.documentElement.dataset;
   return d.sandboxPeerContacts===expected.contacts && d.sandboxPeerFacts===expected.facts;
  },before,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/peer-restored-web.png'});
  if(errors.length)throw new Error(errors.join('\n'));
  console.log('SANDBOX_PEER_WEB_PASS: physical co-presence, actual social facts and persisted observation');
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
