# Sandbox S0 — Seeded population and mobility demand

This is the **first independent playable systems-generated city**, not an expansion of the retired single-passenger ride. The project's default scene is now `scenes/sandbox.tscn`; the old authored clinic test remains in `scenes/main.tscn` and continues to run as a regression fixture.

## Modular responsibilities

- **SandboxPopulation**: nine persisted actors seeded with location, need, cash, purpose, destination, trust, cooldown, language and temperament. Each 10-minute city tick changes their needs; after travel their finances, location, purpose and trust change.
- **SandboxRoads**: a five-district graph shared by all actors and the player. Edges determine fare distance and travel time; these are *not* passenger-specific scripted waypoint sequences.
- **SandboxDispatch**: independent offers emerge from an actor's actual unmet mobility need and ability to pay. Offers include origin, goal, price, owner, channel and time-to-live; they can expire or be declined and do not all reset at once. Official network jobs cannot be taken by the unlicensed player; street and underground channels can be used.
- **SandboxWorld**: one world authority orchestrates commands, discrete 10-minute ticks, acceptance, refusal, repositioning, single-settlement fares and deterministic provenance events. Taking an underground offer increases risk. Views cannot mint money or passengers.
- **SandboxSave**: new versioned v1 world snapshots persist offers (including expired/completed), actors, funds, locations, clock, active trip and event log; no migration from prototype v4.
- **SandboxMain / SandboxCityView**: temporary 2D schematic neighborhood map and interactive dispatch board. NPC offers are not hardwired to named scripted stories. City tick advances automatically (+10 simulated minutes / 10 real seconds); Wait +20m accelerates observation.

## How to play

Run the project (Godot 4.7.2). Select an NPC trip offer; if its origin is your district and it isn't a licensed/official offer, use **Accept ride**. Each road hop costs 10 simulated minutes: **Wait +20 minutes** can progress a trip. Accepted trips settle exactly once, move the NPC and taxi to the destination, debit the NPC and pay the player. Decline a request to affect the NPC's cooldown; reposition the taxi to another district to reach new offers, paying one credit per hop. Save/Load persist the entire city; New world seed changes actors' initial demand.

## Evidence gates and honest limits

`tests/test_sandbox.gd` proves deterministic seeds, state-generated local offers, travel settlement, NPC cash/trust changes, event once-only provenance, independent expiration, save/load and deterministic replay. `tests/test_sandbox_scene.gd` renders the new scene and captures screenshots; `tests/web_sandbox_smoke.cjs` clicks real exported Web buttons and reloads a persistent world.

**This S0 does not yet claim semantic Ink dialogue or any LLM.** Compiled inkgd runs correctly in the archived P1 fixture, but next work in [#15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15) must bind a *live* NPC context to reusable Ink intent/utterance rules, maintain truthful language knowledge and provide deterministic authored fallbacks. This is a world-demand foundation, not a complete NPC social engine.

The map is a temporary schematic, NOT finished close-follow isometric street art. Reusable roads still need cinematic vehicle presentation, risk/checkpoint modeling, vehicle upkeep, day economics and qualitative human acceptance. The first seed uses a small deterministic population and simple provisional pricing—not final world economy or full population AI. No actual Windows gameplay verified.
