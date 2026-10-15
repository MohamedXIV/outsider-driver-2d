const { chromium } = require('playwright');
(async () => {
 const browser = await chromium.launch({headless:true,args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
 const page = await browser.newPage({viewport:{width:1280,height:720}});
 const failures=[];
 page.on('pageerror',e=>failures.push(e.message));
 page.on('console',m=>{if(m.type()==='error')failures.push(m.text())});
 const value=key=>page.evaluate(k=>document.documentElement.dataset[k],key);
 try{
  await page.goto('http://127.0.0.1:8765/index.html',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxReady==='true',{},{timeout:45000});
  if((await value('sandboxMeetingCount'))!=='0')throw Error('Meeting before any relationship');
  await page.mouse.click(90,455);
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxPhase==='enroute',null,{timeout:15000});
  for(let i=0;i<12;i++){
    if((await value('sandboxPhase'))==='seeking')break;
    await page.mouse.click(90,557);
  }
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxSettlements==='1',null,{timeout:15000});
  let index=-1;
  for(let i=0;i<70;i++){
   index=+(await value('sandboxReturningIndex'));
   if(index>=0)break;
   await page.mouse.click(90,557);
  }
  if(index<0)throw Error('No repeat real passenger');
  await page.mouse.click(125,176+index*24);
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxSelectedRecognizes==='true',null,{timeout:15000});
  await page.mouse.click(90,455);
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxPhase==='enroute',null,{timeout:15000});
  for(let i=0;i<12;i++){
    if((await value('sandboxPhase'))==='seeking')break;
    await page.mouse.click(90,557);
  }
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxMeetingStatus==='invited',null,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/meeting-invited-web.png'});
  await page.mouse.click(1120,435);
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxMeetingStatus==='accepted',null,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/meeting-confirmed-web.png'});
  const slot=+(await value('sandboxMeetingSlot'));
  for(let i=0;i<90 && +(await value('sandboxMinute'))<slot;i++){
   await page.mouse.click(90,557);
  }
  if((await value('sandboxMeetingAtVenue'))!=='true')throw Error('NPC missing or not physically at place and time');
  await page.mouse.click(1120,502);
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxMeetingStatus==='in_progress',null,{timeout:15000});
  if(+(await value('sandboxMeetingChoices'))!==3 || !(await value('sandboxMeetingText')).includes('kiosk'))
    throw Error('Off-duty Ink scene did not present real choices');
  await page.screenshot({path:'/tmp/od2d-ink-evidence/meeting-together-web.png'});
  await page.mouse.click(90,610); // Save with the encounter still in progress
  await page.reload({waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxReady==='true',null,{timeout:45000});
  await page.mouse.click(250,610); // Load
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxMeetingStatus==='in_progress',null,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/meeting-restored-web.png'});
  await page.mouse.click(710,594); // Authored 'listen' choice in visible meeting scene
  await page.waitForFunction(()=>document.documentElement.dataset.sandboxMeetingStatus==='completed',null,{timeout:15000});
  await page.screenshot({path:'/tmp/od2d-ink-evidence/meeting-completed-web.png'});
  if(failures.length)throw Error(failures.join('\n'));
  console.log('SANDBOX_MEETING_WEB_PASS: real repeat fares, personal invitation, scheduled location, Ink encounter and save/reload');
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
