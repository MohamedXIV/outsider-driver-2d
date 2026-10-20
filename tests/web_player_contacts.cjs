const assert = require('node:assert/strict');
const { checkDebug } = require('./debug_browser.cjs');

// Native diagnostics drive the actual two-fare invite setup, not a forged
// browser World mutation. Assertions and the final choice use Player Mode.
checkDebug(async ({ page, data, dc, returning, completeFirst, finish, click, shot, reloadSave }) => {
  const enterPlayerContacts = async () => {
    await page.keyboard.press('F3');
    await page.waitForFunction(() => document.documentElement.dataset.playerMode === 'true');
    await click('contacts');
    await page.waitForFunction(() => document.documentElement.dataset.playerTab === 'contacts');
  };
  const leavePlayer = async () => {
    await page.keyboard.press('F3');
    await page.waitForFunction(() => document.documentElement.dataset.playerMode === 'false');
  };
  const sections = async () => JSON.parse((await data()).playerContactSections || '{}');
  const actions = async () => JSON.parse((await data()).playerActions || '{}');

  await completeFirst();
  await returning();
  await dc('accept');
  await finish();
  assert.equal((await data()).sandboxSettlements, '2');
  assert.equal((await data()).sandboxMeetingStatus, 'invited');
  await dc('meeting_accept');
  assert.equal((await data()).sandboxMeetingStatus, 'accepted');

  await enterPlayerContacts();
  const confirmed = await sections();
  assert.equal(confirmed.ContactsListSection, true);
  assert.equal(confirmed.ContactDetailsSection, true);
  assert.equal(confirmed.ContactActionsSection, true);
  assert.equal(confirmed.ContactRepliesSection, false);
  assert.equal((await actions()).meeting_accept, undefined);
  assert.equal((await actions()).meeting_decline, undefined);
  assert.ok((await actions()).meeting_attend.disabled,
    'The actual time/place gate must remain disabled before arrival');
  await shot('web-player-contact-confirmed');
  await leavePlayer();

  for (let i = 0; i < 80 && (await data()).sandboxMeetingAtVenue !== 'true'; i++)
    await dc('wait');
  assert.equal((await data()).sandboxMeetingAtVenue, 'true');
  await dc('meeting_attend');
  assert.equal((await data()).sandboxMeetingStatus, 'in_progress');
  await reloadSave();
  assert.equal((await data()).sandboxMeetingStatus, 'in_progress');
  assert.equal((await data()).sandboxMeetingChoices, '3');

  await enterPlayerContacts();
  const during = await sections();
  assert.equal(during.ContactsListSection, true);
  assert.equal(during.ContactDetailsSection, true);
  assert.equal(during.ContactSceneSection, true);
  assert.equal(during.ContactRepliesSection, true);
  assert.equal(during.ContactActionsSection, false);
  assert.equal((await data()).playerContactSceneText, (await data()).sandboxMeetingText,
    'Rendered Ink must equal the current sourced meeting frame');
  for (let i = 0; i < 3; i++)
    assert.ok((await actions())['meeting_choice_' + i],
      'Every actual Ink choice must remain a Player Mode action');
  await shot('web-player-contact-meeting');
  await click('meeting_choice_0');
  await page.waitForFunction(() =>
    document.documentElement.dataset.sandboxMeetingStatus === 'completed');
  assert.equal((await data()).sandboxMeetingStatus, 'completed');
  assert.equal((await sections()).ContactRepliesSection, false);
  assert.equal((await sections()).ContactActionsSection, false,
    'Completed encounters must not show nonfunctional invitation controls');
  assert.equal((await actions()).meeting_attend, undefined);
  await shot('web-player-contact-completed');
  console.log('WEB_PLAYER_CONTACTS_PASS real two fares, confirmed appointment, restored Ink, live Player choices, single settlement');
}).catch(err => { console.error(err); process.exitCode = 1; });
