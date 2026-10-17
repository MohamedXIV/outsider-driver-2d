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
    assert.equal((await data()).sandboxSelectedRecognizes, "true");
    await dc("talk");
    assert.equal((await data()).sandboxDialogueRecognizes, "true");
    assert.ok((await data()).sandboxDialogueText.length > 0);
    const offer = (await data()).sandboxDialogueOffer;
    await reloadSave();
    assert.equal((await data()).sandboxDialogueRecognizes, "true");
    assert.equal((await data()).sandboxDialogueOffer, offer);
    await shot("audit-returning-driver");
    console.log(
      "SANDBOX_DRIVER_WEB_PASS current graph, real controls and persisted canonical state",
    );
  },
).catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
