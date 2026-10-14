# Outsider Driver 2D

A narrative social-stealth taxi game set in an alien city that prohibits humans. You are a human living under a false identity, earning a living by driving an old taxi and learning how to belong.

**Status:** new Godot 2D production baseline; the previous Babylon.js project remains a reference, not a code dependency.

## Direction

- **Engine:** Godot 4.x; **language:** typed GDScript; **renderer:** 2D Compatibility (Web + desktop).
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

Open `project.godot` with the selected Godot 4.x editor; press **F6/F5** once the first scene lands. For headless project loading, run `godot --headless --path . --editor --quit`.

This project prioritizes playable, testable increments over building systems with no immediate player-facing use.
