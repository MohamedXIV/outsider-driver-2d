# Outsider Driver 2D

A narrative social-stealth taxi game set in an alien city that prohibits humans. You are a human living under a false identity, earning a living by driving an old taxi and learning how to belong.

**Status:** new Godot 2D production baseline; the previous Babylon.js project remains a reference, not a code dependency.

## Direction

- **Engine:** Godot 4.7.2 stable; **language:** typed GDScript; **renderer:** 2D Compatibility (Web + desktop).
- **World:** close-follow isometric/axonometric camera, illustrated environments, authored taxi routes, grounded traffic, and multi-elevation bridges/ramps.
- **Driving:** semi-autonomous, not real-time manual driving.
- **Narrative:** authored Ink, subject to a Godot/Web integration gate. The game domain owns state and consequences.
- **Characters:** simple spritesheet portraits. Passenger upper-right; player choices lower-left; optional seat/cabin frame.
- **Dialogue:** travel and world time continue; arrival is a narrative event, not an arbitrary interruption.
- **Foot exploration:** small personal spaces first; nearby neighborhood is deferred. Not an open world.
- **C++:** optional GDExtension only when measurements justify it. No Inochi2D.

## Design and engineering

- [Game Design](docs/GAME_DESIGN.md)
- [Visual camera, routes and elevation](docs/CAMERA_AND_WORLD.md)
- [Technical Architecture](docs/TECHNICAL_ARCHITECTURE.md)
- [Engineering Rules](docs/ENGINEERING_RULES.md)
- [Roadmap](docs/ROADMAP.md)
- [Decisions and open gates](docs/DECISIONS.md)
- [Agent instructions](AGENTS.md)

The old [Outsider Driver repository](https://github.com/MohamedXIV/outsider-driver) contains useful domain contracts, authored content and older 3D design documents. Do not import its runtime or save formats by default.

## Run

Open `project.godot` in Godot 4.7.2 and press **F5**. The first playable scene is a vector-art P0 route/camera proof: taxi passes under an elevated crossing, follows an authored ramp and drives above it. Press **R** to restart.

For repeatable headless verification:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --quit-after 90
```

See [P0 validation evidence](docs/P0_VALIDATION.md) and [Issue #1](https://github.com/MohamedXIV/outsider-driver-2d/issues/1) before treating Web/Desktop acceptance as complete.

This project prioritizes playable, testable increments over building systems with no immediate player-facing use.
