# P1.3 — First Ride & Authoritative Session

One authored job/passenger and taxi route through the existing Godot world.

## Contract
- `GameSession` owns clock, pickup/arrival/completion phase, route progress, credits, knowledge, suspicion and duplicate-safe consequences.
- `InkBridge` owns interpreter state and the current choice frame, not game truth. All `fact:` and `suspicion:` tags apply through `GameSession`.
- World time continues through active dialogue and after arrival. The taxi stops on arrival, while the clock keeps advancing.
- At the destination, the player explicitly chooses **Talk at destination** to transition into Ink's short authored `arrival` knot. Unanswered earlier choices are not cut automatically. Ink provides **We've arrived** and **Take your time** replies, and only their authored `arrival:complete` tags settle the fare.
- Completed drop-off hides passenger and dialogue presentation; `drop_off` awards 18 credits exactly once.
- Fresh v1 `RideSave` persists authoritative session and active Ink frame/state. No compatibility burden from the old 3D project.
- Passenger, taxi and roadway graphics are placeholders, not approved final artwork.

## Evidence and acceptance
- [Earlier baseline: successful native and Chromium run #38624638579](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38624638579) at `d05dbcf8`; screenshots showed passenger hidden after drop-off and 18 credits/1 known fact restored after browser reload.
- New targeted regression checks include unfinished choice recovery after browser reload, Ink-authored arrival ending, clock advancement while stopped, idempotent fare and repeated Load, restored consequence values, and hidden passenger/choice UI.
- **Verified:** [CI #38634574610](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38634574610) on `268707306d77859ad4a94c306e4c642744acf20c` passed compiler/source parity, Godot 4.7.2 import/scene, native Ink and session tests, Linux release export+boot, and exported Web Chromium journey.
- Captured Chromium screenshots and inspected: `ride-before-pickup.png`, `ride-with-passenger.png`, `restored-midride.png`, `arrived.png`, `arrival-choices.png`, `after-dropoff.png`, and `restored-completed.png`. They show the authored arrival options, restored in-progress dialogue, correct hidden panels after drop-off, and restored wallet (18 cr) plus known fact (1).
- Web assertions cover clock advancing after arrival, single payout, saved and restored credits/facts/suspicion, and repeat Load without duplicate fare. Native tests cover both authored arrival endings, pending choice state restoration, and persistence.
- **Not yet human-accepted:** readability and pacing of the full ride. Art remains intentionally placeholder; the visible "taxi follows authored route" debug HUD and barebones passenger writing deserve a small focused P1 follow-up rather than being described as finished production UI.

## P1.4 — First passenger authenticity and shift readability
- Replace the old Ink proof line with a clinic passenger concerned about the inspection arch. Asking about local roads learns `docks-route`; bluffing confidence increases suspicion. Arrival branches and single fare remain unchanged.
- The ride HUD shows fare, wallet, learned route and a behavioral passenger hint instead of raw suspicion/fact counters. Save/Load feedback has a separate label below the actions; the HUD no longer says "P0 proof" or "taxi follows authored route".
- **Validated:** [Godot 4.7.2 native/Linux/Web CI #38635771346](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38635771346), implementation commit `e4a2d5b4949056cbed4abb33dfc1af5e9574a7b6`. Actual Chromium screenshots show pickup, the route-knowledge consequence, authored arrival choices, hidden passenger on completion and durable mid-ride/completed reloads.
- **Still not a human playtest:** the sample remains a short authored ride with vector placeholders; readability/pacing across actual interactive Linux desktop gameplay should be confirmed before declaring the whole P1 milestone completely accepted.

## P1.5 — Visible Linux native walkthrough

- **Validated:** [Godot 4.7.2 Linux/Web workflow #38636571328](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38636571328) on implementation commit `6952a007d7cb201de43c602b1cd73e023496a8be`, including successful editor import, Ink/native session tests, Linux release export and boot, visible Linux native scene walkthrough, and exported Chromium Web journey.
- `tests/test_native_ride.gd` instantiates the actual `main.tscn` in an Xvfb-backed visible Compatibility renderer. It invokes the real native button signals and verifies pickup, authored choice and learned fact, ongoing time, arrival choices, completed one-time fare, hidden passenger, and native saved-state reload.
- The CI artifact `p1-ink-web-evidence` includes `native/waiting.png`, `native/traveling.png`, `native/arrived.png`, `native/arrival-choices.png`, and `native/completed.png`, all inspected alongside the existing browser screenshots.
- **Important visual-evidence boundary:** The native script fast-forwards route progress by 100 seconds instantly. Therefore the follow camera has not had 100 rendered seconds to catch up in its arrival screenshot; that particular frame is a valid scene/render and UI-state proof, **not** evidence of natural driving-camera pacing. The Chromium run progresses in real time and supplies the corresponding arrival framing.
- **Still requires a person:** judgment of readability, pacing, tactile feel, and moment-to-moment engagement of the ride on Web and desktop. The current world art and passenger portraits are intentionally placeholder. The automated P1 functionality is verified; these qualitative acceptance checks remain explicitly unrun.
