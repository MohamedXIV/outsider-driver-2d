# Outsider Driver 2D — agent instructions

Canonical repository: `MohamedXIV/outsider-driver-2d`. The old 3D repository is READ-ONLY reference.

Read `docs/GAME_DESIGN.md`, `docs/CAMERA_AND_WORLD.md`, `docs/TECHNICAL_ARCHITECTURE.md` and `docs/ROADMAP.md` before implementing systems.

- Implement the smallest playable next slice, not abstractions lacking immediate use.
- Prefer typed GDScript and Godot built-ins. C++/GDExtension only for measured bottlenecks; no Inochi2D.
- Maintain separation: authoritative GameSession, authored Ink, replaceable world and passenger views.
- The game is truly 2D and needs both Web and desktop exports.
- Do not invent free-roam driving, walking city maps or complex puppet rigs.
- Verify Godot loads scenes, run focused tests and inspect actual visuals; label unrun checks accurately.
- Use short PRs. Avoid GitHub Actions unless needed.
- No edits to the original `MohamedXIV/outsider-driver` repository.
