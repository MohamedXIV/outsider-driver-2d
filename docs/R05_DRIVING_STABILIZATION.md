# R05 driving stabilization — October 19, 2026

This batch extends the existing #73 stack. `SandboxWorld`, the road graph,
canonical journey minutes, residents, event provenance and settlements remain
unchanged. #75's rider initiative remains a downstream dependency.

## Player-visible changes

- Wait sits above autonomous street requests. A legitimate offer expiry no
  longer moves its click target between observing the UI and delivering input.
  The native regression exercises real mouse input and exactly one 20-minute
  World command across a real autonomous offer transition.
- Native street/junction cars predict stopping distance with a whole-frame
  reserve. The junction predicts leader clearance and its terminal queue,
  rather than braking abruptly only when movement hits a hard boundary.
- The directed taxi respects World-owned pedestrian holds in both position
  and heading samples. It no longer advances then snaps back every World tick.
- Authored lane sections taper onto the existing centerline presenter at
  unprofiled boundaries. All 96 legal non-U-turn graph triples meet continuously;
  existing Docks–Clinic–Basin Bend connectors and four-lane Freight Spine remain.
- Parking inherits the latest real inbound edge at every profiled stop. The
  next departure blends from that event-owned pose onto the selected lane.

## Evidence and regression design

The unmodified #73 domain/adapters and native gates passed on Godot
`4.7.2.stable.official.ed1daf0bf`. The historical Chromium failures were inspected
from runs 39206929259 and 39206978826. The native pointer regression reproduced
Wait moving from `(216,467)` to `(216,278)` when an actual offer expired at
minute 524; after repair both coordinates are `(216,217)`.

The local pinned-browser diagnostic completed both genuine journeys, but its
console assertion failed on stale UIDs in a preloaded `.godot/exported` cache
from October 16. That generated cache was rebuilt before verification. The
scratch diagnostic's longer observation window is not a passing gate; committed
browser timeouts and fare assertions are unchanged.

- `test_player_wait_scene.gd`: genuine offer transition, stable target, actual
  mouse press/release and once-only authoritative wait.
- `test_junction_braking_scene.gd`: actual CharacterBody movement at 10/30/60 Hz,
  bounded acceleration/braking through FIFO stop lines, downstream congestion
  and terminal queues, stop/resume and restored queue/owner/speeds/positions.
- `test_directed_lane_continuity.gd`: held render pose and tangent progress,
  snapshot provenance, all authored junction triples and a real next departure.
- `test_lane_visual_scene.gd`: sequential native screenshots and JSON pose
  evidence, immutable World snapshot and restored held pose.
- `web_city_routes.cjs`: existing real two-fare scenario, plus three sequential
  driving frames with finite authoritative/render coordinates and hold checks.
  It still requires two settlements and zero browser errors.

The native before/after sequence is committed under
[`evidence/r05-2026-10-19`](evidence/r05-2026-10-19). Each frame records the same
resident count (9), minute (483), World position and crossing owner. Before the
fix, render motion across the five frames is 20.976 pixels (about 54.5 screen
pixels at 2.6x zoom); afterwards it is zero. These frames isolate the presenter
at a valid World-owned hold; they are not a human gameplay acceptance test.

Run the existing exact-head gates with the pinned editor/templates:

```sh
GODOT_BIN=/path/to/godot-4.7.2 python3 tests/run_city_gate.py
DISPLAY=:99 GODOT_BIN=/path/to/godot-4.7.2 python3 tests/run_city_gate.py --native
GODOT_BIN=/path/to/godot-4.7.2 python3 tests/run_exported_gate.py --scope current
```

Final immutable heads, actual PASS/FAIL/NOT RUN results and Web evidence belong
in the PR descriptions and the task's final verification report.

## Scope still requiring acceptance

This is a stabilization and continuity batch, not completion of every #67/#68
acceptance criterion. Native FIFO traffic remains the existing bounded ambient
kit; genuine municipal shuttles still follow World-owned deterministic lane
projections. This batch does not turn the complete authored metric corridor
into one collision-simulated World-owned taxi/shuttle queue, or add a second
traffic/economy clock. The wider nearby-vehicle integration, remaining presenter
load/unload boundaries and human visual/gameplay acceptance stay open.

No merges to main or issue closures are part of this batch.
