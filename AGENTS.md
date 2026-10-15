# Outsider Driver 2D — agent instructions

Canonical repository: `MohamedXIV/outsider-driver-2d`. The old 3D repository is READ-ONLY reference.

Read `docs/SANDBOX_GAME_DNA.md`, `docs/PROTOTYPE_CLOSEOUT.md`, `docs/GAME_DESIGN.md`, `docs/CAMERA_AND_WORLD.md`, `docs/TECHNICAL_ARCHITECTURE.md` and `docs/ROADMAP.md` before implementing systems.

**Current active goal:** [sandbox foundation #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15). P0–P2's fixed clinic ride is a FROZEN TECHNICAL FIXTURE, **not the product architecture**. Do not extend that passenger or scripted loop as gameplay.

- Implement the smallest playable next slice, not abstractions lacking immediate use.
- Prefer typed GDScript and Godot built-ins. C++/GDExtension only for measured bottlenecks; no Inochi2D.
- One authoritative modular world state, domain-owned NPCs/needs/mobility/dispatch/economy/risk and replaceable world/passenger views. No monolithic gameplay session.
- Ink remains for conditional authored speech-acts/text/choices/tags and deterministic fallbacks. It must consume world truth and emit typed validated intents/effects, not drive the simulation. LLM rephrasing may affect surface wording only.
- The game is truly 2D and needs both Web and desktop exports.
- Do not invent free-roam driving, walking city maps or complex puppet rigs.
- Verify Godot loads scenes, run focused tests and inspect actual visuals; label unrun checks accurately. Do not claim semantic Ink host bindings, a true sandbox or actual Windows gameplay have passed based on the prototype's green cross-platform CI.
- Old P1 human pacing and Windows-runtime gates are UNVERIFIED and transferred to new sandbox acceptance; do not keep implementing P2.3 prototype content.
- Use short PRs. Avoid GitHub Actions unless needed.
- No edits to the original `MohamedXIV/outsider-driver` repository.
