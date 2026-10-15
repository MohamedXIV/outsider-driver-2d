# Approved decisions and outstanding gates

> **Status October 15, 2026:** The items below record historical 2D prototype decisions and evidence. Authoring Ink narrative is *not* approval of fixed passenger scenarios as the game structure. New authoritative direction: [Sandbox DNA](SANDBOX_GAME_DNA.md), [prototype closeout](PROTOTYPE_CLOSEOUT.md), [sandbox issue #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15).

## Active execution plan — October 15, 2026

The active issue-by-issue implementation sequence is in [Sandbox Execution Roadmap](SANDBOX_EXECUTION_ROADMAP.md); the old [ROADMAP.md](ROADMAP.md) is **archived P0–P2**, not the current work board. Epic [#15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15) and area parents [#22](https://github.com/MohamedXIV/outsider-driver-2d/issues/22), [#24](https://github.com/MohamedXIV/outsider-driver-2d/issues/24), [#23](https://github.com/MohamedXIV/outsider-driver-2d/issues/23) track execution. **Next ready issue: [#26](https://github.com/MohamedXIV/outsider-driver-2d/issues/26).**

## Active living-city design synthesis — October 15, 2026

Read [Living City: Social Bonds, Languages & Routes](LIVING_CITY_DESIGN_CONCLUSIONS.md) for the consolidated discussion, explicit **agreed vs recommended vs open** distinctions, and the difference between proven S0–S2 code and future relationships/navigation/features. The old equipment bullet in `GAME_DESIGN.md` records the historical prototype/S2 starter; a baseline Common translator plus GPS / extra language / Radio is **recommended, not yet implemented or finally ratified**. Do not mistake the proposal for a passing feature.

## Approved — October 2026

- Clean new repository: `outsider-driver-2d`. Previous `outsider-driver` stays unchanged.
- Godot 4.7.2 stable (pinned engine and export templates) + typed GDScript, 2D Compatibility renderer, **Web and desktop**.
- Fixed-angle axonometric/isometric, cinematic close-follow; more room at junctions/bridges; no wide city-builder view.
- Multi-elevation authored roads, ramps, supports and authentic topological separation.
- Taxi travel is route-driven; no manual driving requirement.
- Passenger spritesheets/avatar at upper-right; player replies lower-left; optional taxi-seat/cabin frame.
- Continuous world/time and route progress during dialogue; destination arrival creates authored safe-exit choices.
- Small walkable home/garage; nearby neighborhood later if worth it; no free-roam city commitment.
- No Inochi2D. No C++ by default, but GDExtension is allowed for proven hotspots.
- Keep the previous project's core game design, not its Babylon architecture or versioned saves.

## Verified P0 technical proof

- Isometric road/elevation/bridge proof, ride progression and close-follow camera: [P0 validation](P0_VALIDATION.md).
- Linux desktop export and Chromium Web runtime on Godot 4.6.3: verified in the historical P0 workflow. 4.7.2 adoption must be verified separately before P1.

## Pending P1 technical proof (not design reconsideration)

- **Verified (P1.1):** inkgd GDScript runtime (pinned source subset) runs authored Ink + choices on Godot 4.7.2 Linux/Desktop and Chromium/Web. See [P1 Ink evidence](P1_INK.md).
- Validate simple portrait sprite atlas/display and settings before scaling character production.

These P1 gates must be validated before growing narrative/character content. Do not restart engine debates without new evidence.
