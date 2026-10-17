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

## Bidirectional taxi yield on the one grounded zebra — October 17, 2026

The original player-taxi right-of-way gate recognized `garage → margin_gate` but not a genuine **return trip** from `margin_gate → garage` over the exact same road. The physical crossing is still the one authored Patchworks zebra, not a new crossing or a second simulated city.

- `SandboxStreetRouteBinding.crossing_fraction(from, to)` returns **0.35** on the outbound route and **0.65** on the reverse route, accounting for the same `SandboxRoads.sample_edge` world geometry in opposite directions. Unrelated road edges remain ineligible.
- `on_edge`, `approaching`, `in_neighborhood` and `taxi_occupies_crosswalk` now use the direction-aware fraction. The actual native walker remains loaded while the returning driver approaches and waits.
- `SandboxWorld.restore_snapshot` validates a held route against either direction and the corresponding integer world-minute approach window, preserving the one-pair taxi yield event ledger and rejecting a forged release on the return trip.
- `test_taxi_crossing_world.gd` drives **garage → market → garage** through `margin_gate`, exercises the reverse held world clock, save/recovery, falsified release rejection and final arrival.
- New `test_taxi_crossing_return_scene.gd` runs an **actual Player Mode scene on a genuine seeded return drive** with a world-owned native walker. It verifies reverse native actor loading, holding while the walker occupies asphalt, mid-hold save/restore, the stale-completion guard, physically clear release and arrival at garage. There is no fabricated resident identity or hand-edited route segment.

**Evidence:** [Godot 4.7.2 native run #38991344179](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38991344179) is **11/11 PASS** at tested code `e3ef10c75b9fa0a6569732fd4b2678e816bcd321`, including new `TAXI_CROSSING_RETURN_SCENE_PASS`, outbound scene, world route, geometry, priority, pedestrian navigation/handoff and city presentation. [Real test logs](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38991344179/artifacts/12085546161). The preceding [run #38991209578](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38991209578) also passed 10/10 on the initial bidirectional world-route implementation at `df0df295`.

**Still bounded:** This is one grade-zero zebra, not general street generation, multiple simultaneously yielding NPCs, traffic lights, or a fully physics-driven taxi. Automated Web/Windows gameplay and subjective feel review are still pending. The scoped feature-branch Actions workflow runs on code pushes and ignores documentation-only updates. PR #61 remains stacked DRAFT, and issues #58/#59/#60 remain open.

## R10–R11: unloaded-pedestrian yield guard and actual elevated-road exclusion — October 17, 2026

**R10 — missing native actor is not clearance.** The previous player-taxi yield guard released its crossing latch as soon as `_street_pilot == null`. A pedestrian might still be in the road as a world-owned walking or offscreen resident. The new `SandboxLocalPedestrianTrip.crossing_cleared_without_actor(world)` checks the authoritative local trip state: `walking` blocks release, `offscreen` blocks until its deterministic progress exceeds the same body-clearance threshold as native physics, while already-arrived residents no longer block a clear road. This does not create a second NPC or tick the physical actor offscreen.

`test_taxi_crossing_unload_scene.gd` fault-injects the unloading of a **genuine native actor while the Player Mode taxi is already yielding**, verifies no phantom resume, a held world clock, save provenance, deterministic partial offscreen movement, resurrection of the **same resident** when the local scene reloads, and final clearance-based taxi release. A separate world-only subcase checks the positive offscreen-clearance transition. Actor removal while actively held is an **adversarial boundary simulation**, not a claim that ordinary proximity-driven unloading occurs on every ride.

**R11 — elevated road does not share the ground crossing.** `test_taxi_crossing_world.gd` now drives an actual route over `bridge_east → bridge_west` at its authored elevated deck height and verifies the Patchworks ground-level zebra cannot engage the hold, pedestrian neighborhood, or vehicle-occupancy check. This is a **route-and-grade isolation regression**, not full multi-grade lane collision.

**Latest verified evidence:** Native Godot 4.7.2 [run #38995029085](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38995029085) passed **12/12 targeted scripts** at `f593615b7906fa5cf1c4e2ecd2c89b6033da2d50`, including `TAXI_CROSSING_UNLOAD_SCENE_PASS` and the existing eleven. [Logs/artifact](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38995029085/artifacts/12086148377). The subsequent grade regression passed **12/12** at `671ab184057b91d7766eccdcf22a25750997c1f5`: [run #38995122278](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38995122278), [logs](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38995122278/artifacts/12086808015).

**Limits:** The actual player car is still a discrete world-road-graph taxi with a route-level priority hold, not a collision-enabled native vehicle; the physical pedestrian pilot remains one bounded Patchworks area. Multiple pedestrians or vehicles, all-district pedestrian networks, Web/Windows runtime and human gamefeel acceptance remain open.

## R12: two real lane bodies with crossing precedence — October 17, 2026

The Patchworks pilot now has **two local** `SandboxTrafficVehicle`/`CharacterBody2D` actors instead of one. They are **ambient cars confined to this street slice**, not invented extra residents, fare providers, or a second world-authoritative traffic model. The **player taxi remains** `SandboxWorld`'s single authoritative road-graph vehicle with its own bidirectional route-level crossing latch.

- The two ambient lane cars have distinct native collision shapes and the same authored lane; the leading body moves first. `SandboxStreetPriority.follower_velocity` bounds the trailing body's step against the updated leading position, maintaining a **42 px center-to-center gap** between **25 px** wide cars (17 px physical space) even on variable physics deltas or during a stop.
- `SandboxPedestrianActor` checks **both** local traffic cars before entering the marked zebra. A late-reserving walker still lets any car already beyond the stop line clear the crosswalk rather than creating a reciprocal traffic/pedestrian deadlock.
- The local actor snapshot stores **both car positions**, so a saved scene need not reset the trailing body to its starting point. The pedestrian remains the **same world-owned resident** and is not duplicated by the second car.
- Updated pure policy regression `test_street_priority.gd` verifies no overshoot, late reservation and following gap at several physics deltas. New native `test_street_multi_vehicle_scene.gd` deliberately holds a genuine resident's crossing reservation long enough for **both** native bodies to stop, validates their spacing each frame, releases the zebra, confirms both vehicles resume and the single resident arrives at the actual world-owned site. `test_street_pilot_scene.gd` separately proves *unstaged* navigation.

**Latest verified native gate:** [Godot 4.7.2 Actions run #38996674793](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38996674793) at source `3d073f69cfd1386b26c244af67eb9a152558d470` — **13/13 targeted scripts PASS**, including `STREET_MULTI_VEHICLE_PASS` and the twelve existing pedestrian/player-taxi/save/bridge scenarios. [Native proof logs](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38996674793/artifacts/12086599331). Three earlier [trial runs #38996322337](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38996322337), [#38996504217](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38996504217) and [#38996527993](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38996527993) failed in the *new test*: an overconstrained natural-time stopping assertion, then detecting initial zero velocity before a first native physics tick; these test errors were corrected and the final full suite passed.

**Not yet implemented:** arbitrary independent cars with world travel itineraries, cross-district multi-car traffic, multiple simultaneous pedestrian reservations, intersection arbitration, player-controlled native car physics, exported Web/Windows runtime validation or human traffic-feel signoff. The draft remains stacked over #55.

## R13: independently routed resident shuttles are visible as actual city traffic — October 17, 2026

The city already has an **authoritative** independent transit system: when a real NPC fare offer expires, `SandboxAutonomy.begin_expired_trips` may choose a paid municipal `shuttle`, recording `npc_alternative_departed`, a complete `transit_nodes` road path, `transit_started`, `transit_until`, and cost against that **same** resident. `SandboxWorld.advance` eventually records `npc_alternative_arrived` and updates the resident's genuine destination.

Previously, `SandboxCityView._draw_people` always rendered that resident as a walking stick figure, even while `transit_method == "shuttle"`. R13 closes this presentation/authority mismatch:

- New focused `SandboxWorldTraffic.shuttle_pose(world,npc,fraction)` **reads**, never advances or mutates, an active genuine shuttle trip. It derives vehicle position directly from `SandboxWorld.npc_position`, route orientation from the same `SandboxRoads.position_on_path`, and retains the real `resident_id`/`transit_from_offer` provenance. Unrelated `walking` or completed trips do not qualify.
- The actual world city renderer draws a distinguishable shuttle/car silhouette on the appropriate ground/elevated drawing layer, instead of a person marker. Its visual fraction moves even while the **player** is parked, and the renderer does not spawn an extra NPC, provider, driver, or vehicle itinerary.
- New `tests/test_world_shuttle_visual.gd` lets the *real seeded NPC economy/dispatch* expire fare offers and choose an independent shuttle. It checks the departure event, world position, fractional interpolation, a valid restored active trip, rendering with no world mutation, exactly-once NPC arrival and removal of the shuttle pose when travel ends. No fabricated transit state is injected.
- **Actual Godot 4.7.2** [run #38997839533](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38997839533) at source `ac935a612822b20fd0954e8dd68aa5606dbc01da` passed **14/14 targeted tests**. [Native logs](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38997839533/artifacts/12087698352), including `WORLD_SHUTTLE_VISUAL_PASS` and all previous native walking, two local physics cars, taxi yield, near/far, save and bridge checks.

**Important scope boundary:** A world-owned *passenger's shuttle journey* is now faithfully represented by a world-positioned car silhouette. This is **not** yet a separately modeled persistent municipal shuttle fleet, a `CharacterBody2D` under local pedestrian traffic control, a proof of traffic-light/vehicle collision arbitration, or proof of exported Web/Windows gameplay. The two ambient physics vehicles in Patchworks remain a separate, bounded local demonstration. Multi-car junction arbitration and full lane ownership remain open.

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

## Follow-up: late crosswalk reservation vs vehicle already past stop line — October 17, 2026

A P0 audit found a possible deadlock in the **local demo traffic vehicle**: if the resident reserved the zebra a fraction of a frame after the car had crossed its stop line, the old `SandboxStreetPriority.vehicle_velocity` returned zero before the car cleared the crossing. The pedestrian simultaneously waited for that car to leave the lane. Neither could progress.

- If a car is still at or before the stop line when a pedestrian has reserved the crossing, variable-frame step clamping keeps its front at or before that line.
- If the car is **already beyond** its stop line, it continues forward to clear the zebra rather than freezing inside it. `pedestrian_may_enter` now refuses entry for any car beyond the stop line until the car passes the clear-ahead threshold. The former 4 px grace after the line was removed.
- `tests/test_street_priority.gd` now reproduces the late-reservation race from **0.01 px beyond the stop line**, checking finite time to clear the pedestrian crossing, pedestrian entry gating and existing variable-delta braking bounds.
- Godot collision and the physical actor's waiting rule remain necessary; this narrow fix does **not** establish multi-car traffic, collision-free city-wide driving or a physics-body player taxi.

**Native verification (2026-10-17):** [Godot 4.7.2 run #38986769410](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38986769410) passed **10/10 targeted tests** at source `ed3c7708f81b30708565993a854902521d8cf910`, including the new `STREET_PRIORITY_PASS` late-reservation deadlock regression. [Actual job logs and artifacts](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38986769410/artifacts/12082857942). This supersedes the previously pending status; the older [run #38967936158](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38967936158) remains evidence for its own earlier code head. The scoped CI runs on feature-branch pushes; documentation-only changes are ignored.

## Follow-up: release only after the pedestrian body clears the actual lane — October 17, 2026

The original walker set `crossing_completed` at `position.y > 370`, even though the authored vehicle road continues to **y=376** and the pedestrian owns a **7 px radius collision body**. That meant the real player taxi could release its route hold while the pedestrian still overlapped the traffic surface. This is separate from R07's *late reservation / demo-car deadlock*.

Changes in stacked PR #61:
- `SandboxStreetModule` now derives a clearance boundary from the actual authored road edge, the walker collision radius, and 1 px margin: **y=384** in the current Patchworks geometry.
- `SandboxPedestrianActor` uses that same physical clearance to mark crossing completed, instead of the previous hard-coded y=370.
- Deterministic `crossing_finished(progress)` for the offscreen handoff uses the same source-derived boundary.
- The normal Player Mode taxi will **not** release a world-route hold merely because `crossing_completed` is true. It also requires that the visible walker's physical position clears that boundary. A nearby pedestrian that is blocked midway through crossing therefore holds the taxi while the world clock continues.
- Targeted GDScript regressions were added/extended in `test_street_module.gd` (geometry and offscreen threshold), `test_street_pilot_scene.gd` (real native actor position), and `test_taxi_crossing_scene.gd` (stale completion flag, blocked mid-lane NPC, mid-hold save/reload and lawful release).

**Verification now PASS (2026-10-17):** 14/14 preliminary source/geometry static checks were followed by a **real Godot 4.7.2 native suite**: [run #38986769410](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38986769410), **10/10 tests passed** at code `ed3c7708f81b30708565993a854902521d8cf910`. This includes `STREET_MODULE_PASS`, `STREET_PRIORITY_PASS`, `STREET_PILOT_PASS`, `STREET_JUNCTION_PASS`, `NPC_INTERPOLATION_PASS`, `STREET_MAIN_PASS`, `STREET_HANDOFF_PASS`, `TAXI_CROSSING_WORLD_PASS`, `TAXI_CROSSING_SCENE_PASS` and `CITY_PRESENTATION_PASS`. Real runner logs show the lane-clearance and stale-flag scene case passing. [Evidence artifact](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38986769410/artifacts/12082857942). Not yet Web/Windows or human driving acceptance.

**Remaining risk:** This is a bounded crossing. Player taxi movement is still discrete authoritative road-graph progress rather than a physics-body braking/collision model; reverse-direction crossing, missing/despawned walkers, prolonged obstructions, network-wide traffic and grade-separated cases need further acceptance.

## Next increment
The amended priority and taxi scene regressions **passed on native Godot 4.7.2** in run #38986769410. Opposite traversal, forced actor-unload/restore boundaries and one elevated viaduct route have now passed targeted native tests. Next implement bounded interaction across multiple active walkers/vehicles and verify exported Web/Windows presentation plus actual human traffic-feel. Afterward broaden the street-module pilot to additional regular blocks while keeping the current one-world near/far handoff model.

Feedback: [#59](https://github.com/MohamedXIV/outsider-driver-2d/issues/59), [#60](https://github.com/MohamedXIV/outsider-driver-2d/issues/60), [#58](https://github.com/MohamedXIV/outsider-driver-2d/issues/58), [#57](https://github.com/MohamedXIV/outsider-driver-2d/issues/57).
