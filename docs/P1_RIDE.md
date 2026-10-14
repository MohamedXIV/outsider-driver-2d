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
- **New acceptance not yet verified** until the updated commit's native tests, Web Chromium run, visual evidence and Linux export complete. Human pacing/legibility acceptance remains a separate gate; placeholders do not constitute finished art.
