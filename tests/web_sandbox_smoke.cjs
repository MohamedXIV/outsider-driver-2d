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
    await dc("talk");
    let d = await data();
    assert.equal(d.sandboxDialogueUnderstood, "false");
    assert.deepEqual(JSON.parse(d.sandboxInstalled), ["trade"]);
    assert.match(d.sandboxDialogueText, /[ᚁ-᚜ᚠ-ᛪ]/u);
    assert.doesNotMatch(
      d.sandboxDialogueText,
      /points at|stranger|taxi|destination/i,
    );
    await native("sandboxCommonPoint");
    await page.waitForTimeout(1000);
    assert.equal((await data()).sandboxDialogueUnderstood, "true");
    assert.equal((await data()).sandboxCommonRequested, "true");
    const offer = (await data()).sandboxDialogueOffer;
    await reloadSave();
    assert.equal((await data()).sandboxDialogueOffer, offer);
    assert.equal((await data()).sandboxCommonRequested, "true");
    assert.equal((await data()).sandboxDialogueUnderstood, "true");
    await native("sandboxInkAcceptPoint");
    await finish();
    assert.equal((await data()).sandboxSettlements, "1");
    await shot("audit-sandbox-smoke");
    console.log(
      "SANDBOX_SMOKE_WEB_PASS current graph, real controls and persisted canonical state",
    );
  },
).catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
