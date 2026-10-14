# Approved decisions and outstanding gates

## Approved — October 2026

- Clean new repository: `outsider-driver-2d`. Previous `outsider-driver` stays unchanged.
- Godot 4.x + typed GDScript, 2D Compatibility renderer, **Web and desktop**.
- Fixed-angle axonometric/isometric, cinematic close-follow; more room at junctions/bridges; no wide city-builder view.
- Multi-elevation authored roads, ramps, supports and authentic topological separation.
- Taxi travel is route-driven; no manual driving requirement.
- Passenger spritesheets/avatar at upper-right; player replies lower-left; optional taxi-seat/cabin frame.
- Continuous world/time and route progress during dialogue; destination arrival creates authored safe-exit choices.
- Small walkable home/garage; nearby neighborhood later if worth it; no free-roam city commitment.
- No Inochi2D. No C++ by default, but GDExtension is allowed for proven hotspots.
- Keep the previous project's core game design, not its Babylon architecture or versioned saves.

## Pending technical proof (not design reconsideration)

- Select/verify a stable Ink interpreter integration working in Godot desktop and Web.
- Verify isometric elevation/occlusion, camera comfort, correct bridge traversal.
- Validate Web + desktop exports on the selected Godot release.
- Validate simple portrait sprite atlas/display and settings before scaling character production.

Only these gates can block expanding P0/P1; do not use them to restart engine debates without evidence.
