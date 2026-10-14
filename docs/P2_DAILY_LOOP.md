# P2.2 — Return, Upkeep & Repeatable Shifts

The vertical slice is now repeatable without resetting the entire game. **One authored clinic passenger/route repeats intentionally**: this proves the economy, daily lifecycle and per-ride Ink isolation. It does *not* supply a catalog of new passengers, new jobs, a full simulation of taxis, fuel/rent or free city driving.

## One complete daily cycle

1. At the small dockside garage, approach the workbench and choose GPS / Translator / Radio **once per run**. The gear and its knowledge persist for subsequent days. Optional shift notice can be read once.
2. Approach the parked taxi and take the clinic fare. The existing authored route and Ink choices run; 18 credits are awarded exactly once when the passenger exits at the clinic.
3. From the completed ride, choose **Return to garage** (or press **E**). The city clock advances to the following morning, the route resets, and on-foot movement resumes. **No money changes hands merely from returning.**
4. Return to the workbench and choose **Service taxi (6 cr)** or press **E**. This models one combined mandatory garage upkeep/repair charge **per completed fare**. It is charged exactly once, and only when the vehicle is physically at the bench and credits are sufficient.
5. Return to the parked taxi and start another ride. Leaving is blocked until upkeep is paid. The story restarts from its authored entry, **not** from the previous passenger's ending. Effects use ride-scoped event IDs: facts remain deduplicated globally; suspicion can increase again on a later ride.
6. Repeat. After the second completed fare, the expected balance is **18 + 18 − 6 = 30 credits**, with a second service bill due on returning to the garage.

## State and save contract

`GameSession` remains authoritative over phase, credits, garage position, world clock, selected starter device, facts, suspicion, completed ride count, service count and pending service obligation. Completing a ride increments `completed_rides` and creates the service debt; the garage return resets only the current route. Story event idempotency is scoped by ride number.

New save schema **v4** stores the repeated shift economy, unfinished Ink state when traveling, and any garage state. No v3 migration is required. Load after return, after servicing, mid-ride and after completion must not double-pay or double-charge.

## Acceptance boundaries

- Cross-platform proof requires native session/loop tests, visible Linux Godot scene tests, real exported Chromium Web keyboard/mouse navigation through **two complete rides**, browser reload and screenshot review.
- Original P1 human pacing/legibility and Windows runtime acceptance remain open on [Issue #3](https://github.com/MohamedXIV/outsider-driver-2d/issues/3).
- The repeatability/regression suite is an engineering gate; the remaining **P2.3** focuses on richer deterministic repeated-run behavior and human review.
- **Not implemented:** apartment, real housing/rent bills, different daily job offers, extra authored passengers, physical return-trip driving, economy balancing or final illustrations.

## Validation evidence — October 15, 2026

- **PASS:** [Godot 4.7.2 Web/Desktop CI #38652590394](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38652590394) on gameplay/test commit `3c02a6fa399031730efde5708dbed38aa261e4a2`. Source/compiled Ink parity, editor import, native Ink and GameSession, two-ride economic test, garage bounds and proximity, Linux export/boot, Windows export, visible Linux native scene walkthrough, and real exported Chromium keyboard/mouse two-shift journey all succeeded.
- Reviewed screenshot evidence from **playable-ride-evidence** (artifact ID `11935366953`): `returned-day2.png`, `serviced-day2.png`, `second-ride.png`, `second-completed.png` and native equivalents. Web shows day 2 at 18 credits with 6 due, then 12 after servicing, then 30 after another 18-credit clinic fare; passenger UI disappears on completion. Native second-ride screenshots use an instantaneous 100-second simulation jump and **do not** prove natural camera pacing.
- Downloadable **outsider-driver-playtest-builds** (artifact ID `11935486880`, 21-day retention) contains Windows x86_64, Linux x86_64 and Web distributions from this passing run. Windows was exported but not executed on Windows hardware.
- First failing run #38652178707 exposed a real brittle completed-HUD Chromium **Load** click: the later Return button occupied its old x=743 target, and `phase('completed')` timed out. The follow-up corrected the completed-state Load target to x=620; #38652590394 then passed, including reloads for both shifts. A browser click at the waiting state's Load location remains x=743.
- **Not verified:** human pacing/comfort, final illustration, varied passengers/contracts, true return-drive travel, rent/housing expenses or actual Windows runtime. [P1 issue #3](https://github.com/MohamedXIV/outsider-driver-2d/issues/3) stays open.
