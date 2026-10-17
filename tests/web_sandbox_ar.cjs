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
    let d = await data();
    assert.equal(d.sandboxAROwned, "false");
    await dc("gps");
    await page.waitForFunction(
      () => document.documentElement.dataset.sandboxDevice === "gps",
    );
    await completeFirst();
    assert.equal((await data()).sandboxDistrict, "market");
    const credits = +(await data()).sandboxCredits;
    await native("sandboxARBuyPoint");
    assert.equal((await data()).sandboxAROwned, "true");
    assert.equal(+(await data()).sandboxCredits, credits - 5);
    await native("sandboxARWearPoint");
    await returning();
    await dc("talk");
    assert.equal((await data()).sandboxDialogueUnderstood, "false");
    assert.equal((await data()).sandboxARHint, "false");
    await native("sandboxCommonPoint");
    await page.waitForTimeout(1000);
    assert.equal((await data()).sandboxDialogueUnderstood, "true");
    await native("sandboxInkAskPoint");
    assert.equal((await data()).sandboxARHint, "true");
    await native("sandboxARContextPoint");
    d = await data();
    assert.equal(d.sandboxARHintCertainty, "verified");
    assert.match(d.sandboxARHintSource, /starter:gps/);
    assert.match(d.sandboxARHintText, /Source:/);
    assert.ok(!d.sandboxARHintText.includes("human"));
    await page.keyboard.press("Escape");
    await native("sandboxARContextPoint");
    await native("sandboxARClosePoint");
    assert.equal((await data()).sandboxAROverlay, "false");
    await native("sandboxARWearPoint");
    assert.equal((await data()).sandboxARHint, "false");
    await native("sandboxARWearPoint");
    await reloadSave();
    assert.equal((await data()).sandboxAREquipped, "true");
    assert.equal((await data()).sandboxARHint, "true");
    await shot("audit-ar-source-restored");
    console.log(
      "SANDBOX_AR_WEB_PASS current graph, real controls and persisted canonical state",
    );
  },
).catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
