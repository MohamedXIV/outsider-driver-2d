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
    assert.match(d.sandboxRoutePreview, /garage.*margin_gate.*market/);
    const normal = Number(d.sandboxRoutePreview.match(/(\d+) min/)[1]);
    await via("depot");
    assert.match((await data()).sandboxRoutePreview, /depot/);
    assert.ok(
      Number((await data()).sandboxRoutePreview.match(/(\d+) min/)[1]) > normal,
    );
    await dc("accept");
    assert.ok((await data()).sandboxRouteNodes.split(",").includes("depot"));
    await dc("wait");
    const nodes = (await data()).sandboxRouteNodes;
    await reloadSave();
    assert.equal((await data()).sandboxRouteNodes, nodes);
    await finish();
    assert.equal((await data()).sandboxSettlements, "1");
    assert.equal((await data()).sandboxDistrict, "market");
    await shot("audit-routes-restored");
    console.log(
      "SANDBOX_ROUTES_WEB_PASS current graph, real controls and persisted canonical state",
    );
  },
).catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
