const assert = require("node:assert/strict");
const { checkDebug } = require("./debug_browser.cjs");
checkDebug(
  async ({
    page,
    data,
    dc,
    native,
    via,
    finish,
    reloadSave,
    returning,
    completeFirst,
    shot,
  }) => {
    await completeFirst();
    await returning();
    await dc("accept");
    await finish();
    assert.equal((await data()).sandboxSettlements, "2");
    assert.equal((await data()).sandboxMeetingStatus, "invited");
    await dc("meeting_accept");
    for (
      let i = 0;
      i < 80 && (await data()).sandboxMeetingAtVenue !== "true";
      i++
    )
      await dc("wait");
    assert.equal((await data()).sandboxMeetingAtVenue, "true");
    await dc("meeting_attend");
    assert.equal((await data()).sandboxMeetingStatus, "in_progress");
    assert.equal((await data()).sandboxMeetingChoices, "3");
    assert.match(
      (await data()).sandboxMeetingText,
      /familiar passenger|untranslated/,
    );
    await reloadSave();
    assert.equal((await data()).sandboxMeetingStatus, "in_progress");
    assert.equal((await data()).sandboxMeetingChoices, "3");
    await shot("audit-meeting-restored");
    await native("sandboxMeetingChoicePoint");
    assert.equal((await data()).sandboxMeetingStatus, "completed");
    console.log(
      "SANDBOX_MEETING_WEB_PASS current graph, real controls and persisted canonical state",
    );
  },
).catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
