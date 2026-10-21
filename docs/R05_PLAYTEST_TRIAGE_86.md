# Playtest triage #86 — player-reported stalls and frame drops

Human Windows x64 preview feedback (2026-10-21) is the acceptance authority.
These changes are diagnostic and a small read-only UI indicator, **not a
claim that the vehicle or pedestrian deadlocks are already fixed**.

`test_playtest_liveness_scene.gd` starts the actual unmodified seeded World
at the observed Clinic location, asks for its regular authored route to the
Mutual Aid Hall, and drives native vehicle/traffic collision execution in the
real `sandbox.tscn` with no fake occupants, while recording per-40-frame:
- World minute, remaining time, route edge and native progress
- `vehicle_execution.player.reason` / actual speed and `route_hold_id`
- number of loaded vehicle and pedestrian bodies
- Godot live node count and sampled real process/physics time
- whether the taxi can complete the route without >25 World-minute zero progress

In Player Map, a trip in progress now explains *why* Drive is disabled.
If native execution is stopped by a real physical obstacle, the text
distinguishes pedestrian / junction / vehicle reason, without issuing a
reroute, cancel, world tick, fake release or teleport.

These are **first diagnostic gates**; the old World-projected people and
native-agent residents remain separate. Next steps depend on the actual
targeted failure telemetry and need a deterministic repro for the claimed
everlasting stop and quantitative desktop frame degradation. No production
Release until the tester verifies both.
