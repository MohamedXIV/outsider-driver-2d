const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({headless:true,
    args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader',
      '--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  const page = await browser.newPage({viewport:{width:1280,height:720}});
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => {if(m.type()==='error') errors.push(m.text());});
  try {
    await page.goto('http://127.0.0.1:8765/index.html',{waitUntil:'domcontentloaded'});
    await page.waitForFunction(() => document.documentElement.dataset.sandboxReady==='true',null,{timeout:45000});
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-autonomy-before.png'});
    const origin = await page.evaluate(() => {
      const d=document.documentElement.dataset;
      return {seed:d.sandboxSeed, counts:d.sandboxAltDepartures};
    });
    if(origin.seed!=='8'||origin.counts!=='0')throw new Error('Expected fresh city without alternative trips.');
    const clickObserve = async () => {
      const r = await page.evaluate(() => JSON.parse(document.documentElement.dataset.sandboxObserveRect));
      await page.mouse.click(r[0]+r[2]/2,r[1]+r[3]/2);
    };
    for(let i=0;i<4;i++)await clickObserve();
    await page.waitForFunction(() => {
      const d=document.documentElement.dataset;
      return +d.sandboxAltDepartures>0 && +d.sandboxAltArrivals>0;
    },null,{timeout:15000});
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-autonomy-after.png'});
    const before=await page.evaluate(() => {
      const d=document.documentElement.dataset;
      return {events:d.sandboxEvents,depart:d.sandboxAltDepartures,arrive:d.sandboxAltArrivals};
    });
    await page.mouse.click(95,610); // Save in existing dock panel
    await page.waitForTimeout(2200);
    await page.reload({waitUntil:'domcontentloaded'});
    await page.waitForFunction(() => document.documentElement.dataset.sandboxReady==='true',null,{timeout:45000});
    await page.mouse.click(250,610); // Load
    await page.waitForFunction(expected => {
      const d=document.documentElement.dataset;
      return d.sandboxEvents===expected.events && d.sandboxAltDepartures===expected.depart &&
        d.sandboxAltArrivals===expected.arrive;
    },before,{timeout:15000});
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-autonomy-restored.png'});
    if(errors.length)throw new Error(errors.join('\n'));
    console.log('SANDBOX_AUTONOMY_WEB_PASS: independent NPC trips, 24h idle world and reload');
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
