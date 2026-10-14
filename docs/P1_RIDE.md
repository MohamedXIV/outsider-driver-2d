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
