# Patchworks street-navigation pilot — implementation in progress

The bounded `res://scenes/street_pilot.tscn` remains a standalone validation scene, **and** the `SandboxStreetPilot` street module is embedded in the default `sandbox.tscn` near Patchworks when a real resident walks. It is still **not** the city-wide runtime navigation system.

## What is real in the proof
- Godot `NavigationRegion2D` with two distinct manually authored `NavigationPolygon` sidewalks. Vehicle pavement is NOT part of pedestrian polygons.
- `NavigationLink2D` links at **authored marked zebras**; one original garage crossing plus east-block and T-branch crossings.
- Actual `CharacterBody2D` resident with `NavigationAgent2D` and built-in local avoidance; the script applies velocity via Godot physics.
- A physical prototype `CharacterBody2D` car on a lane; yielding is governed by an explicit crossing rule rather than arbitrary navmesh traversal.
- One eligible real `SandboxWorld` seeded garage resident is selected from world needs for a local parts-counter errand and reports real arrival to the same world, which validates intent and commits one provenance event. This is a **test fixture**, not a fixed first passenger or automatic city-wide errand.
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
- Targeted `tests/test_street_main_scene.gd` has passed in native Godot; exported Chromium gameplay remains unverified for this branch.

## Main-scene integrated native proof (2026-10-16)

**PASS** — [Native Godot 4.7.2 run #38956333840](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38956333840), integrated test source `3018be6f6e0935f4ea2043b5a80738fcc418e9a2`.

The actual Xvfb / software OpenGL runner completed all four checks:
- `STREET_PILOT_PASS`: separate real sidewalk navigation regions, authorized crossing, yielding physical vehicle, once-only arrival and restore in standalone scene.
- `NPC_INTERPOLATION_PASS`: default scene advances NPC presentation while player's taxi is parked.
- `STREET_MAIN_PASS`: normal game scene instantiates a **real seeded world-owned resident** in local nav, actor physically advances, saves and restores mid-walk geometry, reports arrival once, and **rejects forged arrival from save state without event provenance**.
- `CITY_PRESENTATION_PASS`: previous city/bridge, passenger and save demonstration still works.

`test_street_main_scene.gd` also captures three local PNG frames in `/tmp/od2d-street-evidence/` on the runner, but those frames were **not published in the successful run's artifact**; do not assert independent visual review of those images. The uploaded artifact contains run logs. Native Linux only, not exported Chromium or Windows runtime.

The gate returned to **manual-only** after the run. No more Actions minutes should be used on docs/status updates.

## Modular streets and near/far movement fidelity — verified 2026-10-16

**PASS:** [single targeted native Godot run #38960875587](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38960875587), source `191240ede20494d2a395a6f82599f75fcf208adf`. Six targeted tests passed in native Godot 4.7.2: `STREET_MODULE_PASS`, `STREET_PILOT_PASS`, `NPC_INTERPOLATION_PASS`, `STREET_MAIN_PASS`, `STREET_HANDOFF_PASS`, `CITY_PRESENTATION_PASS`. [Logs and captured integration PNGs](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38960875587/artifacts/12072821581). Captured images were uploaded but have **not been separately human-reviewed** for aesthetics.

- `SandboxStreetModule` is the single source of the Patchworks **road slab, sidewalks, one crosswalk, traffic lane, lot footprints and walker path waypoints**. A straight 4-point path supports interpolation anchors; active walking still uses Godot's `NavigationAgent2D`/physics, not a replacement scripted route.
- On leaving the garage neighborhood, the player-scene native actor is uninstantiated and the **same** `SandboxWorld` resident changes to `offscreen`, recording `local_pedestrian_handoff` with a bounded spatial progress anchor.
- During offscreen world ticks, the resident advances on an **inexpensive deterministic coarse clock**, with no physics body; only one true arrival is committed. Returning before arrival records `local_pedestrian_resumed` and instantiates the Godot actor at the reconciled shared module position (using `NavigationRegion2D` and the legal crossing link again).
- The world validates each resident's sequential local departure/handoff/resumption/arrival provenance in save restoration; tampering a previous progress anchor does not load. A resident with an already-completed local errand cannot restart the same trip accidentally.
- Presentation hides only the active nearby actor's **duplicate** coarse marker (and any offscreen walker), leaving other NPC visibility intact.
- `SandboxPopulation` treats an in-progress local errand as travelling; no new fare is generated for that walking NPC.

**Deliberate limits:** This is **one authored Patchworks street module**, not automated six-district sidewalk generation, complex intersections, human acceptance or full pedestrian-car traffic in the normal taxi driving routes. The taxi still follows the legacy route-graph presentation; the demonstrator traffic car yields locally. No Web/Windows play-through of this new slice is claimed. The Godot action is now returned to **manual-only** to conserve CI minutes.

## Two-block Patchworks junction + physical arrival verification — October 16, 2026

**Native PASS:** [Godot 4.7.2 run #38964666601](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38964666601), tested source `f7719f7cbf0128fb2ee90e2bbde3b0cf73641733`; **8/8 targeted tests** passed, including the existing city render and near/far/save invariants. [Test logs and previous integration captures](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38964666601/artifacts/12074197435).

- The existing `SandboxStreetModule` now also composes a **second connected east avenue block and a perpendicular T-branch**, with an explicit navmesh cut at the vehicle branch, two new `NavigationLink2D` marked crossings, and consistent block/lot paintings. Same actual Godot navigation map, no unrestricted paved-road polygon.
- `test_street_junction_scene.gd` verifies Native `NavigationServer2D.map_get_path` routes across the T crossing, between the connected blocks and along a branch sidewalk. `test_street_module.gd` verifies the contiguous module geometry.
- `SandboxStreetPriority` provides a small, testable local **vehicle stop-line/yield contract**, with speed capped by distance-to-stop-line and physics frame duration; the existing demonstration traffic car uses the shared policy. Tests confirm no step overshoots the stop line and residents wait for a vehicle already occupying the crossing.
- **Important fix:** `SandboxPedestrianActor` now resolves target coordinates from the **street-module parent**, not the moving pedestrian's own transform. Arrival is accepted only when the body is physically within 9 px of the authored parts-counter location; both standalone pilot and main-game tests assert it. This prevents false arrivals from clipped/ended nav paths.
- The previous two failed runs [#38964285698](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38964285698) and [#38964401215](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38964401215) stopped at an incorrect test lookup of a child NavigationAgent2D node by auto-generated name, *before* checking the new route graph. The test was corrected to use the actual typed actor reference; final run passed all 8 tests. The target-coordinate bug was independently corrected and added to strict site-distance checks.

**Still not done:** This is NOT yet a generalized arbitrary-city street-tile builder or a complete junction controller; module composition is still authored locally at Patchworks. The physical yielding car is a **traffic demonstrator, NOT the player taxi**. The game's actual player car is still world-road-graph-driven, and requires grade-safe lane alignment + crossing events before native collision/yielding can safely govern fares. No Web/Windows or human gamefeel validation on this PR yet. Keep #58/#59/#60 open.

**CI policy:** One focused native suite is now PASS; branch-scoped automatic Actions triggering has been removed again. Manual-only for any subsequent required release gate.

## Real player taxi at a grounded Patchworks zebra — verified

**Godot 4.7.2 native PASS:** [run #38967936158](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38967936158), code SHA `fb7e6a23643c4d0fa238dd99e8e550b9991cb094`. **10/10 targeted checks** passed; [logs and PNG evidence](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38967936158/artifacts/12074764453). Earlier street/junction, nearby/offscreen, NPC render, save and bridge presentations still passed.

- `SandboxStreetRouteBinding` places the module's **first zebra crossing center on the actual grade-zero `garage → margin_gate` world road edge** (sampled at 35% of that physical path), orienting its local lane along the sampled route tangent. The nav polygon, physical walker and crossing painting now share the world-road location; the rest of the city still retains its existing curve geometry and elevation graph.
- `SandboxWorld.begin_crossing_yield()` and `release_crossing_yield()` are **world-owned one-way traffic events**, with an audited `route_hold_id` save field. A hold is allowed only on the actual ground-level approach to this authored zebra. The **city clock and resident ecology keep ticking**, while the player's route segment, remaining travel time, credits and fare settlement remain held until the crossing clears. The renderer also clamps the taxi visual fraction so it does not animate through a stop.
- The normal `sandbox.tscn` keeps the active native pedestrian in the nearby garage-to-feeder corridor while the taxi approaches. The pedestrian waits while an unheld player taxi physically occupies the crosswalk, and the driver yields to a pedestrian who already reserved it. The existing near/far handoff unloads the walker after the player is actually outside the neighborhood.
- `test_taxi_crossing_world.gd` exercises a real reroute, safety-gated world hold, ongoing clock, mid-hold world snapshot/restore and matching ledger start/end, followed by route continuation and normal arrival. It also rejects a forged save that clears the hold without a matching end event.
- `test_taxi_crossing_scene.gd` loads **Player Mode**, finds the world-aligned crossing, holds the real player taxi in a staged native pedestrian-crossing case, saves/loads mid-yield and verifies that the same taxi route resumes after the crossing has cleared. The older eight native tests remain green.

**Not yet a physics-driven player car:** the player taxi is still the authoritative **`SandboxRoads` world-route vehicle**; this is an actual game-rule yielding stop on one validated lane-edge, **not** `CharacterBody2D` car steering/collision, a global traffic graph, traffic signals, grade-independent pedestrian crossing or proof of all six districts. The previous local demo vehicle remains useful for checking the native stop line. Native Linux only; exported Web/Windows and human gameplay acceptance have **not** been run for this latest change.

The scoped Actions runner is **manual-only** again after this passing validation. PR #61 stays stacked DRAFT over PR #55, with #58/#59/#60 open for generalized district lanes, junction controls, player-car bodies and visual playtests.

## What is NOT implemented
- Migration of all existing autonomous walking residents away from `SandboxRoads.position_on_path`.
- **Full city-wide** native footpath network, reusable street-module generation and deterministic near/far ownership handoff. The garage slice is now embedded in the normal scene but is the only integrated neighborhood.
- Complete taxi physics/lane movement, complex intersection controls, signals, crowd avoidance or traffic simulation.
- No runtime gates have been claimed passed solely because the code is present. Run `tests/test_street_pilot_scene.gd` with a matching Godot 4.7.2 editor and native renderer before promotion.

## Next increment
After actual native visual proof, derive the sidewalk polygons, road lanes and crosswalk links from reusable street modules, integrate a resident's genuine world-generated pedestrian goal into the main scene, and ensure physics arrival is authoritative for nearby walkers. Preserve cheap off-screen schedules for distant residents and avoid frame-rate dependent economic randomness.

Feedback: [#59](https://github.com/MohamedXIV/outsider-driver-2d/issues/59), [#60](https://github.com/MohamedXIV/outsider-driver-2d/issues/60), [#58](https://github.com/MohamedXIV/outsider-driver-2d/issues/58), [#57](https://github.com/MohamedXIV/outsider-driver-2d/issues/57).
