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
    await via("depot");
    await dc("accept");
    let d = await data();
    assert.equal(d.sandboxRiderStatus, "pending");
    const requested = d.sandboxRiderVia;
    await dc("honor");
    assert.equal((await data()).sandboxRiderStatus, "accepted");
    assert.ok(
      (await data()).sandboxPendingRoute.split(",").includes(requested),
    );
    const pending = (await data()).sandboxPendingRoute;
    await reloadSave();
    assert.equal((await data()).sandboxPendingRoute, pending);
    assert.equal((await data()).sandboxRiderStatus, "accepted");
    await finish();
    assert.equal((await data()).sandboxSettlements, "1");
    assert.equal((await data()).sandboxDistrict, "market");
    await shot("audit-rider-reroute");
    console.log(
      "SANDBOX_REROUTE_WEB_PASS current graph, real controls and persisted canonical state",
    );
  },
).catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
