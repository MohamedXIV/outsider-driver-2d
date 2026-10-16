# Patchworks street-navigation pilot — implementation in progress

This **bounded standalone proof scene** is opened as `res://scenes/street_pilot.tscn`. It is **not yet the city-wide runtime navigation system**, and is intentionally not the default playable game scene.

## What is real in the proof
- Godot `NavigationRegion2D` with two distinct manually authored `NavigationPolygon` sidewalks. Vehicle pavement is NOT part of pedestrian polygons.
- `NavigationLink2D` crossing at the **only** marked zebra crossing.
- Actual `CharacterBody2D` resident with `NavigationAgent2D` and built-in local avoidance; the script applies velocity via Godot physics.
- A physical prototype `CharacterBody2D` car on a lane; yielding is governed by an explicit crossing rule rather than arbitrary navmesh traversal.
- One real `SandboxWorld` seeded resident (`npc:07`, garage home) is given a local parts-counter errand and reports real arrival to the same world, which validates intent and commits one provenance event. This is a **test fixture**, not a fixed first passenger or automatic city-wide errand.
- Simple orthogonal pavement, frontage/building blocks and crossing markers to validate the modular street-building approach from #58.

## Actual native test evidence (2026-10-16)

**PASS:** [Targeted Godot 4.7.2 native runner #38954467799](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38954467799), tested source commit `c8bde5e5204352f3d4170889cb69e729177c0fae`.

- Full project editor import / parse passed.
- `test_street_pilot_scene.gd`: `STREET_PILOT_PASS native agent, sidewalks, crosswalk, yielding, one world-owned arrival and restore`.
- `test_npc_interpolation_scene.gd`: `NPC_INTERPOLATION_PASS parked taxi continuously updates resident render fraction`.
- Linux Xvfb + software OpenGL + Dummy audio driver; this was **actual native Godot runtime**, not a static code inspection. No full Windows/Web test of this new pilot.
- The initial failed CI attempt [#38954310347](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38954310347) had successfully printed `STREET_PILOT_PASS` but CI incorrectly flagged an unavailable ALSA audio device. The second run corrected test environment by selecting Dummy audio, without changing game code.
- After the successful targeted run, the new gate was returned to **manual-only** triggering to preserve GitHub Actions minutes.

## Next incremental integration — main city, not just the pilot

- The default `sandbox.tscn` now can instantiate a **spatially embedded** Patchworks street module when the player is parked at the garage and a genuinely idle eligible resident has a local work/supplies errand. It uses the **same** `SandboxWorld` and `SandboxLocalPedestrianTrip.candidate(world)`, not a second seed or a fixed first passenger.
- In-world `SandboxPedestrianActor` targets and crossing control now correctly use global navigation positions vs parent-local traffic coordinates. The street module is positioned near the garage in the game's real projected world.
- The duplicate coarse `CanvasItem` NPC marker is suppressed for a resident with a local trip. Dispatch does not create a taxi offer while the resident is physically walking.
- Save/load now stores the **presentation actor's** local position/crossing flags separately from the authoritative trip + provenance event, while the latter remains in `SandboxWorld`. This avoids treating physics frame positions as world-tick economic state. Old experimental saves are not a compatibility gate.
- Only **one** nearby street module is instantiated; this is not a whole-city native navigation migration. Its physical actor continues running if the camera leaves the garage (acceptable for this one actor, not a completed far-simulation handoff).
- New targeted `tests/test_street_main_scene.gd` checks real default scene integration and mid-walk save/reload; Godot/Chromium execution must be verified before claiming completion.

## Main-scene integrated native proof (2026-10-16)

**PASS** — [Native Godot 4.7.2 run #38956333840](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38956333840), integrated test source `3018be6f6e0935f4ea2043b5a80738fcc418e9a2`.

The actual Xvfb / software OpenGL runner completed all four checks:
- `STREET_PILOT_PASS`: separate real sidewalk navigation regions, authorized crossing, yielding physical vehicle, once-only arrival and restore in standalone scene.
- `NPC_INTERPOLATION_PASS`: default scene advances NPC presentation while player's taxi is parked.
- `STREET_MAIN_PASS`: normal game scene instantiates a **real seeded world-owned resident** in local nav, actor physically advances, saves and restores mid-walk geometry, reports arrival once, and **rejects forged arrival from save state without event provenance**.
- `CITY_PRESENTATION_PASS`: previous city/bridge, passenger and save demonstration still works.

`test_street_main_scene.gd` also captures three local PNG frames in `/tmp/od2d-street-evidence/` on the runner, but those frames were **not published in the successful run's artifact**; do not assert independent visual review of those images. The uploaded artifact contains run logs. Native Linux only, not exported Chromium or Windows runtime.

The gate returned to **manual-only** after the run. No more Actions minutes should be used on docs/status updates.

## What is NOT implemented
- Migration of all existing autonomous walking residents away from `SandboxRoads.position_on_path`.
- **Full city-wide** native footpath network, reusable street-module generation and deterministic near/far ownership handoff. The garage slice is now embedded in the normal scene but is the only integrated neighborhood.
- Complete taxi physics/lane movement, complex intersection controls, signals, crowd avoidance or traffic simulation.
- No runtime gates have been claimed passed solely because the code is present. Run `tests/test_street_pilot_scene.gd` with a matching Godot 4.7.2 editor and native renderer before promotion.

## Next increment
After actual native visual proof, derive the sidewalk polygons, road lanes and crosswalk links from reusable street modules, integrate a resident's genuine world-generated pedestrian goal into the main scene, and ensure physics arrival is authoritative for nearby walkers. Preserve cheap off-screen schedules for distant residents and avoid frame-rate dependent economic randomness.

Feedback: [#59](https://github.com/MohamedXIV/outsider-driver-2d/issues/59), [#60](https://github.com/MohamedXIV/outsider-driver-2d/issues/60), [#58](https://github.com/MohamedXIV/outsider-driver-2d/issues/58), [#57](https://github.com/MohamedXIV/outsider-driver-2d/issues/57).
