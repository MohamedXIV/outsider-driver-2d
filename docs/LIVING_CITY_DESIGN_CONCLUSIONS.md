# Outsider Driver — Living City, Social Bonds, Languages & Routes

> **Design synthesis — October 15, 2026.** Consolidates the discussions after Sandbox S2 about societies, language presentation, personal identity, persistent relationships, off-duty encounters, route planning and restrained Paradox-inspired simulation. This is a **design reference**, not a claim these systems already ship.
>
> **Status legend:** **Agreed direction** = repeated design intent accepted as a working principle; **Recommended / pending** = assistant proposal or unresolved implementation choice, not locked by explicit approval; **Current proof** = verified in the repository; **Future** = not implemented.
>
> Primary game contract: [SANDBOX_GAME_DNA.md](SANDBOX_GAME_DNA.md). Active tracking: [foundation #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15), [living NPCs #22](https://github.com/MohamedXIV/outsider-driver-2d/issues/22), [languages/equipment #23](https://github.com/MohamedXIV/outsider-driver-2d/issues/23), [route selection #24](https://github.com/MohamedXIV/outsider-driver-2d/issues/24). Archived authored clinic ride is a technical regression fixture, never the NPC content structure.

## 1. The fantasy and the scope ceiling

**Agreed direction:** The protagonist is a human surviving illegally among alien societies, earning a living as a taxi driver. The city is dangerous and socially fragmented; many residents barely know one another. People have independent needs, locations, schedules, finances, cultures and allegiances. The player progressively learns the city rather than reading an omniscient encyclopedia. The taxi is a mobile social space, not just travel between scripted story scenes.

**Do not** add whole-country grand strategy, a thousand authored passenger quests, manual city-wide driving, a full constructed-language grammar, universal translator progress bars, a dating sim, one AI runtime per character, or a Google Maps clone. Systems generate situations; Ink expresses grounded semantic acts; the authoritative world validates the consequences. Offline deterministic authored content remains sufficient.

**Core interaction loop (intended):**

1. Independent population activity creates real needs and mobility offers.
2. The player identifies an accessible pickup, understands what they can of the situation, and chooses a trip and route.
3. The taxi moves semi-autonomously while encounters, traffic/news/risk, dialogue and time continue.
4. NPCs react according to their own knowledge, histories, attitudes and current conditions.
5. Money, schedules, risk, personal relationships and learned facts persist; the city continues when the player does nothing.
6. Off-duty life, meeting known people and buying equipment create new opportunities and exposure.

## 2. Social identity: species is not language is not allegiance

**Agreed direction:** Keep **Species**, **Language**, **Culture**, **Community** and **Faction/affiliation** conceptually distinct, but use the *smallest useful persisted fields* instead of constructing five full simulation engines.

- **Species:** physical/sensory identity and relevant physiological constraints; not a personality preset.
- **Language(s):** what a person speaks or writes; multiple species and communities can share a language.
- **Culture:** learned etiquette, taboos, customs and habits; may blend between groups.
- **Community:** lived social network, place, migration and shared experience, independent of biology.
- **Faction/affiliation:** political, economic or organizational loyalties, possibly contested within a community.
- **Personal identity:** an individual viewpoint, history, memories, temperament, knowledge and relationships, including exceptions to community norms.

**Small language scope:** **three city languages initially**, optionally a fourth **only** if its gameplay contribution justifies it. A common/official/trade language is understood by many residents; one or more minority languages are shared by several species through common ancestry or generations of cohabitation. Language, culture or community boundaries must not be assigned one-to-one to species.

**Social relations are historical rather than random:** shared origin, language, culture and trade provide reasons for familiarity; territorial competition, resource disputes or history provide reasons for conflict. **Affinity and Rivalry are independent dimensions**; neighbors can be familiar, cooperative *and* intensely competitive at the same time. Group-level tendencies never force every individual's position. The Spanish/Portuguese-style close-neighbor rivalry is an analogy, not a required alien faction pairing.

**Separate facts and beliefs:** WorldTruth != NPCBeliefs != PlayerKnowledge. Facts/rumors may have sources, witnesses, age and confidence; NPCs should not acquire private knowledge without contact or a communication channel. Rumors can be mistaken or biased. Understanding the literal words of an insult does not imply knowing that it is taboo.

## 3. Language representation, translators and localization

### Content and writing

**Agreed direction:** Each world language has a **stable semantic lexicon**, a **coherent light phonetic/phrase style**, and a **distinct readable script/glyph presentation**. The same expression (e.g. thanks) should not randomly become a huge sentence in one encounter and two characters in another without a defined context, dialect, register or variation. No full grammar/conlang generator needed. Start with a small catalog of recurrent taxi/social intentions.

**Untranslated:** Render that language's actual alien-script text, with gesture/presentation clues. A different language should look different. Avoid unstable random glyph generation, missing-font rectangles or platform-specific emoji as core writing.

**Translated:** First show alien glyphs, then use a brief, skippable and reduced-motion-safe transition (e.g. crossfade/reveal) to the player's **selected UI language**. Do not attempt expensive character-by-character morphing when strings have different lengths. **Localization is a primary requirement:** dialogues, choices, hints and interface text must resolve via semantic/localization keys; do not hardcode English as the translation target. Design for Arabic RTL/BiDi and other target languages, line length, touch/controller and accessibility. Godot's text/UI facilities should be validated in actual native and Web rendering, not assumed based on an example font.

### Equipment and access

**Agreed direction:** A language module is **all or nothing for that language**: installed -> translated; not installed -> untranslated. No production partial-word/partial-sentence translation progress or per-dialect upgrade bars. Modules should be associated with **languages, not species**, and purchased as physical goods in reachable neighborhood markets; cost/availability and persistence are meaningful.

**Recommended / pending final loadout decision:** The player begins with a **Basic Translator preloaded with the official/common language** so the game remains understandable. One extra **starter choice** becomes **GPS / one additional language module / Radio**. This replaces the older mutually exclusive GPS / Translator / Radio starting choice *if ratified*. Other-language modules are obtainable in-world. The majority of NPCs may speak Common, but not all will willingly switch to it.

**Common-language fallback is a social act, not a universal escape:** If the player says 'I don't speak your language', an NPC may switch to Common, refuse, disengage, remain silent for the rest of the ride or test the player's knowledge. Conditions depend on that NPC's genuine abilities, motives, context and memory. Players can often drive using mapped destination, gesture or dispatch details without understanding all dialogue; not speaking a language should create meaningful risk/opportunity rather than make routine rides impossible.

**Radio:** Ordinary channels may broadcast alien-language speech and strange music. A module does not silently translate unsupported broadcasts. Human transmissions through illicit antennas/frequencies remain a *future* restricted mechanism with consequences if overheard, not default radio behavior.

**Current-proof mismatch — intentional future replacement:** [S2](SANDBOX_S2.md) currently proves one-time GPS/Translator/Radio and **partial learned local route-marker comprehension**. It is **not** the finalized module UX above. Treat S2 as a historical/technical proof to refactor; do not preserve obsolete experimental-save compatibility at the cost of the new direction. Do not mark binary module purchasing or glyph transitions as implemented.

## 4. Optional purchased AR/headset assistant

**Agreed direction:** Smart glasses / AR headwear can display small contextual inline tooltips or on-demand overlays while listening, talking or navigating. Their data source is **only what the player already knows**, with provenance/uncertainty for suspected facts or rumors. They must never reveal secret identities, hidden relationship truth, correct answer flags, future outcomes, omniscient translations or navigation information the player has not obtained.

Example: a highlighted town name can show its known district and local reputation, allowing the player to *reason* about a response. On touch/controller, pressing/focusing the term opens the same information; hover cannot be the only way to access it. The wearable is an **information presentation device**, not an all-knowing AI agent or a second gameplay authority. Purchase, power/inventory and UI polish belong to an incremental equipment slice.

## 5. Persistent recognition, the player's secret, and character depth

### What does a returning passenger know?

**Agreed direction:** An NPC can remember a taxi, driver, voice, kindness, refusal or repeated meeting **without knowing the player's true identity**. Distinguish at least:

- **Recognition:** 'I have seen this driver / vehicle before.'
- **Relationship:** 'I trust/dislike/enjoy meeting this person because of actual encounters.'
- **Identity knowledge:** what they know/suspect about the driver's name, origin, humanity, legal residence, garage or cover identity.

Do **not** collapse all identity evidence into a global `unmasked` boolean. Knowledge can be partial, false, inferred or shared by a real witness. A person may care little about the driver's origins; another may actively investigate. Not everyone must recognize every taxi encounter in a fragmented and anonymous city. Memorable, consequential or repeated encounters should persist; routine brief encounters can remain low-salience.

**Open question:** precisely **how visually and socially concealable human identity is** (appearance, disguise, documents, voice, legal status) has not been settled. Being human, being undocumented and knowing one's real name are distinct claims.

### NPC importance without incompatible character engines

**Recommended architecture:** One coherent character record with *graduated depth*, not an entirely separate NPC system for each class.

1. **Background population:** aggregate or very lightweight independent city activity; no persistent fully simulated individual for every citizen.
2. **Persistent NPCs:** stable IDs, locations, needs, encounters, selected memories and modest relationships. The player can naturally meet them again.
3. **Significant NPCs:** richer ongoing bonds, deeper background, commitments, off-duty locations and specific authored personal material. Some may start deliberately handcrafted; others can become significant through play.

The **importance can grow** based on salient player/NPC events rather than requiring a fixed cast of 'special passengers'. Conversely, not every customer needs a full background, persistent scene or hundreds of memories. Relationship strength is not equivalent to agreement on human rights, political allegiance or personal safety. Don't turn trust/affection into a single 'safety bar'.

### Light romance and off-duty encounters

**Agreed direction:** If a mutual optional relationship develops, it may extend **outside the taxi** into modest real meeting spots (garage/home vicinity, market, cafe, selected dwelling or local hub). Do not promise city-wide apartment exploration or a separate full dating sim. Potential effects include invitations, meeting times, lost work hours, affection/trust, gossip, help, misunderstandings and danger arising from shared knowledge. The other person has agency, schedules, existing relationships and may decline or be unavailable; repeated rides do not automatically imply romance.

**Recommended:** Keep friendship, alliances and non-romantic connections as rich as romance. A small number of authored significant characters are compatible with systemic trip generation, so long as they are not spawned for an arbitrary scripted passenger chain. Unkept promises/late arrivals should have consequences with actual clock/source provenance.

## 6. Trip planning and mid-trip control

### What currently exists

[SandboxRoads](../scripts/sandbox/sandbox_roads.gd) has a **five-district graph** with links and BFS hop counts (10 simulated minutes/hop). [SandboxWorld](../scripts/sandbox/sandbox_world.gd) accepts a generated offer, counts down travel and settles the fare; it does **not** expose a selectable route sequence, a live taxi movement path, route alternatives, waypoints, or mid-trip rerouting. The prior P0 camera/bridge proof is **separate historical technical evidence**, not the current sandbox driving experience.

### Proposed route contract — strong preferred direction, not yet implemented

**Hybrid**: the rider/dispatch provides an actual destination, the game suggests a route, and the **player can choose a suggested route or specify waypoints** on a map. The taxi follows the selected path semi-autonomously; no manual steering requirement.

- **Map pin alone** is sufficient for casual/quick travel: automatically select a known/default path.
- **Suggested route profiles** (e.g. quickest, lower exposure, via a place) are available only when their relevant map/risk information is actually known; they are not omniscient previews or guaranteed safe outcomes. The exact number/names of route profiles remain to be decided.
- **Manual route/waypoints** allow a driver who knows the neighborhood to pick junctions or districts instead of accepting the default route.
- **Mid-trip reroute** is an intended core affordance. A change is applied at the **next valid graph junction/segment boundary**, not via teleportation or instant turnaround.
- **Passenger route requests** can involve avoiding a district/checkpoint, stopping somewhere or changing destination. Small ordinary deviations differ from large detours/changed destinations; the latter may require consent/fare renegotiation and affect trust, schedule, risk and reputation. Route *length* and destination *contract* are not the same thing.
- **Economics/time/risk** are computed by the authoritative road/world domain from topology, hazards, known restrictions and vehicle condition—not invented by Ink or the visual taxi node.
- GPS is an **information advantage**, not a gate preventing a basic ride: signs, route familiarity, memorized districts and dispatch instructions may also support driving.

### Technical stance

**Use Godot's built-in `AStar2D` on a small shared authored road graph** (and reusable route definitions/waypoints) if/when the implementation needs weighted shortest paths; no custom city-scale routing engine or imitation Google Maps. Pathfinding proposes paths; the graph encodes which roads/junctions/elevations are connected; the movement presenter animates the actual taxi; the world verifies time, risk and settlement. Elevated roads that overlap visually are *not* connected unless an explicit ramp/edge exists.

BFS is enough for today's unweighted five-district S0–S2 proof. Upgrading to AStar is only justified alongside visible route choice/rerouting and weighted reasons to choose one route over another. The chosen road graph must remain reusable for NPC trips too.

## 7. How social and route gameplay reinforce each other

**Illustrative systemic situation — NOT a scripted ride:** an NPC requests a longer route to avoid a rival community's market or a checkpoint. The request arises from **their own actual history, knowledge and risk**, not a named passenger quest. The player may understand the words but not the cultural implications; ask for Common, accept the detour, negotiate, refuse or reroute. The NPC may remember the decision. Another NPC may hear the story *only if the source has a valid contact/channel*. The player might subsequently meet that person off duty. The same route options can create different consequences with another person's context.

Time and social bonds compete meaningfully: taking a safe long detour might make a later off-duty meeting late; a faster route might incur legal scrutiny. Do not secretly assign a single 'correct answer' or always reveal optimal risk through AR.

## 8. What to borrow from Paradox, and what NOT to borrow

**Design inspiration, not a claim of reimplementing Clausewitz:**

- **CK3-style character significance:** a few traits, relationship facts, remembered encounters and salient social reactions matter more than large banks of fixed scene scripts.
- **Victoria-style population abstraction:** independent population aggregates provide city demand; named/persistent NPCs receive deeper simulation only where player interaction or consequence warrants it.
- **Simulation update cadence:** immediate commands/events; short periodic NPC/offer ticks; occasional/daily group economy and community changes; expensive reactions/Ink conditions evaluated **on demand**. No full recomputation of every relationship each rendered frame.
- **Explainability:** for a refusal, reroute or social suspicion, a debug trace should show *which witnessed fact, memory, offer constraint or world condition* caused it. Stable event IDs and deterministic seed behavior matter more than a large complex AI tree.

**Explicit non-goals:** 1:1 CK3 diplomacy, all-citizen deep cognition, bespoke faction simulation per species, full grand-strategy politics, speculative performance systems, Rust/Web Worker-style optimization without a measured need.

## 9. Milestone mapping and testable acceptance

**S3 / [#22](https://github.com/MohamedXIV/outsider-driver-2d/issues/22):** independent NPC routines, unserved transport alternatives, persistent personally grounded memory, at least one real NPC-to-NPC interaction, social identity constraints and visible consequences **without the player initiating everything**. Keep S3 small and playable; do not drag in font/tool markets or a dating sim before the social core works.

**Languages, hardware, accessibility / [#23](https://github.com/MohamedXIV/outsider-driver-2d/issues/23):** stable three-language lexicon/script, binary language modules from actual physical shops, common-language negotiation, localized glyph-to-translation transition (incl. Arabic RTL and reduced-motion), assistive knowledge-only headgear. Replace S2 partial translator when this becomes an executable slice.

**Routes / [#24](https://github.com/MohamedXIV/outsider-driver-2d/issues/24):** live journey with 2+ valid graph alternatives, default map-pin routing, a player-set waypoint, legal mid-trip reroute at a junction, route/time/risk/event provenance, NPC route request and verified state recovery. Do not add only a route-list UI atop the current instant-settlement timer.

**Significant relationships (incremental follow-on):** repeated encounter recognition without requiring unmasking, real promises/appointments, one off-duty location interaction and save/reload. Romance remains an **optional extension** on top of general relationship machinery, not an S3 foundational gate.

**Cross-cutting technical proof:** deterministic native domain tests, real Godot Linux scene screenshots, exported Chromium interaction, save/load with no duplicate consequences; Windows runtime and human driving/readability/comfort remain independently unverified. No feature is 'shipped' on the strength of this design document.

## 10. Deliberately open decisions

These should be settled only when building the smallest relevant playable slice:

1. **Disguise/identity:** how obviously human is the protagonist, and what can disguise reveal or conceal? Separate human origin vs legal residency vs cover name.
2. **Default Translator:** whether Basic Common translation is mandatory from start. **Recommended yes**, with optional GPS / extra language module / Radio starter, but not yet an unambiguous gameplay implementation decision.
3. **Language inventory:** final names/sound families/glyph aesthetics for the three languages, plus which groups know Common and why.
4. **Relationship scope:** how many authored significant NPCs, how/when regular NPCs gain salience, how durable low-salience memories should be, and which bounded off-duty locations ship first.
5. **Route presentation:** exact route-planning interaction, when rerouting pauses/continues, and what knowledge each route preview reveals. Default shortest path vs fastest/safest depends on actual street data and hazards.
6. **Fare agreements and detours:** when the passenger can ask for a diversion, veto one, abandon the ride or renegotiate; avoid a fixed universal reaction.
7. **Simulation detail:** how coarse population updates and autonomous NPC routines should be at first playable proof; keep constraints measured against actual fun and clarity.

**Guiding rule:** Make **language hardware simple**, while reserving systemic complexity for **who knows whom, what they believe, which route they ask for, and what the player's choices cost**.
