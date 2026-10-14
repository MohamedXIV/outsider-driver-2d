# Godot 4.7.2 engine version adoption

## Decision

Use **Godot 4.7.2 stable**, not the earlier 4.6.3 that was used for initial P0 validation. The 4.7.2 stable release was published on 2026-08-18. 4.8 development builds are not an acceptable release baseline.

This is a tooling/version correction, not a change in 2D renderer, gameplay scope or architecture. Use matching 4.7.2 standard editor and 4.7.2 export templates for every targeted build (Linux x86_64 and single-threaded Web).

Official release: https://godotengine.org/download/archive/4.7.2-stable/
Migration notes: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html

## Specific migration checks

- Godot 4.7 changes `CanvasItem` line antialiasing feather: review the placeholder road/bridge edge line thickness visually.
- Existing typed GDScript projection and route logic must parse and pass deterministic tests without amendments.
- Export native Linux binary and single-threaded Web; smoke-run the binary and Chromium canvas.
- Compare actual underpass, ramp and elevated screenshots with the 4.6.3 accepted evidence.

## Validation state

**PASS:** [targeted CI run #38614945344](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38614945344) (Godot 4.7.2) completed successfully:
- Godot editor import, GDScript parse, P0 deterministic tests and headless startup.
- Real software-OpenGL frames captured at start, underpass, ramp, elevated deck and end.
- Linux x86_64 release exported and launched.
- Single-threaded Web exported and loaded in Chromium, with a rendered canvas screenshot and no captured browser page errors.
- [Six-image evidence artifact](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38614945344/artifacts/11919420559) was reviewed. Underpass remains visible through a translucent deck; camera and elevated road remain legible with no obvious regression compared to P0.

This is Web Chromium/Linux smoke verification only, not Windows/macOS, mobile Safari or full gameplay validation. Historic P0 evidence from 4.6.3 remains unchanged.

Keep the CI branch-specific to this version migration; do not use this job for routine docs changes.
