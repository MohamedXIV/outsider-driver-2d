# Outsider Driver 2D

A narrative social-stealth taxi game set in an alien city that prohibits humans. You are a human living under a false identity, earning a living by driving an old taxi and learning how to belong.

**Status:** **P0–P2 technical prototypes archived** (Web/Linux checks passed); the **actual systemic sandbox is not yet built**. The previous Babylon.js project remains read-only reference, not a code dependency. [Why we stopped extending the scripted prototype](docs/PROTOTYPE_CLOSEOUT.md).

## Direction

- **Engine:** Godot 4.7.2 stable; **language:** typed GDScript; **renderer:** 2D Compatibility (Web + desktop).
- **World:** close-follow isometric/axonometric camera, illustrated environments, reusable road-graph modules and multi-elevation bridges/ramps. Current fixed route is a test fixture only.
- **Driving:** semi-autonomous, not real-time manual driving.
- **Gameplay architecture:** persistent, modular world simulation; NPC needs create offers; official/underground networks, languages, social state, risk and economy determine available gameplay. [Sandbox Game DNA](docs/SANDBOX_GAME_DNA.md).
- **Narrative:** Ink as contextual, semantic-tagged authored rules/utterances and deterministic offline fallback, not a scripted passenger scenario scheduler. Current tested bridge proves text/choices/tags/saving only. The sandbox owns NPC/world facts and consequences; optional LLM changes only permitted surface wording.
- **Characters:** simple spritesheet portraits. Passenger upper-right; player choices lower-left; optional seat/cabin frame.
- **Dialogue:** travel and world time continue; arrival is a narrative event, not an arbitrary interruption.
- **Foot exploration:** small personal spaces first; nearby neighborhood is deferred. Not an open world.
- **C++:** optional GDExtension only when measurements justify it. No Inochi2D.

## Design and engineering

- [Current Sandbox Game DNA](docs/SANDBOX_GAME_DNA.md)
- [Prototype Closeout](docs/PROTOTYPE_CLOSEOUT.md)
- [Sandbox Foundation #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15)
- [Game Design](docs/GAME_DESIGN.md)
- [Visual camera, routes and elevation](docs/CAMERA_AND_WORLD.md)
- [Technical Architecture](docs/TECHNICAL_ARCHITECTURE.md)
- [Engineering Rules](docs/ENGINEERING_RULES.md)
- [Roadmap](docs/ROADMAP.md)
- [Decisions and open gates](docs/DECISIONS.md)
- [Agent instructions](AGENTS.md)

The old [Outsider Driver repository](https://github.com/MohamedXIV/outsider-driver) contains useful domain contracts, authored content and older 3D design documents. Do not import its runtime or save formats by default.

## Run — historical P0–P2 technical fixture (NOT sandbox gameplay)

Open `project.godot` in Godot 4.7.2 and press **F5**. Move with **WASD / arrow keys** in the small garage. Approach the workbench to choose one starter device (GPS / Translator / Radio). Read the shift notice with **E**, then approach the taxi and press **E** or **Pick up visitor**. The taxi follows an authored route through the elevated crossing while you speak to the passenger. At the clinic, choose **Talk at destination** to conclude the ride. Save / Load preserve the chosen device and unfinished dialogue. After dropping off the passenger, press **E** or **Return to garage**. At the workbench, press **E** to pay the 6-credit taxi service/upkeep, then walk back to the taxi for another shift. This loop repeats and preserves your credits and knowledge; **R** is a debug new-game reset.

For the garage interactions see [P2 Garage](docs/P2_GARAGE.md), and for starter knowledge see [P2 Shift Prep](docs/P2_SHIFT_PREP.md). For the previously validated P1-only build (without prep), see [P1 Playtest](docs/P1_PLAYTEST.md).

For repeatable headless verification:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --quit-after 90
```

See [P0 validation evidence](docs/P0_VALIDATION.md) and [Issue #1](https://github.com/MohamedXIV/outsider-driver-2d/issues/1) before treating Web/Desktop acceptance as complete.

The 18-credit fare, 6-credit servicing, fixed clinic visitor and repeated drive are **noncanonical test values**. New work starts with [sandbox systems #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15), not a P2.3 expansion. Existing GitHub CI exports test the prototype; Windows gameplay and human pacing/feel remain unverified.
