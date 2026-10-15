# Game Design — Outsider Driver 2D

## Core fantasy

**Survive by learning how to belong somewhere you do not belong.** The protagonist is a human residing illegally in an alien city that prohibits or persecutes humans. They operate an old taxi under a cover identity.

The taxi is the main social space: each passenger can teach you something, pay you, suspect you, like you, betray you or help you.

## Primary loop

Persistently simulated NPCs experience needs/constraints → those needs create ride demand in a changing city → accessible official/underground channels expose offers → player accepts/declines/negotiates → vehicle travels reusable graph paths through real district risks → spoken interaction uses context-grounded semantic choices → resulting knowledge, money, social and legal consequences are committed → repairs, learning and return continue the world.

Travel is semi-autonomous and **does not pause for ordinary dialogue**. As the destination approaches, the narrative avoids opening new long topics; once arrived, the taxi stops and the passenger can finish, react, or be told `We've arrived`. Safe exit points are authored; the story is never cut mid-sentence without intent. Reading/choice UX must not become a race by default.

## Design pillars

1. **Knowledge is progression:** learn geography, languages, local customs, slang, attitudes, contacts and institutions; learned facts must be usable later.
2. **Lies have memory:** store claims, audiences and contradictions; confidence without knowledge can increase suspicion.
3. **Relationships are not safety meters:** trust/affection are distinct from an NPC's stance toward humans. Romance and betrayal are authored consequences, not stat unlocks.
4. **Survival economy:** taxi fares, legal/underground job networks, repairs, housing expenses, equipment and forged access. Greater capability can create exposure.
5. **The living city:** radio stations, local traffic/news, recurring passengers and districts react to the player's actions and time.
6. **The taxi matters:** passenger pickup, time, route choices, checkpoints, cabin upgrades and risk remain gameplay, even without manual steering.

Starter knowledge choice: **GPS / Translator / Radio**; they respectively unlock spatial, linguistic and societal information. Basic semi-autonomous driving is standard.

## Content model

NPCs are autonomous persistent inhabitants; trip demand is systemic, **not** a fixed passenger catalog or authored scenario schedule. Their identities, needs, budgets, intentions, languages, associations, time and location constrain the available offers and conversations. Ink remains an authored *conditional interaction and response* system: intent/speech-act tags, authored fallback utterances and optional variations based on context. A typed command boundary validates all meaningful actions and stores their consequences in the simulation. Optional LLM participation can only paraphrase an approved grounded utterance, not invent facts, actions, motives, choices or world changes. See [Sandbox Game DNA](SANDBOX_GAME_DNA.md).

The existing dockside-clinic Ink passenger is a **frozen test fixture** that proves compiler/runtime/choice/tag/save interoperability. Do not expand it as the default NPC architecture.

## Presentation

- True 2D isometric/axonometric world, close enough for streets and vehicles to feel present rather than like a city-management map.
- Animated 2D passenger portrait upper-right; optional stylized taxi seat/cabin background; dialogue choices lower-left.
- The world continues during the conversation. Cabins need not be rendered as a literal 3D space.
- Apartment/garage may be walkable in bounded scenes. Small neighborhood hub is **deferred**, not promised for the first ride.
- Preserve **Hybrid Illustrative Alien Retro-Futurism** as an *art identity*: warm, tactile, alien-built environments and different local histories; avoid generic neon cyberpunk and Mad Max. The earlier reference images establish **camera composition**, not their color palettes or production technique.

## Scope guardrails

No manual/open-world driving, city-wide free walking, full traffic physics, combat, huge procedural crowds, general-purpose puppet engine or C++ rewrite. Add a feature only where it makes the playable loop stronger.

The first SANDBOX milestone must demonstrate *multiple independently generated NPC mobility demands*, persistent consequences and reusable grounded dialogue intent in a small world slice, rather than a convincing single fixed ride. See [Prototype Closeout](PROTOTYPE_CLOSEOUT.md).
