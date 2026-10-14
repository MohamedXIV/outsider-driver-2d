# Gameplay-First Roadmap

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

**P2.0 in progress:** one-time GPS / Translator / Radio preparation before pickup, authoritative equipment + three distinct knowledge facts, preserved in new v2 saves. [Equipment slice](P2_SHIFT_PREP.md); [P2 tracking #11](https://github.com/MohamedXIV/outsider-driver-2d/issues/11). This is a small dockside-garage prep **UI**, not yet a walkable garage scene or a repeatable daily loop. P1 human acceptance remains open separately.


- Small apartment/garage scene with basic on-foot interaction.
- Shift preparation, jobs, repairs, expenses and return.
- GPS / Translator / Radio choices provide differentiated information.
- Repeatable daily loop and deterministic integration tests.

## P3 — Content expansion & living city

- Multiple routes/districts, a recurring character, radio content, legal/underground job paths and relationship/lie callbacks.
- Repeatable art-production workflow measured on actual added scenes.
- Explore a bounded neighborhood only if it strengthens the game; not a prerequisite.

## Stop conditions

Never claim a phase passes without evidence for relevant desktop/Web targets. Don't build city-wide navigation, a generic rigging product, elaborate shaders or migration compatibility just because they may be useful later.
