const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true,
    args: ['--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader',
      '--enable-unsafe-swiftshader', '--disable-dev-shm-usage'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  const ready = () => page.waitForFunction(
    () => document.documentElement.dataset.sandboxReady === 'true', null, {timeout:45000});
  const check = async (fn, message) => {
    if (!(await page.evaluate(fn))) throw new Error(message);
  };
  try {
    await page.goto('http://127.0.0.1:8765/index.html', {waitUntil:'domcontentloaded'});
    await ready();
    await check(() => {
      const d = document.documentElement.dataset;
      return d.sandboxSeed === '8' && +d.sandboxOffers >= 2 &&
        d.sandboxResidents === '9' && d.sandboxAccepted === 'true';
    }, 'No systemic local offers at bootstrap.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-initial.png'});
    await page.mouse.click(730, 66); // Actual Translator button center from 1280x720 Chromium screenshot.
    await page.waitForFunction(() => {
      const d = document.documentElement.dataset;
      return d.sandboxDevice === 'translator' && d.sandboxKnowledge === '1' &&
        d.sandboxRouteMarker === 'false';
    }, null, {timeout:15000});
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-translator-untrained.png'});
    await page.mouse.click(337, 455); // Talk to the actual local NPC behind selected offer.
    await page.waitForFunction(() => {
      const d = document.documentElement.dataset;
      return d.sandboxDialogue === 'true' && d.sandboxDialogueChoices === '3' &&
        d.sandboxDialogueUnderstood === 'false' &&
        d.sandboxDialogueIntent === 'request_trip';
    }, null, {timeout:15000});
    await check(() => document.documentElement.dataset.sandboxDialogueText.includes("Rru'ka"),
      'The local-language passenger magically speaks English.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-unknown-speech.png'});
    await page.mouse.click(700, 534); // Ink: Ask where they need to go.
    await page.waitForFunction(() => {
      const d = document.documentElement.dataset;
      return d.sandboxDialogueIntent === 'ask_destination' &&
        d.sandboxDialogueChoices === '2';
    }, null, {timeout:15000});
    await check(() => document.documentElement.dataset.sandboxDialogueText.includes('Vrek shaa') &&
      !document.documentElement.dataset.sandboxDialogueText.includes('route marker for '),
      'First destination question incorrectly translated unlearned local speech.');
    await check(() => document.documentElement.dataset.sandboxRouteMarker === 'true' &&
      document.documentElement.dataset.sandboxKnowledge === '2',
      'Actual local speaker did not teach one route marker to the translator.');
    await page.mouse.click(95, 610); // Save WORLD + unanswered Ink frame.
    await page.waitForTimeout(2200); // Persist Godot Web filesystem.
    await page.reload({waitUntil:'domcontentloaded'});
    await ready();
    await page.mouse.click(250, 610); // Restore the same live resident and Ink decision.
    await page.waitForFunction(() => {
      const d = document.documentElement.dataset;
      return d.sandboxDialogue === 'true' && d.sandboxDialogueChoices === '2' &&
        d.sandboxDialogueIntent === 'restored';
    }, null, {timeout:15000});
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-restored-dialogue.png'});
    await page.mouse.click(337, 455); // Ask the same NPC again with acquired lexicon.
    await page.waitForFunction(() => document.documentElement.dataset.sandboxDialogueChoices === '3',
      null, {timeout:15000});
    await page.mouse.click(700, 534);
    await page.waitForFunction(() => document.documentElement.dataset.sandboxDialogueChoices === '2' &&
      document.documentElement.dataset.sandboxDialogueText.includes('route marker for '),
      null, {timeout:15000});
    await check(() => document.documentElement.dataset.sandboxDialogueUnderstood === 'false',
      'Partial phrase knowledge was incorrectly promoted to fluent translation.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-learned-route.png'});
    await page.mouse.click(700, 534); // Ink accept speech act -> authoritative SandboxWorld.
    await page.waitForFunction(() => document.documentElement.dataset.sandboxPhase === 'enroute' &&
      document.documentElement.dataset.sandboxDialogueOutcome === 'accepted',
      null, {timeout:15000});
    await page.waitForFunction(() => document.documentElement.dataset.sandboxDialogue === 'false',
      null, {timeout:15000});
    await page.waitForFunction(() => document.documentElement.dataset.sandboxPhase === 'enroute',
      null, {timeout:15000});
    await check(() => document.documentElement.dataset.sandboxSettlements === '0',
      'Fare paid before travel.');
    await page.mouse.click(120, 557); // Wait +20 simulated minutes.
    await page.waitForFunction(() => document.documentElement.dataset.sandboxSettlements === '1',
      null, {timeout:15000});
    await check(() => document.documentElement.dataset.sandboxPhase === 'seeking' &&
      +document.documentElement.dataset.sandboxCredits > 12, 'No trip settlement.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-settled.png'});
    const credits = await page.evaluate(() => document.documentElement.dataset.sandboxCredits);
    await page.mouse.click(95, 610); // Save world.
    await page.waitForTimeout(2200); // Flush Godot Web FS.
    await page.reload({waitUntil:'domcontentloaded'});
    await ready();
    await page.mouse.click(250, 610); // Load world.
    await page.waitForFunction(expected => document.documentElement.dataset.sandboxCredits === expected &&
      document.documentElement.dataset.sandboxSettlements === '1', credits, {timeout:15000});
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-restored.png'});
    await page.mouse.click(300, 557); // New seeded world.
    await page.waitForFunction(() => document.documentElement.dataset.sandboxSeed === '9',
      null, {timeout:15000});
    await check(() => document.documentElement.dataset.sandboxSettlements === '0',
      'New seed inherited settled ride.');
    await page.screenshot({path:'/tmp/od2d-ink-evidence/sandbox-seed9.png'});
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('SANDBOX_WEB_PASS: systemic NPC contextual Ink, alien fallback, mid-dialogue restore, settlement and reseed');
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
