# Sandbox S3 P0 — Autonomous NPC Routines and Independent Travel

**Status:** implementation slice for [#26](https://github.com/MohamedXIV/outsider-driver-2d/issues/26) under [#22](https://github.com/MohamedXIV/outsider-driver-2d/issues/22) and [#15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15). See [active roadmap](SANDBOX_EXECUTION_ROADMAP.md), [living-city design](LIVING_CITY_DESIGN_CONCLUSIONS.md), and [supersession register](SUPERSESSION_REGISTER.md). This slice does not complete the wider society or route-control roadmap.

## Reuse / Replace / Retire
- **Reuse:** `SandboxWorld` as the sole authority, NPC and offer IDs, 10-minute tick, generated dispatch offers, ledger event IDs, once-only player-fare settlement, reusable Ink and existing S2 translator proof.
- **Replace within this issue:** NPCs whose only independent action was need accumulation and republishing offers indefinitely. Real time and state now drive work/rest/availability and independent travel.
- **Retire from gameplay:** archived fixed clinic passenger and P2 18/6 economy. Retain its isolated technical regression. **Not replaced here:** S2 partial translator (future #32), player taxi countdown (route travel #27–#28), personal/peer memories (#29–#31).

## Domain ownership and behavior
- `SandboxPopulation` tracks home, workplace, current activity, need, cash and next personal trip purpose for nine seeded persistent residents. At their workplace during daytime they may earn a small wage; late at home they rest and reduce need. During travel they cannot post fresh demand.
- Real unaccepted offers continue to expire normally. `SandboxAutonomy.begin_expired_trips` can trigger an independent **walk** or **affordable shuttle** from the expired origin to the actual requested destination, deducting non-player fare where applicable. The NPC stays at the origin until `transit_until`; `finish_arrivals` then moves them, satisfies their current goal, changes their next need and records provenance of the expired offer.
- `SandboxWorld` alone commits `npc_routine_changed`, `npc_work_paid`, `npc_alternative_departed`, and `npc_alternative_arrived`. No invisible cash paid to the player, invented named driver, parallel NPC story scheduler or duplicated world engine.
- `SandboxSave` uses experimental v4 save envelope/world v3. JSON integer-valued data is restored to integer types to keep deterministic seed replay matching a saved/continued world. No backward-save migration is required.

## Visible proof
- Temporary HUD displays work/rest/in-transit resident counts and independent departures/arrivals; debug **Observe +6h** advances the entire authoritative world without a player fare. Map district NPC counts update from NPC locations. This is **schematic**, not final isometric camera or driving.
- `tests/test_sandbox_autonomy.gd`: 24-hour idle simulation for seeds 8, 9, 17, identical fresh replays, multiple routines, positive work-payments, genuine delayed independent arrivals, world-location changes, wallet separation, save at +12h/restore/continue to +24h identical, and forged in-transit snapshot rejection.
- `tests/test_sandbox_autonomy_scene.gd`: actual Linux Godot visible observer interactions, 24h idle, screenshots before/after and save/reload.
- `tests/web_sandbox_autonomy.cjs`: actual Chromium clicks, 24h idle progression, persistent autonomous counts and browser save/reload; retains existing S0/S1/S2 Web smoke.

**Important limits:** 9 NPCs and simple motives/routines produce frequent activity over the compressed test day; this is causal domain proof, not tuned city demographics, realistic weekly routines, an entire transport network, NPC-to-NPC relationships or polished street presentation. The player taxi is still on the old countdown until #27. Human playtest and actual Windows runtime are not verified.

## Verified final evidence — October 15, 2026

**PASS:** [Godot 4.7.2 cross-platform acceptance #38767914997](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38767914997) on tested gameplay head `36291b789fb780a0919a6bdfdae483e0a2f7550d` (later change updates this documentation only). Canonical S1/S2 Ink compiler/source bytecode, Godot import, historical P1/P2, all S0–S2 sandbox tests, **SANDBOX_AUTONOMY_PASS**, **SANDBOX_AUTONOMY_SCENE_PASS**, legacy contextual browser smoke, and **SANDBOX_AUTONOMY_WEB_PASS** are all green. Linux native runtime/visual screenshots and actual exported Chromium clicks/save/page reload/restore confirmed; Windows was **exported only**, not run on Windows.

Deterministic 24-hour no-player-command probes from the tested run:
- Seed 8: 55 independent departures, 49 arrivals, 35 routine changes, 57 worker wage events.
- Seed 9: 59 departures, 52 arrivals, 36 routine changes, 42 wage events.
- Seed 17: 55 departures, 50 arrivals, 30 routine changes, 52 wage events.

The unfinished departures have actual future arrival timestamps; no extra player income is minted. These compressed counts are **instrumented proof**, **not** a target demand frequency/balancing claim.

Reviewed actual screenshots from [run artifacts](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38767914997): native `sandbox/autonomy-before-idle.png`, `sandbox/autonomy-after-idle.png`, `sandbox/autonomy-restored.png`; Chromium `sandbox-autonomy-before.png`, `sandbox-autonomy-after.png`, `sandbox-autonomy-restored.png`. The HUD shows changed district resident counts and independent departure/arrival counters after 24h. Build bundle `outsider-driver-playtest-builds` artifact **11990555341** and evidence `playable-ride-evidence` artifact **11990585304**, currently retained around 21 days. The schematic art is **not** final camera/UX acceptance.

Development regressions exposed a real JSON numeric-type mismatch in byte-exact save replay, fixed by restoring integer fields; an early Chromium test had stale UI bounds from Godot's pre-layout `_ready()` observation, corrected to click the verified fixed-viewport button. This is not a claim that all responsive layouts are tested.
