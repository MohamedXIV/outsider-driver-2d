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

**PENDING targeted 4.7.2 CI** at this commit. Historic P0 evidence from 4.6.3 remains truthful but must not be represented as 4.7.2 validation.

Keep the CI branch-specific to this version migration; do not use this job for routine docs changes.
