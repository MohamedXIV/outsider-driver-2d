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
    assert.equal((await data()).sandboxAltDepartures, "0");
    for (let i = 0; i < 4; i++) await dc("observe");
    let d = await data();
    assert.ok(+d.sandboxAltDepartures > 0 && +d.sandboxAltArrivals > 0);
    const before = {
      depart: +d.sandboxAltDepartures,
      arrive: +d.sandboxAltArrivals,
    };
    await reloadSave();
    d = await data();
    assert.ok(
      +d.sandboxAltDepartures >= before.depart &&
        +d.sandboxAltArrivals >= before.arrive,
    );
    await shot("audit-autonomous-day");
    console.log(
      "SANDBOX_AUTONOMY_WEB_PASS current graph, real controls and persisted canonical state",
    );
  },
).catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
