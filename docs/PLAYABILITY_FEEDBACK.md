# Outsider Driver — Playability Feedback Register

> **Living human-feedback register / first entry October 16, 2026.** [Central discussion & workstream board: #48](https://github.com/MohamedXIV/outsider-driver-2d/issues/48). [Execution roadmap](SANDBOX_EXECUTION_ROADMAP.md). This is a product feedback record, NOT a QA pass, sprint calendar or duplicate implementation backlog.

## Baseline: what is actually known

- **Gameplay:** Godot 4.x 2D / axonometric sandbox driven by one authoritative `SandboxWorld`; systemic nine-NPC sample, real Ink conversations, priced translator/AR equipment, physical store, seeded fare dispatch, road graph routes, reroute and persistent social encounters. [Last verified baseline before this feedback](https://github.com/MohamedXIV/outsider-driver-2d/commit/4c9c848b467baa4a1bcb4b30c35f31504db62936).
- **Historical pre-reboot visuals:** `SandboxRoads` had **five district nodes** linked by a simple graph; `SandboxCityView` draws **straight lines** between district projections and interpolates taxi motion linearly. This is a schematic playable engineering sample, *not* evidence of a real-scale, physically rich city or believable bridges.
- **Human feedback:** user reports information overload / confusing debug text, rushed and fragmented trip experience, and wants naturally larger urban distances, engaging UI and curved/elevated natural-looking roads.
- **Checklist baseline (R01):** the user explicitly answered **False to all four playability questions for the CURRENT debug dashboard**, and cautioned that applying that checklist here is **misleading** because the required Player Mode / world presentation does not exist yet. Treat this as **4/4 presently unmet in the prototype**, **not** an isolated assessment of the finished design or four independent root causes. Detailed scenario-by-scenario feedback, numerical pacing score, artistic reference and user approval of a revised Player Mode/large city/splines are NOT provided. Do not invent these. Green native/Web checks prove functional gameplay invariants, **not** human comfort or appearance. Windows release export is not actual Windows runtime.

## Long-lived observations (IDs never recycled)

| ID | Original observation / direction | Owner issue | Priority | Current status | Technical proof | Human acceptance |
|---|---|---|---|---|---|---|
| **FB-001** | Trips feel too short and pressuring to notice passenger, read/talk, enjoy road scenery. **Approved correction:** a sufficiently large and varied city should naturally give rides breathing room, rather than fake time dilation. | [#51](https://github.com/MohamedXIV/outsider-driver-2d/issues/51) | High | **Implemented / Ready for human check** | [Integrated implementation, tests and captures](CITY_PLAYTEST.md) | **Pending** |
| **FB-002** | Existing on-screen diagnostic texts cause confusion and compete with playing. **Approved:** default Player Mode + explicit reversible Debug Mode for developer telemetry. | [#49](https://github.com/MohamedXIV/outsider-driver-2d/issues/49) | First slice | **Implemented / Ready for human check** | [Integrated implementation, tests and captures](CITY_PLAYTEST.md) | **Pending** |
| **FB-003** | Roads should look organic: splines/curves, real-feeling bridges, flyovers and sensible elevation instead of toy straight lines. | [#52](https://github.com/MohamedXIV/outsider-driver-2d/issues/52) | High, coordinated with #51 | **Implemented / Ready for human check** | [Integrated implementation, tests and captures](CITY_PLAYTEST.md) | **Pending** |
| **FB-004** | Player HUD should be attractive, intuitive, supportive and readable, rather than merely debug controls with colors. | [#50](https://github.com/MohamedXIV/outsider-driver-2d/issues/50) | High, builds on #49 | **Implemented / Ready for human check** | [Integrated implementation, tests and captures](CITY_PLAYTEST.md) | **Pending** |

| **FB-005** | First revised-build playtest: camera is far too distant; user asks for adjustable zoom-in/out as previously discussed. Existing Camera2D zoom is hardcoded at `(2,2)`. | [#56](https://github.com/MohamedXIV/outsider-driver-2d/issues/56) | High UX | **Reported / planned; not implemented** | Root code seam identified, no new runtime proof | **Pending** |
| **FB-006** | Roads and especially bridges are visually unsatisfactory (known placeholder limitation). User is **considering** straighter, regular/modular geometry for practical city layout, standardized building blocks. Not a final prohibition on curves. | [#58](https://github.com/MohamedXIV/outsider-driver-2d/issues/58), follows [#52](https://github.com/MohamedXIV/outsider-driver-2d/issues/52) | High art/layout direction | **Exploratory proposal; not implemented** | Earlier graph/bridge tech proven; geometry presentation rework not tested | **Pending** |
| **FB-007** | NPCs move smoothly sometimes and visibly step/jump at other times. Likely render interpolation freezes when player's taxi is parked, despite NPC simulation continuing. | [#57](https://github.com/MohamedXIV/outsider-driver-2d/issues/57) | High polish/correctness | **Reported / cause suspected; not fixed** | Code inspection; visual reproduction after fix pending | **Pending** |

**Checklist correction:** The user has now given a **pre-reboot baseline verdict of False on all four questions**, while explicitly stating that scoring a debug-world/dashboard as a game is misleading. This is captured in **R01**, not treated as four independent gameplay defects, and is **not a verdict on a not-yet-existing Player Mode**. More detailed scenario-based notes remain optional/pending. **Do not prompt repeatedly, invent responses, schedule mandatory check-ins or mark a category approved by the user beyond the directions actually stated.**

## Lightweight recurring review protocol — trigger on feedback or a new playable build

This is a workflow triggered by actual iterative gameplay/builds, **not** a background automation:

1. **Intake:** User comment / screenshot / recording → append a dated entry under "Feedback rounds" with platform, build or SHA, seed and reproduction only when available. Unknown fields = `Not provided`.
2. **Classify:** associate an existing FB ID (or a new one), issue, perceived pain and severity if **reported**. Distinguish the user's own observation from the developer's explanation/hypothesis.
3. **Decide:** preserve original note, record accepted response `Do now / Later / Not planned` with reason and dependencies; re-rank a single authoritative board (#48 + child issues).
4. **Implement:** each PR records `FB-ID`, before→after, what was changed, exact acceptance scenarios, verified local/native/Web evidence with run and branch heads. Do not create unrelated major systems or run GitHub Actions for docs-only updates.
5. **Hand back:** move item to `Implemented (technical) / Ready for human check` after green code tests. Provide a concise tailored request to try **one or two relevant interactions**; do not dump another long checklist unless user asks.
6. **Review:** next real user impression records `Human accepted`, `Needs rework`, or `Unassessed`. If rework, edit the same issue / append the next round without erasing what previously shipped or passed. Summarize `Changed / Still painful / Next targeted experiment` in #48 and this register.

### Status semantics

`Reported` → `Accepted direction` → `In progress` → `Implemented (technical)` → `Ready for human check` → **either** `Human accepted` or `Needs rework`. `Deferred` and `Not planned` require an explanation; automated CI passing must **never** substitute for `Human accepted`.

### Entry format (copy for each new actual round)

```markdown
### Feedback round Rxx — <date> — build / SHA <if known>
- Environment / platform / viewport / seed: <reported or Not provided>
- User's own observation: <verbatim or attributed paraphrase>
- FB IDs / linked issue(s): #...
- Hypothesis (developer, explicitly an interpretation): ...
- Decision / change made (PR, commit): ... / Not implemented
- Technical evidence (native, Web, screenshot): ... / Not tested
- User re-test / verdict: Human accepted / Needs rework / Pending
- Remaining discomfort and next narrowly scoped experiment: ...
```

## Feedback rounds

### R00 — October 16, 2026 — initial perception
- **Environment:** user has begun checking the game; build/OS/seed/duration not specified in the feedback.
- **User observations:** overwhelmed by debug writings; journeys feel rushed/short for watching NPC/world and conversing; wishes visually natural roads, splines, bridges, flyovers, and attractive intuitive UI.
- **Approved refinements:** Player Mode default vs Debug Mode; a city large enough to create natural journey breathing room rather than arbitrary delay; track changes and feedback consistently.
- **Work registered:** #48 overarching, #49 mode separation, #50 player UI improvement, #51 city/ride scale and pacing, #52 road geometry/elevation.
- **Implementation of these changes:** Not started. The existing verified sim and renders are merely technical baseline.
- **Human verdict on revised build:** **Pending**; no revised build submitted. See R01 for the user's subsequently supplied *current debug-build* baseline of four False responses.
- **Next action:** implement #49 as the first independently playable slice; coordinate #51/#52 topology and track one real passenger ride and world/route visibility. Wait for user-provided checklist whenever they choose to send it.

### R01 — October 16, 2026 — user's four-point checklist baseline correction
- **Source / exact user distinction:** «الاجابة عن الـ 4 نقاط الـ Checklist هيكون مش مظبوط ومضلل لان الموجود الان debug world/dashboard لذلك الاربع نقاط الاجابة عليهم false».
- **Environment / build:** Existing debug world/dashboard; exact OS, viewport, runtime, seed and SHA of the session were **not provided**.
- **Checklist (as asked of the existing debug dashboard):**

  | Check from assistant's previous four-point list | User's answer | Interpretation |
  |---|---|---|
  | **1. Ride comfort:** enough time to observe and understand rather than feel rushed | **False** | Current debug travel gives no comfortable ride feel; the systemic city's eventual pacing is **not separately assessed**. |
  | **2. UI clarity:** know what to do without a wall of text | **False** | Dashboard-first UX fails as a game-facing interface; no Player Mode build exists yet. |
  | **3. City believability:** roads and movement evoke a convincing city | **False** | Current schematic five-node straight-line roads are not representative of intended city visuals. |
  | **4. In-ride dialogue comfort:** read and follow passenger exchanges without stress/confusion | **False** | Debug-stage dialogue/ride presentation is currently inadequate; future in-car UX remains to be tested. |

- **Overall initial outcome:** **4/4 False for CURRENT debug-build playability**; **evaluation context invalid/misleading for judging the proposed production experience**. Do not collapse this into a measured usability score or treat it as four independent validated root causes.
- **Related feedback IDs/issues:** FB-001 → #51; FB-002 → #49; FB-003 → #52; FB-004 plus dialogue/ride presentation → #50, #51. No new duplicate issue needed.
- **Decisions/implementation:** Existing #49–#52 remain **Accepted direction / Not implemented**. No source changes, player-mode UI or city pass occurred just because this checklist was recorded.
- **Technical evidence of a revised build:** **None**. Existing Linux/Web tests validate simulation mechanics, not these four human comfort goals.
- **Next check:** once a first genuine Player Mode and meaningful road scale exist, offer a small **specific** in-game interaction for optional user evaluation, without requiring a repeated full checklist or pre-claiming an improvement.
- **Human acceptance of improved gameplay:** **Pending / not assessed**, distinctly from the current baseline's four False answers.

### R03 — October 16, 2026 — first actual human impression of the integrated playtest build

- **Source/build:** User's first experience of Codex's integrated build [PR #55](https://github.com/MohamedXIV/outsider-driver-2d/pull/55), tested code `52fd490`. Exact OS/seed/screen size not provided; the build had passed [Godot native + exported Chromium technical run](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38919427433).
- **Overall player's own judgment:** «دي اكتر من اللي اتمناه في مرحلة مبكرة كده 😅 ، جميلة فعلا ، واتحسنا كتييير». This is **strongly positive initial reception**, not blanket human acceptance of all FB-001–FB-004 or completed final art. Do not preserve the old **4/4 False** as if it is their verdict on this new build; it referred exclusively to the PRE-reboot Debug World/Dashboard.
- **FB-005 / #56 — camera:** «الكاميرا بعيدة اوي ، هل نقدر نعمل zooming in and out زي مااتكلمنا قبل كده». Evidence: `sandbox_city_view.gd` currently sets `camera.zoom = Vector2(2.0,2.0)` every frame. Proposed bounded smooth manual zoom and closer default, with optional contextual bridge/junction zoom that respects manual choice. **Not implemented.**
- **FB-006 / #58 — city visuals:** «الطرق مش مظبوطة والكباري اكتر ، انا عارف انها لسة placeholders and for prototyping just wanted to say ، كمان مش دايما عايزين curves or splines بل بفكر اننا نتجه للاشكال المستقيمة المنتظمة ، لان ده يساعد اكتر على رسم المدينة وتنظيمها ووضع المباني ومعرفة وعمل بلوكات قياسية للمباني». User **considers**, not yet locks, a straighter, modular road/building block grammar. This **refines, not deletes** the earlier wish for roads natural enough to drive and grade-separated bridges. Existing technical #52 curved path/bridge demonstration remains verified, aesthetic feedback **Needs iteration**. **Not implemented.**
- **FB-007 / #57 — NPC jitter:** «ملاحظ انه في اوقات الـ npcs بيمشوا عادي smooth واوقات بينطوا steps». In `sandbox_main.gd` the presentation fraction advances under `_world.is_travelling()` only, while `sandbox_city_view.gd` samples NPC positions from that same fraction. This plausibly causes 1Hz visual stepping whenever the player is parked. The suspected cause is a **developer hypothesis**, not an experimentally confirmed single root cause. **Not fixed.**
- **Interpretation/next priorities:** first fix #57 interpolation independent of player taxi motion and #56 bounded camera zoom; iterate #58 road/block visual grammar separately with before/after pictures. **Do not globally remodel the city, remove curves everywhere or invalidate prior technical proof** on the basis of a first impression.
- **Human check status:** Overall visual/game impression substantially improved. Specific camera distance, road/bridge treatment and NPC smoothness unresolved. More user notes may follow after later play, without imposing another formal checklist.

### R04 — October 16, 2026 — native navigation & organized crossing

- **User's direction:** Use Godot's navigation/physics for the visible character's actual walking, instead of ticking a position along the vehicle graph by hand. Let SandboxWorld determine the character's goals and receive a verified arrival.
- **User's observation:** NPCs may cross roads at arbitrary points and visually overlap the player's taxi. They want a credible foundation for pedestrian and vehicle lanes, crossings and basic right-of-way, not an entirely new bespoke pathfinder.
- **FB-008 — [#59](https://github.com/MohamedXIV/outsider-driver-2d/issues/59):** Draft stacked [PR #61](https://github.com/MohamedXIV/outsider-driver-2d/pull/61) implements a **bounded Patchworks local world-resident actor**, `NavigationAgent2D`, physical movement, arrival provenance and location-sensitive instantiation in the default main scene. Full native city-wide NPC handoff is **not** yet implemented or human accepted.
- **FB-009 — [#60](https://github.com/MohamedXIV/outsider-driver-2d/issues/60):** Same PR prototypes modular sidewalks, one authorized `NavigationLink2D` crossing and a locally yielding traffic car; **it does not yet prevent all taxi/walker overlaps** or implement traffic across six districts.
- **Validation:** [Native Godot targeted run #38955939278](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38955939278) passed four tests including main-scene actor, a mid-walk save/reload and legacy city render. Post-run provenance validation and additional screenshot capture require a subsequent gate; no Web/Windows runtime proof yet.
- **Human acceptance:** Pending; previous user praise for the integrated Player Mode refers to PR #55, **not** to this new physical-navigation prototype.

### R07 engineering follow-up — October 17, 2026
- **Issue/feedback:** FB-009 / #60; local crossing priority after R06's grounded player taxi integration.
- **Found during audit:** In the demo `SandboxStreetPriority` policy, a pedestrian reservation just after a car had passed its stop line could freeze that car inside the zebra, while the pedestrian waited for the car to clear: a deadlock risk.
- **Implementation on draft stacked PR #61:** Cars at/before the line clamp to a safe stop when a pedestrian has reserved the crossing. Cars already beyond the line retain clearance priority; pedestrians wait until the car clears the lane. Removed the permissive 4 px post-line entry margin.
- **Regression added:** `tests/test_street_priority.gd` simulates a reservation at 0.01 px past the stop line and checks crossing clearance, gate reopening, and existing variable-frame stop-line bounds.
- **Evidence:** [Godot 4.7.2 native run #38986769410](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38986769410), source `ed3c7708`, **10/10 targeted PASS**, including `STREET_PRIORITY_PASS` for late-reservation clearance. [Logs/artifacts](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38986769410/artifacts/12082857942). No Web/Windows or human verification on this follow-up.
- **Acceptance:** Native technical gate PASS; full city traffic and human playtest pending. #60 remains open. GitHub Actions allowed: scoped push CI on pilot branch, documentation-only pushes ignored.

### R08 engineering follow-up — October 17, 2026
- **Issue/feedback:** FB-009 / #60; physically grounded crossing clearance on the active Player Mode taxi route.
- **Found:** The walker previously set `crossing_completed` once its center passed y=370, while the road still occupied y≤376 and its collision circle had a 7 px radius. The taxi could therefore resume while part of the NPC remained in the vehicle lane.
- **Implemented on stacked Draft PR #61:** Physical `crossing_clear_y()` derived from shared road rectangle, walker radius and margin (currently y=384). Both the native walker and deterministic offscreen completion use it. Actual taxi hold release requires both a completion flag **and** physical lane clearance, protecting even against a stale/incorrect presentation flag after restore.
- **New targeted regressions:** `test_street_module.gd`, `test_street_pilot_scene.gd`, `test_taxi_crossing_scene.gd` cover road boundary, native actor, blocked walker mid-crossing, stale completion flag and hold/resume after save/load.
- **Validation:** 14/14 preliminary static checks plus a **real Godot 4.7.2 10/10 PASS** at `ed3c7708` ([run #38986769410](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38986769410)); the updated `TAXI_CROSSING_SCENE_PASS` confirms physical lane-body clearance and stale-flag guard. No Web/Windows or human traffic acceptance.
- **Status:** Implemented and native test-verified. #60 and #59 remain open for broader traffic and playtest coverage, PR #61 remains stacked DRAFT; feature-branch native CI enabled, with documentation-only changes ignored.

### R09 — bidirectional real taxi crossing on the same Patchworks zebra (October 17, 2026)
- **Issue:** FB-009 / #60. The route-level crossing gate previously worked only for an outbound `garage → margin_gate` taxi. The same real road is traversable in reverse.
- **Implemented in stacked Draft PR #61:** The world-aligned crossing uses 35% outbound and 65% inbound route progress. Both `SandboxStreetRouteBinding` and held-world save validation recognize the reverse segment, while neighborhood proximity keeps the native walker available.
- **Coverage:** Extended `test_taxi_crossing_world.gd` with real Market round-trip, reverse hold, continuing clock, forged-release rejection and arrival. Added `test_taxi_crossing_return_scene.gd` to exercise a true seeded Market → garage return in the **actual Player Mode scene**, with native pedestrian, save/load, occupied-lane wait and clearance-based release.
- **Native evidence:** [Godot 4.7.2 run #38991344179](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38991344179), source `e3ef10c`, **11/11 targeted tests PASS**, including `TAXI_CROSSING_RETURN_SCENE_PASS`. [Logs/artifacts](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38991344179/artifacts/12085546161). This tests the actual game scene, not only a pure-world simulation.
- **Remaining:** Human gamefeel, Web/Windows gameplay, safe unloading and grade rules beyond the bounded zebra, and generalized multi-car city traffic. Keep #60 open and PR #61 Draft.

### R10–R11 — unloaded walker guard and grade-safe elevated taxi route (October 17, 2026)
- **R10 finding (FB-009 / #60):** Missing native `_street_pilot` used to release the real taxi's crossing yield unconditionally. A world-owned pedestrian may still occupy the zebra despite the scene actor being absent.
- **Fix:** The world trip is consulted: a still-`walking` resident cannot prove clearance; an `offscreen` resident must pass the shared road-edge + collider threshold through deterministic progress. Reloading the physical walker preserves the same NPC and hold.
- **Native proof:** `test_taxi_crossing_unload_scene.gd` deliberately removes the actor during an already-held actual Player Mode ride, checks held time/position, saved event provenance, offscreen partial movement, re-created native actor, and proper release. This is a *fault injection*, not a claim the normal game always unloads while stopped.
- **R11 proof:** The existing taxi route can travel the raised `bridge_east → bridge_west` viaduct without firing the unrelated grade-zero Patchworks crossing gate. Extended `test_taxi_crossing_world.gd` checks no invalid hold, neighborhood or occupancy.
- **Native verification:** [run #38995029085](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38995029085) **12/12 PASS** at `f593615b` for the unload fix, then [run #38995122278](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38995122278) **12/12 PASS** at `671ab184` for elevated-route isolation. [Latest logs](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38995122278/artifacts/12086808015).
- **Not yet covered:** Simultaneous multiple pedestrian crossings, native physical taxi body, larger city navigation, exported Web/Windows visual/play tests and human approval. PR #61 remains stacked DRAFT; #58/#59/#60 remain open.

### R12 — two physical ambient lane cars obey one world-owned pedestrian crossing (October 17, 2026)
- **Issue #60 / Draft PR #61:** The local Patchworks pilot now instantiates two native `CharacterBody2D` traffic cars. They are local ambient physics, **not** extra `SandboxWorld` resident identities or a replacement for the real route-graph player taxi.
- **Traffic contract:** Move leader first; clamp follower speed by its leader's updated position and a 42 px center gap, giving 17 px body-to-body clearance for the current 25 px wide collision shapes. Pedestrian entry checks both vehicles, preserving late-reservation clearance precedence.
- **Evidence:** [Godot 4.7.2 run #38996674793](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38996674793), SHA `3d073f69cfd1386b26c244af67eb9a152558d470` — **13/13 targeted Native PASS**, including new `STREET_MULTI_VEHICLE_PASS`, real-world resident arrival, existing Player Mode taxi/restore and grade separation. [Logs/artifact](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38996674793/artifacts/12086599331).
- **Test iteration:** Three prior runs failed due newly added assertions, not project parse: one assumed the rear car would always reach a full stop during natural crossing, and two staged runs counted initial zero velocity as a stop. Final native regression stages sustained reservation and checks *observed physical stop* before release.
- **Remaining:** Two bounded demo cars are not a city traffic scheduler or world-owned car itineraries. Multi-pedestrian collision, intersection occupancy, native player-car body, Web/Windows and human playtest stay open.

## Guiding invariants

- Natural ride lengths arise from road geometry/topology, street speed and meaningful travel, not simply multiplying fixed 10-minute edges or penalizing the player for reading dialogue.
- Debug Mode and Player Mode are **two presentations of the same game world**; preserving developer evidence cannot dictate player-first HUD structure.
- A visually crossing elevated deck has **no legal junction** unless connected by a real explicit ramp/graph node. Vehicle animation follows road geometry, not screen-space hacks.
- Preserve the strengths of one `SandboxWorld`, real systemic fares, Ink meaning, player-only knowledge, source-backed rumors, deterministic replay and existing language/AR save behavior.

### R02 — October 16, 2026 — integrated engineering delivery (not user feedback)
- Original R00/R01 notes and 4/4 False old-dashboard baseline remain unchanged.
- FB-001: metric curved roads, 6 regions / 27 nodes, varied 9–72 minute examples; unchanged clock rate; pickup engagement and readable arrival preserve normal reading.
- FB-002: default contextual Player Mode; reversible F3/touch Debug Mode shares the same authoritative world and Ink.
- FB-003: Curve2D geometry, actual taxi/NPC positions, tangent facing, explicit ramps/decks/supports/shadows/occlusion and non-connected crossings.
- FB-004: themed compact contextual screens, passenger portrait, route map, physical services, EN/Arabic, reduced motion and scrollable 44px controls.
- Checkpoints: `1bf7687` design recovery, `e5ac4b9` physical city/domain, `1d0f708` Player/Debug and travel Ink, followed by review/verification fixes in this integration branch.
- [Technical evidence and play instructions](CITY_PLAYTEST.md); source attribution and design boundaries in [world recovery](world/README.md).
- **Human verdict: Pending for every FB item.** Ready for human check is an engineering handoff, not a new True/False answer or visual/pacing acceptance.

## Delivered integrated build and evidence

- Code `52fd490`, [PR #55](https://github.com/MohamedXIV/outsider-driver-2d/pull/55), [single final run — PASS](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38919427433).
- [Linux / Windows-export / Web build bundle](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38919427433/artifacts/12054755010) and [actual screenshots/logs](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38919427433/artifacts/12054118689). Artifacts checked after download; 21-day retention.
- FB-001 proof: `test_city_journeys`, `test_travel_dialogue`, `04-long-city-ride`, `05-arrival-readable`, `web-long-route`, `web-short-route`; actual 72-minute and 35-minute fares, not a claim of human comfort.
- FB-002 proof: `test_player_mode`, `01-player-outer-margin`, `03-debug-same-world`, `web-default-player`, `web-debug`; one unchanged world on mode switch.
- FB-003 proof: `test_city`, `test_city_waypoints`, `test_sandbox_reroute`, native `06-underpass` / `07-ramp` / `08-deck` / `09-connected-descent`, each with authoritative position JSON.
- FB-004 proof: `test_player_layout`, `test_player_arabic`, `test_player_contacts`, `web-player-dialogue`, `web-gear`, `web-small-arabic`; actual pointer/scrolling and Arabic font/fallback rendering inspected.
- #23's completed engineering umbrella is closed. #49–52 are implemented on the PR and remain open until merge. #48 and #15 remain open for human feedback and broader sandbox scope. **No FB item is Human accepted.**

### R04 engineering checkpoint — October 16, 2026
- [PR #61](https://github.com/MohamedXIV/outsider-driver-2d/pull/61) (stacked draft on #55) now embeds one world-chosen native walking NPC and organized crossing at the Patchworks garage in actual Player Mode. Visual walker location is preserved at save/load without duplicating resident identity, economy, dispatch or arrival; world restore rejects a forged local arrival event.
- [Native runner #38956333840](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38956333840): **4/4 targeted tests PASS**, including actual game-scene navigation and prior city renderer. **Not** a city-wide traffic or NPC pathfinding proof, no Web/Windows runtime verification, no human acceptance. The temporary CI was returned to manual-only.

### R04 native street module and near/far checkpoint — October 16, 2026
- [PR #61](https://github.com/MohamedXIV/outsider-driver-2d/pull/61) now derives Patchworks walking polygons, marked legal crossing, traffic lane and building lots from `SandboxStreetModule`. A world-owned local NPC has a recorded spatial handoff when the player leaves, deterministic coarse offscreen continuation, and native Godot reactivation when the player returns before arrival. Save restore validates the sequential movement events; the resident's social/economic world identity is unchanged.
- **Technical evidence:** [Native Godot run #38960875587](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38960875587) with **6/6 targeted tests passed**, including native near/far continuity, one arrival and spoofed progress rejection. Native scene PNGs and logs uploaded. No claim of human aesthetic acceptance, Web run or city-wide traffic completeness.
- Actions street pilot gate restored to **manual-only** after testing. #58/#59/#60 remain open for multi-street geometry, additional NPCs and actual vehicle traffic/final playtesting.

### R05 engineering checkpoint — connected junction + actual site arrival (October 16, 2026)
- [Draft PR #61](https://github.com/MohamedXIV/outsider-driver-2d/pull/61) now draws two connected Patchworks street blocks and a perpendicular T-junction; Godot navmesh polygons connect sidewalks by matching edges while explicit NavLinks alone cross the traffic asphalt.
- StreetPriority adds stop-line braking and pedestrian crossing precedence for **demo traffic vehicles**. Do not claim the world-graph-driven **player taxi** has physical lane collision/yielding yet.
- Physical NPC arrival now requires true proximity to the service point, not just a finished/clipped NavigationAgent path.
- **Evidence:** [Godot 4.7.2 targeted native run #38964666601](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38964666601), **8/8 PASS**. Native only; visual/human and Web/Windows checks outstanding. Prior two CI failures were due to an incorrect child-node lookup in the new test and were corrected. The targeted workflow is manual-only again.

### R06 — actual player taxi yields at a grade-safe Patchworks crossing (October 16, 2026)
- **User direction:** continue from the connected street modules to make the actual player taxi obey pedestrian traffic, without falsely claiming the legacy world-route car is a Godot physics vehicle.
- **Implemented in [stacked Draft #61](https://github.com/MohamedXIV/outsider-driver-2d/pull/61):** the first zebra is now grounded on the real garage→margin_gate road edge, the native pedestrian remains loaded as the taxi approaches, and a world-owned route hold suspends travel *position* while world minutes continue. A start/end event records the yield, restores through save/load and blocks forged held/unheld state. Clearing the crossing resumes the exact route and preserves ordinary passenger settlement. This is a **single edge and crossing** proof, not all-city player-car collision or lane physics.
- **Verified:** [Godot 4.7.2 native targeted run #38967936158](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38967936158), **10/10 PASS**, including world and actual Player Mode crossing scene, mid-hold save/load, route completion and prior eight tests. Windows/Web runtime and human traffic-feel assessment pending. Actions returned to manual-only. #58/#59/#60 remain OPEN.
