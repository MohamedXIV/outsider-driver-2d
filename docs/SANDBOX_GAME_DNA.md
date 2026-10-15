# Outsider Driver — Sandbox Game DNA (current direction, October 15 2026)

This is a **systemic social-stealth taxi sandbox**, NOT a series of authored passenger scenarios or an endlessly extended prototype clinic ride.

## Non-negotiable fantasy

The player is a human living illegally among alien societies. The city exists independently of the player and contains communities, schedules, languages, needs, work, laws and unequal access to infrastructure. The taxi provides income, social access and exposure. **The world creates situations; actors decide; the player intervenes; consequences persist.**

This is a **sandbox simulation**, but does not require open-world manual driving. A fixed close-follow axonometric camera, small walkable personal spaces and reusable graph-based/semi-autonomous road travel remain valid.

## System-owned causality, modular responsibilities

- **World/time/event ledger:** one authoritative persisted snapshot, stable identifiers, explicit commands and consequences with provenance; reproducible world ticks/seeds where stochastic outcomes are necessary.
- **Population:** NPCs exist with location/presence, needs, budgets, identity, local knowledge, languages, attitudes, schedules and relationships. Their roles and wants are not assigned by scripted ride sequences.
- **Mobility / offers:** trip demands arise from NPC state and world conditions; origin, destination, urgency, money, constraints and cancellation all matter. Offers may be discovered by street pickups, formal apps or underground channels. Different access, payouts, risk and social reputation. No one mandatory scripted first client.
- **Routes / vehicle:** route topology/elevation, time and risk from authoritative city data; vehicle condition, equipment and operating costs are capabilities rather than per-scene constants.
- **Law / identity / economy:** licensing, surveillance, checkpoints, fake papers and illegal work interact with district economics and social context. Rich formal areas can be institutionally unsafe; underground places can offer social safety but economic/exposure risk.
- **Knowledge / languages / communication:** GPS reveals space; Translator reveals linguistic content it actually covers; Radio reveals communities, local alien-language broadcasts and music even if initially unintelligible. Acquired lexicon must stay stable. Illegal human broadcasts may be physically detectable and socially incriminating.
- **Social state:** NPC memory of encounters, promises, contradictions, favors, refusal, danger, privacy and trust; recurrence is a product of persistent people, not a sequence of handcrafted cutscenes.

Make modules cohesive with explicit inputs/outputs and contracts; no God-object GameSession and no superficial "one file per named system" scaffolding. Keep ONE consistent source of world truth, not one enormous class.

## Ink — semantic authoring, not a scenario scheduler

**Authored narrative** means authored sentences, reaction alternatives, conversational acts, style, interaction rules and rare special writing; it does NOT require authored passenger journeys. A named authored character can exist in a simulation, but their trip demand is still grounded in world state.

**Ink** is a branching scripting/runtime language supporting choices, conditions, variables, dynamic alternatives, tags and runtime integration. Tags are *metadata chosen by the author*, not automatic natural-language semantic understanding. Use Ink to implement conditional conversational policy and deterministic offline expression; it must never own the canonical city, money or NPC facts.

Conceptual pipeline:

1. Systemic NPC situation -> immutable conversation context (speaker identity/language capability, intent, mood, known claims, available actions, current district/risk).
2. Conversation rules + Ink choose **speech act / semantic intent**, permitted response or branches and authored **offline fallback text**.
3. Typed game boundary validates action/effect IDs against actual state; commands/events mutate canonical world state exactly once.
4. Presentation renders the chosen text, passenger expression, optional seat/cabin framing and city cues. Dialogue does not arbitrarily stop world time.
5. Optional LLM **surface realization only**: reword an approved speech act using provided grounded facts/style, never add information, translate unknown languages magically, decide NPC motives, invent choices, facts or trigger gameplay effects. Invalid, unavailable or disabled LLM -> deterministic authored text. No always-online dependency.

Example *semantic payload* (illustrative contract, not existing code):

~~~text
intent: request_route_change
speaker: npc:42
reason_fact: checkpoint:west-ring-active
tone: nervous
allowed_replies: [ask_for_extra_fare, refuse, accept_detour]
fallback_line_id: route.change.nervous.v1
~~~

The same authored response/intent can serve very different passengers because **NPC context is supplied by simulation**. An authored narrative rule library and a sandbox are compatible; an authored passenger ride scheduler is not our foundational gameplay.

### Proven vs future Ink capability

- **Proven here:** pinned pure-GDScript inkgd runs compiled authored Ink text, decisions, effect tags, arrival jump, persistence and Web/Linux runtime; `scripts/narrative/ink_bridge.gd` exposes open/advance/choose/current_frame/jump/snapshot/restore.
- **NOT proven by these tests:** binding dynamic NPC context into Ink, external host functions, reusable semantic intent schema/typed effect validation, compositional fallback selection, dynamic multilingual rendering or optional LLM paraphrasing. These belong to the sandbox foundation.
- Official Ink documentation: https://github.com/inkle/ink/blob/master/Documentation/RunningYourInk.md and https://github.com/inkle/inky/blob/master/app/resources/Documentation/WritingWithInk.md.

## First meaningful systemic acceptance

Across at least two different deterministic seeds or changing world states: multiple NPCs generate different meaningful ride demand with independent expiration; the player can ignore/accept/decline; a journey resolves within the route system; knowledge, money and risk/reputation impact persistent people; offers and effects survive Save/Load without duplicates. The same semantic conversation intent should have **different grounded language** across two independent NPC contexts with an authored offline fallback. Render and actually drive at least one end-to-end play loop on Web/Linux; human feel/Windows execution are independent gates.

**Do not grow the fixed first-clinic passenger into a sandbox, and do not reopen engine debates or create a speculative mega-framework.**

Tracking: https://github.com/MohamedXIV/outsider-driver-2d/issues/15. Prior proofs: [Prototype closeout](PROTOTYPE_CLOSEOUT.md).
