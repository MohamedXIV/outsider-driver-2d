const {chromium} = require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
 const page=await browser.newPage({viewport:{width:1280,height:720}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 const wait=fn=>page.waitForFunction(fn,null,{timeout:18000});
 const d=()=>page.evaluate(()=>({...document.documentElement.dataset}));
 const click=async(key)=>{const v=(await d())[key];if(!v)throw Error('Missing '+key);
  const p=JSON.parse(v); if(p[0]<=0||p[1]<=0)throw Error('Bad button '+key);
  await page.mouse.click(p[0],p[1]);};
 try{
  await page.goto('http://127.0.0.1:8765/index.html',{waitUntil:'domcontentloaded'});
  await wait(()=>document.documentElement.dataset.sandboxReady==='true' &&
   !!document.documentElement.dataset.sandboxARBuyPoint);
  let x=await d();
  if(x.sandboxAROwned!=='false'||x.sandboxAREquipped!=='false'||x.sandboxARHint!=='false')
   throw Error('Fresh save must not grant free AR hints.');
  await click('sandboxStarterGPSPoint');
  await click('sandboxMarketTravelPoint');
  await wait(()=>document.documentElement.dataset.sandboxDistrict==='market');
  await click('sandboxARBuyPoint');
  await wait(()=>document.documentElement.dataset.sandboxAROwned==='true');
  x=await d();
  if(x.sandboxCredits!=='6'||x.sandboxAREquipped!=='false')
   throw Error('Eyewear was free, pre-equipped or not physically sold.');
  await click('sandboxARWearPoint');
  await wait(()=>document.documentElement.dataset.sandboxAREquipped==='true');
  await click('sandboxOfferTalkPoint');
  await wait(()=>document.documentElement.dataset.sandboxDialogue==='true');
  x=await d();
  if(x.sandboxDialogueUnderstood!=='false'||x.sandboxARHint!=='false')
   throw Error('AR guessed hidden untranslated language.');
  await click('sandboxCommonPoint');
  await wait(()=>document.documentElement.dataset.sandboxDialogueUnderstood==='true');
  await click('sandboxInkAskPoint');
  await wait(()=>document.documentElement.dataset.sandboxDialogueIntent==='ask_destination' &&
   document.documentElement.dataset.sandboxARHint==='true');
  await click('sandboxARContextPoint');
  await wait(()=>document.documentElement.dataset.sandboxAROverlay==='true');
  x=await d();
  if(x.sandboxARHintCertainty!=='verified'||!x.sandboxARHintSource.includes('starter:gps') ||
   !x.sandboxARHintText.includes('Source:')||x.sandboxARHintText.includes('human'))
   throw Error('Known AR hint missing provenance or leaked private facts.');
  await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-ar-verified-web.png'});
  await page.keyboard.press('Escape');
  await wait(()=>document.documentElement.dataset.sandboxAROverlay==='false');
  await click('sandboxARContextPoint'); // touch/click can reopen the same sourced note.
  await click('sandboxARClosePoint');
  await wait(()=>document.documentElement.dataset.sandboxAROverlay==='false');
  await click('sandboxARWearPoint');
  await wait(()=>document.documentElement.dataset.sandboxAREquipped==='false' &&
   document.documentElement.dataset.sandboxARHint==='false');
  await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-ar-unworn-web.png'});
  await click('sandboxARWearPoint');
  await wait(()=>document.documentElement.dataset.sandboxARHint==='true');
  await click('sandboxSavePoint');
  await page.waitForTimeout(1900);
  await page.reload({waitUntil:'domcontentloaded'});
  await wait(()=>document.documentElement.dataset.sandboxReady==='true');
  await click('sandboxLoadPoint');
  await wait(()=>document.documentElement.dataset.sandboxAREquipped==='true' &&
   document.documentElement.dataset.sandboxDialogueIntent==='restored');
  x=await d();
  if(x.sandboxCredits!=='6'||x.sandboxARHint!=='true')
   throw Error('Purchased/equipped AR or player-known hint lost on persisted Web reload.');
  await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-ar-restored-web.png'});
  if(errors.length)throw Error(errors.join('\n'));
  console.log('SANDBOX_AR_WEB_PASS: purchased/known-only context, untranslated exclusion, focus/click/ESC and Web reload');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
