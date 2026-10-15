# Archived P0–P2 Prototype Roadmap

> **Frozen October 15, 2026.** The chronology below records what the technical prototype proved. It is **not** an active roadmap and must not be used to justify implementing P2.3 or additional authored taxi scenarios. See [current Sandbox Game DNA](SANDBOX_GAME_DNA.md), [P0–P2 closeout](PROTOTYPE_CLOSEOUT.md), and [new active foundation issue #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15). The old automated Web/Linux gates passed; human UX and actual Windows play were NOT tested and are deferred to the new sandbox.


Each milestone produces a playable improvement using production-quality code. Placeholder graphics are allowed; disposable architectures are not.

## P0 — Isometric road and camera proof — VERIFIED

- Godot project opens and starts on desktop/headless.
- 2D ground street, elevated bridge, authored ramp and a taxi following them.
- Taxi passes below then above the bridge with correct occlusion.
- Cinematic close-follow, modest look-ahead, readable zoom.
- Verify the actual rendered frame, not just math.
- Validate Web and desktop export before closing P0.

**Accepted:** [P0 validation evidence](P0_VALIDATION.md) — real Godot rendering and Chromium/Linux export-smoke passed. Vector graphics remain placeholders, and Windows/mobile UX is a later platform gate.

## P1 — First authentic taxi ride

- One job / passenger / destination.
- Pickup → travel → arrival → deliberate drop-off.
- Passenger portrait upper-right, player choices lower-left, optional cabin frame. **P1.2 proof verified** ([Web screenshots](P1_PRESENTATION.md)); final asset content and responsive polish remain.
- Ink story integration proven on Web and desktop. **P1.1 verified:** [Ink native/Web evidence](P1_INK.md); remaining ride loop and UI work is ongoing.
- World/time continue throughout dialogue; arrival-aware choices and safe exits.
- Fare and one meaningful suspicion/knowledge consequence; fresh save/load.

**P1 implementation status (October 2026):** P1.1/P1.2/P1.3/P1.4/P1.5 are merged; first taxi ride gameplay and Web/Linux automated end-to-end checks are verified. P1.6 exports and packages the same slice for Web, Linux x86_64 and Windows x86_64 ([build and instructions](P1_PLAYTEST.md)). **Human pacing/legibility and real Windows gameplay remain unverified.** Keep [P1 parent #3](https://github.com/MohamedXIV/outsider-driver-2d/issues/3) open for qualitative acceptance; placeholder artwork is not a final visual acceptance. Do not start P2 by pretending that unfinished playtest evidence is a PASS.

## P2 — Daily loop with personal spaces

**P2.0 merged via PR #12:** one-time GPS / Translator / Radio preparation before pickup, authoritative equipment + three distinct knowledge facts, preserved in new v2 saves. [Equipment slice](P2_SHIFT_PREP.md); [P2 tracking #11](https://github.com/MohamedXIV/outsider-driver-2d/issues/11). This is a small dockside-garage prep **UI**, not yet a walkable garage scene or a repeatable daily loop. P1 human acceptance remains open separately.

**P2.1 implemented and native/Web validated:** bounded on-foot garage, proximity-gated equipment, read-once shift notice and taxi-door departure, including browser refresh/save recovery ([P2.1 evidence](P2_GARAGE.md); [CI #38650014827](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38650014827)). The garage uses **placeholder art**, Windows runtime and human pacing remain unverified. P2.2 follows with return-to-garage and day-by-day servicing.


**P2.2 implemented and Web/Linux validated (PR #14):** after a completed fare, return to the authored garage and next morning, service at the workbench for 6 credits and drive another authored shift. Two fares gross 36, one service 6, wallet 30. Fresh v4 saves preserve recurring economy, gear, knowledge and ride-scoped Ink results. [Daily-loop evidence](P2_DAILY_LOOP.md); [successful CI #38652590394](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38652590394). The *same* short authored passenger/route repeats for now, with placeholder art. P2.3 and human/Windows-runtime acceptance remain pending.

- Small apartment/garage scene with basic on-foot interaction.
- Shift preparation, jobs, repairs, expenses and return.
- GPS / Translator / Radio choices provide differentiated information.
- Repeatable daily loop and deterministic integration tests.

## P3 — Former candidate content expansion (superseded by sandbox-first architecture)

- Multiple routes/districts, a recurring character, radio content, legal/underground job paths and relationship/lie callbacks.
- Repeatable art-production workflow measured on actual added scenes.
- Explore a bounded neighborhood only if it strengthens the game; not a prerequisite.

## Stop conditions

Never claim a phase passes without evidence for relevant desktop/Web targets. Don't build city-wide navigation, a generic rigging product, elaborate shaders or migration compatibility just because they may be useful later.
