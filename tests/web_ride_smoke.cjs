const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true,
    args: ['--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader',
      '--enable-unsafe-swiftshader', '--disable-dev-shm-usage'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  const check = async (condition, reason) => {
    if (!(await page.evaluate(condition))) throw new Error(reason);
  };
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  const phase = async value => page.waitForFunction(v => document.documentElement.dataset.ridePhase === v,
    value, { timeout: 60000 });
  try {
    await page.goto('http://127.0.0.1:8765/index.html', { waitUntil: 'domcontentloaded' });
    await phase('waiting');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/ride-before-pickup.png' });
    // Real keyboard input drives the visible character to each station.
    for (let i = 0; i < 5; i++) await page.keyboard.press('w');
    for (let i = 0; i < 3; i++) await page.keyboard.press('a');
    await page.waitForFunction(() => document.documentElement.dataset.garageStation === 'workbench', null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/garage-workbench.png' });
    await page.mouse.click(65, 181); // Select GPS at the real workbench
    await page.waitForFunction(() => document.documentElement.dataset.starterDevice === 'gps', null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/shift-prepared.png' });
    for (let i = 0; i < 4; i++) await page.keyboard.press('d');
    await page.waitForFunction(() => document.documentElement.dataset.garageStation === 'noticeboard', null, { timeout: 15000 });
    await page.keyboard.press('e');
    await page.waitForFunction(() => document.documentElement.dataset.noticeRead === 'true', null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/garage-notice.png' });
    // Save/load a partially prepared shift while still on foot, not just mid-ride.
    await page.mouse.click(691, 615); // Save at the garage's fixed RideBar.
    await page.waitForTimeout(2200);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await phase('waiting');
    await page.mouse.click(743, 615); // Load the garage position and knowledge.
    await page.waitForFunction(() => {
      const d = document.documentElement.dataset;
      return d.garageStation === 'noticeboard' && d.starterDevice === 'gps' && d.noticeRead === 'true';
    }, null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/restored-garage.png' });
    for (let i = 0; i < 4; i++) await page.keyboard.press('d');
    for (let i = 0; i < 5; i++) await page.keyboard.press('s');
    await page.waitForFunction(() => document.documentElement.dataset.garageStation === 'taxi', null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/garage-taxi.png' });
    await page.mouse.click(615, 614); // Pick up visitor from the parked taxi
    await page.waitForFunction(() => document.documentElement.dataset.inkReady === 'true' &&
      document.documentElement.dataset.ridePhase === 'traveling', null, { timeout: 15000 });
    await check(() => document.documentElement.dataset.choiceCount === '2', 'Missing original Ink choices');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/ride-with-passenger.png' });
    // Save with an unanswered choice; prove exact playable recovery after a browser reload.
    await page.mouse.click(570, 615); // Save (pickup button disappears during travel)
    await page.waitForTimeout(2200); // Allow Godot Web persistent filesystem to flush.
    await page.reload({ waitUntil: 'domcontentloaded' });
    await phase('waiting');
    await page.mouse.click(743, 615); // Load
    await phase('traveling');
    await check(() => document.documentElement.dataset.choiceCount === '2' &&
      document.documentElement.dataset.rideCredits === '0' && document.documentElement.dataset.starterDevice === 'gps' &&
      document.documentElement.dataset.noticeRead === 'true', 'Unanswered Ink frame, prep or wallet lost on reload');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/restored-midride.png' });
    await page.mouse.click(170, 467); // Authored first Ink response
    await page.waitForFunction(() => document.documentElement.dataset.rideFacts === '3',
      null, { timeout: 15000 });
    await check(() => document.documentElement.dataset.rideCredits === '0', 'Fare paid before dropoff');
    await phase('arrived');
    const before = Number(await page.evaluate(() => document.documentElement.dataset.rideClock));
    await page.waitForTimeout(1200);
    const after = Number(await page.evaluate(() => document.documentElement.dataset.rideClock));
    if (!(after > before)) throw new Error('World time froze at arrival');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/arrived.png' });
    await page.mouse.click(614, 614); // Explicitly enter authored arrival scene
    await page.waitForFunction(() => document.documentElement.dataset.arrivalOffer === 'true' &&
      document.documentElement.dataset.choiceCount === '2', null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/arrival-choices.png' });
    await page.mouse.click(170, 467); // We've arrived (authored Ink ending)
    await phase('completed');
    await check(() => document.documentElement.dataset.rideCredits === '18' &&
      document.documentElement.dataset.rideFacts === '3' &&
      document.documentElement.dataset.rideSuspicion === '0' &&
      document.documentElement.dataset.passengerVisible === 'false' &&
      document.documentElement.dataset.choiceVisible === 'false', 'Completed ride UI or consequences wrong');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/after-dropoff.png' });
    await page.waitForTimeout(2200);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await phase('waiting');
    await page.mouse.click(743, 615); // Restore completed ride
    await phase('completed');
    await check(() => document.documentElement.dataset.rideCredits === '18' &&
      document.documentElement.dataset.rideFacts === '3' &&
      document.documentElement.dataset.rideSuspicion === '0' &&
      document.documentElement.dataset.passengerVisible === 'false', 'Completed consequences failed browser persistence');
    await page.mouse.click(743, 615); // Second Load is idempotent
    await phase('completed');
    await check(() => document.documentElement.dataset.rideCredits === '18', 'Duplicate payment after loading');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/restored-completed.png' });

    // Player actually returns to the garage, services the taxi, and works a second shift.
    await page.keyboard.press('e');
    await phase('waiting');
    await check(() => {
      const d = document.documentElement.dataset;
      return d.rideCount === '1' && d.dayNumber === '2' &&
        d.serviceDue === 'true' && d.rideCredits === '18' && d.starterDevice === 'gps';
    }, 'Return lost the first fare or service debt');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/returned-day2.png' });
    await page.waitForTimeout(2200);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await phase('waiting');
    await page.mouse.click(743, 615); // Load the overnight garage state.
    await page.waitForFunction(() => {
      const d = document.documentElement.dataset;
      return d.rideCount === '1' && d.dayNumber === '2' && d.serviceDue === 'true';
    }, null, { timeout: 15000 });
    for (let i = 0; i < 5; i++) await page.keyboard.press('w');
    for (let i = 0; i < 3; i++) await page.keyboard.press('a');
    await page.waitForFunction(() => document.documentElement.dataset.garageStation === 'workbench', null, { timeout: 15000 });
    await page.keyboard.press('e'); // One 6-credit repair/upkeep payment.
    await page.waitForFunction(() => {
      const d = document.documentElement.dataset;
      return d.serviceDue === 'false' && d.rideCredits === '12' && d.serviceCount === '1';
    }, null, { timeout: 15000 });
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/serviced-day2.png' });
    for (let i = 0; i < 8; i++) await page.keyboard.press('d');
    for (let i = 0; i < 5; i++) await page.keyboard.press('s');
    await page.waitForFunction(() => document.documentElement.dataset.garageStation === 'taxi', null, { timeout: 15000 });
    await page.mouse.click(615, 614);
    await phase('traveling');
    await check(() => document.documentElement.dataset.choiceCount === '2', 'Second Ink story did not start.');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/second-ride.png' });
    await page.mouse.click(170, 467); // Repeat authored route-information reply.
    await phase('arrived');
    await page.mouse.click(614, 614);
    await page.waitForFunction(() => document.documentElement.dataset.arrivalOffer === 'true', null, { timeout: 15000 });
    await page.mouse.click(170, 467);
    await phase('completed');
    await check(() => {
      const d = document.documentElement.dataset;
      return d.rideCount === '2' && d.rideCredits === '30' &&
        d.serviceCount === '1' && d.serviceDue === 'true' &&
        d.rideFacts === '3' && d.passengerVisible === 'false';
    }, 'Second fare or one-time repair/upkeep failed');
    await page.screenshot({ path: '/tmp/od2d-ink-evidence/second-completed.png' });
    await page.waitForTimeout(2200);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await phase('waiting');
    await page.mouse.click(743, 615);
    await page.waitForFunction(() => document.documentElement.dataset.rideCount === '2', null, { timeout: 15000 });
    await check(() => document.documentElement.dataset.rideCredits === '30' &&
      document.documentElement.dataset.serviceDue === 'true', 'Second shift failed browser persistence');
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('P1_RIDE_WEB_PASS: two shifts, once-only fares and upkeep, native Ink and garage persistence in Chromium');
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
