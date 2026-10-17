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
    assert.equal((await data()).sandboxPeerContacts, "0");
    await dc("observe");
    let d = await data();
    assert.ok(+d.sandboxPeerContacts > 0 && +d.sandboxPeerFacts > 0);
    assert.match(d.sandboxPeerLast, /met/);
    const n = +d.sandboxPeerContacts;
    await reloadSave();
    assert.ok(+(await data()).sandboxPeerContacts >= n);
    await shot("audit-peer-provenance");
    console.log(
      "SANDBOX_PEER_WEB_PASS current graph, real controls and persisted canonical state",
    );
  },
).catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
