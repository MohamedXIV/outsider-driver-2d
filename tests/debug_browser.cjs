const assert = require("node:assert/strict");
const { openCity } = require("./city_browser.cjs");
async function openDebugCity() {
  const s = await openCity(),
    { page, data, ready } = s;
  async function debug() {
    if ((await data()).playerMode !== "false") await page.keyboard.press("F3");
    await page.waitForFunction(
      () =>
        document.documentElement.dataset.playerMode === "false" &&
        JSON.parse(document.documentElement.dataset.debugControls || "{}").wait,
    );
  }
  await page.setViewportSize({ width: 1280, height: 1400 });
  await debug();
  async function point(p) {
    const d = await data(),
      v = JSON.parse(d.playerViewport),
      b = await page.locator("canvas").boundingBox();
    if (p.y > v[1] - 10) {
      await page.setViewportSize({ width: 1280, height: Math.ceil(p.y + 80) });
      await page.waitForTimeout(200);
      return false;
    }
    await page.mouse.click(
      b.x + (p.x * b.width) / v[0],
      b.y + (p.y * b.height) / v[1],
    );
    await page.waitForTimeout(150);
    return true;
  }
  async function dc(key) {
    for (let i = 0; i < 4; i++) {
      const p = JSON.parse((await data()).debugControls)[key];
      assert.ok(p && !p.disabled, "Active diagnostic control: " + key);
      const serial = Number((await data()).debugActionSerial);
      if (await point(p)) {
        await page.waitForFunction(
          (previous) =>
            Number(document.documentElement.dataset.debugActionSerial) >
            previous,
          serial,
        );
        return;
      }
    }
    throw Error("Unreachable control " + key);
  }
  async function native(key) {
    const p = JSON.parse((await data())[key]);
    assert.ok(p[0] > 0 && p[1] > 0, key);
    if (!(await point({ x: p[0], y: p[1] }))) return native(key);
  }
  async function via(id) {
    const i = JSON.parse((await data()).debugViaOptions).indexOf(id);
    assert.ok(i >= 0, id);
    await dc("via");
    await page.waitForFunction(
      () =>
        JSON.parse(document.documentElement.dataset.debugViaPopup || "[]")
          .length === 4,
    );
    const d = await data(),
      r = JSON.parse(d.debugViaPopup),
      n = JSON.parse(d.debugViaOptions).length;
    await point({ x: r[0] + r[2] / 2, y: r[1] + (r[3] * (i + 0.5)) / n });
    await page.waitForFunction(
      (id) => document.documentElement.dataset.sandboxRouteWaypoint === id,
      id,
    );
  }
  async function select(index) {
    for (let i = 0; i < 20; i++) {
      const p = JSON.parse((await data()).debugOffers).find((x) =>
        typeof index === "string" ? x.id === index : x.index === index,
      );
      assert.ok(p, "Real offer row");
      if (p.y < p.top + 2 || p.y > p.bottom - 2) {
        await page.mouse.move(p.x, (p.top + p.bottom) / 2);
        await page.mouse.wheel(0, p.y < p.top ? -120 : 120);
        await page.waitForTimeout(150);
        continue;
      }
      await point(p);
      await page.waitForFunction(
        (id) => document.documentElement.dataset.sandboxSelected === id,
        p.id,
      );
      return;
    }
    throw Error("Offer row unavailable");
  }
  async function finish() {
    await page.waitForFunction(
      () => document.documentElement.dataset.playerTravelling === "true",
    );
    const deadline = Date.now() + 180000;
    while (
      (await data()).playerTravelling === "true" &&
      Date.now() < deadline
    ) {
      if ((await data()).streetTaxiHold) await page.waitForTimeout(500);
      else {
        await dc("wait");
        await page.waitForTimeout(500);
      }
    }
    assert.equal(
      (await data()).playerTravelling,
      "false",
      "Actual route must finish, including crossing waits: " +
        JSON.stringify(await data()),
    );
  }
  async function reloadSave() {
    await dc("save");
    assert.equal((await data()).debugNotice, "Sandbox saved.");
    await page.waitForTimeout(3000);
    await page.reload();
    await ready();
    await debug();
    await dc("load");
    await page.waitForFunction(() =>
      document.documentElement.dataset.debugNotice.includes("restored"),
    );
  }
  async function returning() {
    for (let i = 0; i < 150; i++) {
      const state = await data(),
        index = Number(state.sandboxReturningIndex);
      if (index >= 0) {
        const row = JSON.parse(state.debugOffers).find(
          (row) => row.index === index,
        );
        assert.ok(row && row.id, "Persistent returning request identity");
        await select(row.id);
        return;
      }
      await dc("wait");
    }
    throw Error("No genuine local returning request");
  }
  async function completeFirst() {
    await dc("accept");
    await finish();
    assert.equal((await data()).sandboxSettlements, "1");
    assert.equal((await data()).sandboxKnownCabs, "1");
  }
  return {
    ...s,
    dc,
    native,
    via,
    select,
    finish,
    reloadSave,
    returning,
    completeFirst,
  };
}
async function checkDebug(run) {
  const s = await openDebugCity();
  try {
    await run(s);
    assert.deepEqual(s.errors, []);
  } catch (error) {
    await s.shot(
      "audit-failure-" + require("node:path").basename(process.argv[1], ".cjs"),
    );
    require("node:fs").writeFileSync(
      "/tmp/od2d-city-evidence/failure-" +
        require("node:path").basename(process.argv[1]) +
        ".json",
      JSON.stringify(await s.data(), null, 2),
    );
    throw error;
  } finally {
    await s.browser.close();
  }
}
module.exports = { checkDebug };
