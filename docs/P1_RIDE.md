# P1.3 — First Ride & Authoritative Session

One authored job/passenger and taxi route through the existing Godot world.

## Contract
- `GameSession` owns world clock, pickup/arrival/completion phase, taxi progress, credits, knowledge, suspicion and idempotent story-event application.
- `InkBridge` owns only an interpreter state/presentation snapshot, never credits, relationships or taxi status. Ink tags become explicit player consequences through `GameSession.apply_story_tags`.
- World time continues each frame (including pending dialogue and after arrival); taxi stops at the destination without freezing the world.
- `We've arrived` is an intentional safe-exit action. No arbitrary cut-off of a dialogue line.
- `drop_off` succeeds once, credits +18 once, subsequent calls return false.
- Fresh schema v1 saves `GameSession` state plus exact Ink interpreter state through `RideSave`. No backward compatibility burden.
- The current road and passenger graphics remain placeholders; real story content is intentionally small.

## Validation
Pending targeted Godot 4.7.2 integration: native session/idempotency/persistence tests, Ink state-restoration tests, exported Linux/Web and an actual browser trip from pickup through dialogue to arrival and completion.

Do not claim P1 complete before a real ride runs end to end.
