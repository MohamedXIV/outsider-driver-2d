# Living Streets Core P0 (#82)

This branch builds on the verified Core + Player UI integration `5f0aea609b4ce17d5029bbb8c6684e88576076db`, including city geometry `0648fc49`. It targets `feat/r05-player-guidance`; no upstream lane is rewritten.

Ordinary World ticks choose at most two existing eligible garage residents from their purpose (`supplies`/`work`), need, availability, open offers, cooldown and opening hours (06:00–22:00). Seed 29 naturally supplies `npc:04` and `npc:08`. There are still nine residents. No debug errand command, new clock, reward, fake fare or new population exists. Departures enter the existing coarse movement policy until a real nearby presenter resumes them. This also keeps World-only saves valid when no native bodies exist.

The first goal uses the parts-counter bay on the existing wide south pavement; the second continues along the connected pavement into the adjacent block to `(700,391)`. The counter bay leaves room for the second walker to pass a stopped resident. Godot `NavigationAgent2D`, native bodies, the marked crossing link, existing curb geometry and crossing/vehicle policies still control physical movement. The leading resident has higher native avoidance priority so a follower cannot push it past the counter and outside the save/handoff corridor. Arrived agents have stationary avoidance priority; displaced agents whose native path has finished request a fresh native path instead of claiming arrival. Actual destination proximity remains the native completion gate. A completed small local service relieves 30 need (floor 10), applies the existing 30-minute cooldown convention, and records before/after need in the arrival event. It does not settle a fare or complete the resident's distant city destination.

The presenter observes new World intents at the tick boundary and during physics, so eligibility arising after the street has loaded can create a body without reloading the scene. Dynamic claims use the current World fraction, including a save before the first departure, rather than the module’s original reentry fraction. A missing walking body is not respawned at a guessed start pose: its reservation fails closed until an explicit pose-preserving handoff/restore. Native pose, crossing reservations, car progress and event provenance continue through the existing save and near/far contracts. Far travel retains the existing approximate eight-minute distance-progress policy; this is not used to declare arrival for a loaded native actor.

## Reproduction and verification

Run with Godot **4.7.2**. In ordinary sandbox gameplay, seed 8 has one initial local resident; seed 29 has two. The existing Debug new-seed control can select the population scenario, but does not trigger errands. Stay parked at Patchworks to watch departures on the next World tick, curb waiting, legal crossing, the two destination arrivals and local vehicle yield. The same street stays active while driving through its proximity region.

- `tests/test_living_streets.gd`: autonomous World departures, persistence, no duplicate departures, adjacent goal and real need relief.
- `tests/test_living_streets_scene.gd`: normal realtime World ticks in `sandbox.tscn`, two genuine native actors, separation, legal crossing, traffic yield, exact mid-crossing save/load poses and unchanged ledger, adjacent-block arrival. Ordered `LIVING_TRACE` output and an actual rendered screenshot are produced.
- `tests/test_pedestrian_replan_scene.gd`: native finished-path recovery after physical displacement.
- Existing two-resident native tests cover unreachable destinations, independent reservations, cancellation, taxi/shuttle yield, handoff and save restoration. Fixtures now wait for a World tick instead of relying on presentation-owned departure.
- `tests/web_two_residents.cjs`: exported current-world seed 29 gameplay, two moving bodies, live save/reload, narrow viewport, once-only events and a physical adjacent-block goal; writes `living-streets-ledger.json` alongside screenshots.
- Full regression commands: `python3 tests/run_city_gate.py`, `python3 tests/run_city_gate.py --native`; exported current-world checks: `python3 tests/run_exported_gate.py --scope current`. Use a real display or Xvfb for native tests and installed matching export templates/Playwright for Web.

Exact commit IDs, executed commands, results and any baseline failures belong in the Draft PR handoff after execution. A failed check is not acceptance.

## Bounds and human gates

This is one living block pair, with one persisted local errand per eligible resident per world history, not citywide recurring pedestrian life. The adjacent destination uses the existing south pavement and does not require another road crossing. Other authored junction/crosswalk proofs are retained, not promoted into a citywide traffic system. Far movement remains coarse; locally loaded bodies require genuine physical arrival. Windows gameplay, Linux human pacing/observability and driving feel remain human playtest gates. Keep the PR Draft, keep issues open, and do not release or merge to main.
