# Approved decisions and outstanding gates

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

- Select/verify a stable Ink interpreter integration working in Godot desktop and Web.
- Validate simple portrait sprite atlas/display and settings before scaling character production.

These P1 gates must be validated before growing narrative/character content. Do not restart engine debates without new evidence.
