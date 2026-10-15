# Outsider Driver 2D

A narrative social-stealth taxi game set in an alien city that prohibits humans. You are a human living under a false identity, earning a living by driving an old taxi and learning how to belong.

**Status:** P0–P2 authored-ride technical prototype archived. **Sandbox S0–S3 and Routes P0 now run by default**: seeded NPC mobility offers, autonomous work/rest and alternative travel, visible 5-district route selection and persistent economy, plus context-grounded shared Ink interactions, distinct persistent GPS/Translator/Radio starter gear, earned partial route-language knowledge, world-command decisions and mid-dialogue Save/Load. This is an early systemic playable foundation, **not** a completed living-city game. The previous Babylon.js project remains read-only reference, not a code dependency. [Why we stopped extending the scripted prototype](docs/PROTOTYPE_CLOSEOUT.md).

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
- [Active Sandbox Execution Roadmap](docs/SANDBOX_EXECUTION_ROADMAP.md)
- [Current vs Superseded Contracts](docs/SUPERSESSION_REGISTER.md)
- [Archived prototype P0–P2 Roadmap](docs/ROADMAP.md)
- [Decisions and open gates](docs/DECISIONS.md)
- [Agent instructions](AGENTS.md)

The old [Outsider Driver repository](https://github.com/MohamedXIV/outsider-driver) contains useful domain contracts, authored content and older 3D design documents. Do not import its runtime or save formats by default.

## Run — systemic sandbox S0–S3 + Routes P0

Open `project.godot` in Godot 4.7.2 and press **F5**. The default screen is now a *systemic city dispatch board*, **not the fixed clinic story**. The map shows five connected districts and how many NPC residents currently occupy each. NPCs generate offers from changing travel needs and budgets.

Choose exactly one starter **GPS / Translator / Radio** at the top of the sandbox board. GPS provides graph-route hints, Radio exposes an untranslated alien signal, and Translator can gradually learn a *single local route marker* by asking a nearby alien NPC; it does not translate entire conversations. The choice, learned facts and event provenance survive Save/Load. Select a generated ride offer (the nearest accessible one is selected by default). At a local offer, press **Talk to NPC** to hear a reusable Ink conversation grounded in that resident's language/need/mood. **Ask where they need to go**, then accept or decline using Ink speech acts; an unlicensed player cannot take an official-network fare. Untranslated alien languages remain unintelligible. Direct **Accept ride** still works for offers originating in your current district and available via street/underground networks. **Decline** changes the NPC's pending demand; **Reposition taxi** moves along city road connections and costs credits; **Wait +20 minutes** advances all NPCs, offers and active trip progress. Before accepting a local offer, choose a connected waypoint in **Trip Route** (or click a district node on the schematic map) to change the journey. The taxi advances along the selected real road edges and can be seen **between** districts; route time and posted toll/checkpoint consequences are committed by the world as segments finish. **Save World / Load World** now retain the current edge and elapsed minutes. Mid-trip route changes belong to the next milestone, #28. **Observe +6h (debug)** fast-forwards autonomous city life without driver actions. An accepted fare pays only upon reaching its actual destination. **Save World / Load World** persist complete residents, offers and events. **New world seed** changes the population, not a scripted route.

See [Sandbox S2 earned knowledge and verification](docs/SANDBOX_S2.md), [S1 contextual Ink](docs/SANDBOX_S1.md), [S0 scope](docs/SANDBOX_S0.md) and [Sandbox foundation #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15). The S3/Routes P0 screen still uses temporary schematic artwork; real language acquisition/Translator progression, richer social memory, human pacing tests and full city economy are **future increments**.

The old fixed clinic prototype remains at `scenes/main.tscn` for regression; it is not the production main scene.


For repeatable headless verification:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --quit-after 90
```

See [P0 validation evidence](docs/P0_VALIDATION.md) and [Issue #1](https://github.com/MohamedXIV/outsider-driver-2d/issues/1) before treating Web/Desktop acceptance as complete.

The 18-credit fare, 6-credit servicing, fixed clinic visitor and repeated drive are **noncanonical test values**. New work starts with [sandbox systems #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15), not a P2.3 expansion. Existing GitHub CI exports test the prototype; Windows gameplay and human pacing/feel remain unverified.
