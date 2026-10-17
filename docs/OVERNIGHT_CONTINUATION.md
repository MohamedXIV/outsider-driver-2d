# Autonomous continuation — October 17, 2026

Same branch `codex/overnight-completion`, same [Draft PR #62](https://github.com/MohamedXIV/outsider-driver-2d/pull/62), targeting `feat/native-pedestrian-crossing-pilot`.

**Final code SHA: `28960f90a6ecaa357ed4c25646e1d1db8e345121`.** The final evidence commit changes documentation/artifacts only. Source tree: `2de24fdf3583933de3a55cee7bae5ddbed9deefe` under `scripts/sandbox`.

Live head before this continuation was `06557e55f99f4fa4137cab62dc0e6f929b2d923b`. Final live audit confirms main remains `05ea3fdd3c5a0484f2b2db7657a639ad919bff30`, #55 remains `e18aa0cd1444865f0ce7f669590df201ad8de36b`, and #61 remains `983ed8724baf936828bb620f270a387fcbd45b7a`. They are unmerged and untouched. No additional PR/branch was created.

## Sequential verified batches

| Commit | Result |
| --- | --- |
| `0f621c699ccd41906b28b03a23a03a8348cd7769` | [#59/#60 two-resident native crossing](MULTI_RESIDENT_CROSSING.md): natural seed 29 residents `npc:04`/`npc:08`, population nine, separate bodies/agents/reservations, actual taxi and genuine shuttle last-body holds, cancellation, blocked path, missing body, independent save/handoff and once-only arrivals. |
| `9da3c6d0efbb850a84edcfad6f8ac1f165f84c83` | [#60 local T-junction](LOCAL_JUNCTION_TRAFFIC.md): FIFO conflict ownership, blocked exit, physical obstruction, 42px headway, saved body reconstruction and finite queue drain. Three explicit ambient cars do not add residents, services or an economy. Also fixes restoring the presenter after all native errands have arrived. |
| `a5f48fab2a4da40579098f005d600f853422c259` | [#58 bridge/ramp presentation](BRIDGE_PRESENTATION.md): grounded paired supports, clear ground carriageways and facade footprints, tapered retaining faces, deck depth, joined surfaces and structure/ground/deck ordering. No graph, grade, toll or travel-time changes. Close/wide before/after captures are included. |

Follow-up `28960f90a6ecaa357ed4c25646e1d1db8e345121` keeps all three terminal queue bodies between the marked x950/x1100 crossings. Focused native and exported FIFO/obstruction/headway/save tests passed again with explicit final body-clearance assertions.

## Verification

Pinned **Godot 4.7.2 stable, `ed1daf0bf`**, Linux X11/Mesa llvmpipe:

- **35/35 domain and adapter tests PASS**.
- **27/27 native rendered tests PASS**.
- After the final drawing-order adjustment, the native underpass/ramp/deck/descent test passed again; committed bridge/retained-layer/camera checks also passed. Those focused final logs are included alongside the full gates.
- **5 exported Chromium suites PASS:** two-resident movement/live save/reload/narrow viewport/once-only arrivals; native junction FIFO/spacing/queue drain/save; camera/phone controls/persistence; complete Player Mode fare/Ink/save/settlement/market/module/AR/narrow Arabic; two genuine fare routes.

The two genuine fares passed with **28.16 km / 72 minutes** via depot, then **13.97 km / 35 minutes**, with exactly two settlements.

[Full logs and manifest](evidence/continuation-2026-10-17/verification-logs.zip). The exported build is reproducible using the pinned editor/templates and the checked-in `tests/web_*.cjs` checks. The crossing native harness stages problematic body positions while using genuine residents, routes and a genuinely generated shuttle. The Web resident test chooses natural seed 29 with the existing Debug seed selector, then exercises actual native movement and ordinary Player Mode Save/Load.

Regressions found and fixed include a narrow counter pavement preventing passing, embedded cars moving along the screen axis instead of their rotated lane, stale RVO movement after cancellation, physical progress advancing behind a collider, all-arrived saves losing their street presenter, building footprints beneath piers and disconnected-looking edge end caps. The retained-layer test was updated for the added structure layer; an initial gate launched against its old four-layer assertion timed out, and the corrected full domain rerun passed. Early Web/native failures were repaired before committing their respective work batches.

## Screenshots

[Two residents / native aggregate hold](evidence/multi-resident-2026-10-17/native-staggered-hold.png), [restored narrow viewport](evidence/multi-resident-2026-10-17/multi-two-residents-restored-narrow.png), [junction queue](evidence/junction-2026-10-17/junction-blocked-queue.png), [branch admission](evidence/junction-2026-10-17/junction-branch-admitted.png).

[Underpass close](evidence/bridge-2026-10-17/06-underpass.png), [deck wide](evidence/bridge-2026-10-17/08-deck-wide.png), [connected descent](evidence/bridge-2026-10-17/09-connected-descent.png). The bridge report links all eight close/wide captures, their authoritative position JSON and the earlier before captures.

## Remaining / blockers

No engineering blocker remains for these bounded slices. #58/#59/#60 stay open: citywide native pedestrian coverage, additional composed crossings/junctions and genuine world-owned vehicle bodies participating in broader native lane arbitration remain technical work. Current taxi/shuttle coordination is authoritative route-level yielding at the loaded Patchworks crossing, not an all-city physics fleet.

Actual Windows runtime, hardware touch and human camera/UI/bridge/traffic/pacing acceptance remain unverified. No human acceptance, issue closure or merge is claimed; umbrella #48/#15 remain open. The next technical package is binding one genuine world-owned transit actor to a composed native lane/junction while retaining its existing trip provenance, then broadening coverage incrementally.

The combined Web wrapper initially stopped the two-route script at six minutes while its second fare was still in progress. A standalone rerun passed its unchanged individual fare deadlines and assertions. The wrapper timeout and passing standalone logs are both retained. A final local queue review also found terminal cars could overlap the next marked crossing; the stopping point now fits all three bodies between zebras, verified by focused native and exported checks.
