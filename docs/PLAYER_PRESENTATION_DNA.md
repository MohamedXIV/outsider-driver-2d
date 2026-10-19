# Passenger-first UI and world presentation DNA

Status: design correction from the player, 2026-10-19. Historical decisions restored below. The current #77 UI is an experimental adapter, NOT visual sign-off.

## Sources and scope precedence

The original 3D repository remains a required creative source:
- [Visual Style Bible](https://github.com/MohamedXIV/outsider-driver/blob/main/docs/STYLE_BIBLE.md) — approved concept: Hybrid Illustrative Alien Retro-Futurism, tactile painted materials, rounded-but-varied alien architecture, selective ink/soft cel effects, real supported multilayer roads, nonhovering road vehicles, old maintained taxi, district-specific colors and alien signage. Not generic neon cyberpunk.
- [District Boards](https://github.com/MohamedXIV/outsider-driver/blob/main/docs/DISTRICT_BOARDS.md) — each region has functional, economic and architectural history; board specifics remain exploratory, source PNGs are not checked into that repository.
- [Narrative Architecture](https://github.com/MohamedXIV/outsider-driver/blob/main/docs/NARRATIVE_ARCHITECTURE.md) and [Passenger Performance](https://github.com/MohamedXIV/outsider-driver/blob/main/docs/PASSENGER_PERFORMANCE_LIGHTING.md) — actual Ink utterances and semantic cues; presentation must not own truth, suspicion or outcomes.
- [Work Economy](https://github.com/MohamedXIV/outsider-driver/blob/main/docs/WORK_ECONOMY_SYSTEM.md) and [Radio System](https://github.com/MohamedXIV/outsider-driver/blob/main/docs/RADIO_SYSTEM.md) — licensed versus underground life, language-dependent broadcasts, survival and identity are the story.
- **Earlier approved isometric discussion**: upper-right passenger avatar with optional seat/cabin frame, player dialogue choices lower-left, close-follow world remaining visible, and a technology-agnostic PassengerPresenter that can evolve beyond basic spritesheets.
- For ENGINE choices and gameplay use the newer [Sandbox DNA](SANDBOX_GAME_DNA.md), [Game Design](GAME_DESIGN.md), and [Supersession Register](SUPERSESSION_REGISTER.md). Do not resurrect Babylon.js, the old first-person camera, a mandatory Inochi renderer or hardcoded first fare just because the visual references came from 3D.

## User corrections to UI presentation — required direction

1. **No AI narrator copy.** Never pad the UI with conversational/explanatory flourishes such as “The city keeps moving while you read”, “Your passenger speaks first”, “People, not quest markers”. A label must convey a real gameplay affordance, device status, sourced message, route/fare fact or world-authored character statement. No omniscient hints.
2. **Speaker and speech are inseparable.** The actual passenger's avatar/portrait and the source-accurate utterance belong to ONE passenger surface. Do not put alien dialogue in the same card as player responses. On compact screens use a speaker portrait + text together; show only replies in a separate section below. Important passengers can later have expressions, blink, mouth and posture based on authored semantic cues.
3. **Different interaction classes have separate sections.** Player responses, other actions (translator, route, contacts), navigation, wallet, system options and notifications must not look like an unbroken column of equal buttons. Visual hierarchy should be world > passenger > responses > contextual actions > status.
4. **Semantic response color coding is a PROPOSAL**, not a fixed palette. Ask, accept, refuse, evade, silence and tool-mediated responses can use distinct icons, shapes and restrained accent colors once meaningful semantic tags are available. Color must not claim a choice is “good” or “bad” or predict hidden NPC reactions; keep text and non-color cues for accessibility.
5. **Icons and illustrations** should inherit the culture of this alien city: signage, device markings, transport contracts, stamped trade tokens, radio/translator affordances. Use culturally motivated icon shapes rather than a generic mobile-app/AI-dashboard icon set.
6. Preserve EN/Arabic RTL, alien-script non-disclosure, reduced motion, responsive hit targets, actual World authority and saved conversations. A pretty but omniscient HUD fails the design.

## Currency — undecided worldbuilding, not a formatting patch

The prototype uses internal credits / `cr`. Neither the original 3D economy docs nor current 2D game design define a canonical *fictional* currency name or symbol.

Candidates to discuss:
- **Rin (رين)** — short in both languages; concept: a stamped notched-ring emblem recalling circular port infrastructure and trade seals. Name, origin and glyph are PROPOSED, not established canon.
- **Tal (تال)** — short, angular and easy to letter; needs invented institutional background.
- **Vara (ڤارا)** — soft pronunciation; needs cross-locale readability review.

After approval, add one presentation formatter/icon for wallet, fares, markets and receipts; **keep the stored numeric credits unchanged** until there is an engineering reason to rename it. Official vs underground usage may be different socially without requiring invented alternate currencies now.

## Immediate and subsequent slices

P0 now: remove obvious narrator filler while preserving actual dialogue and controls; capture this source-linked design contract.

P1 next, before #50 acceptance: a dedicated passenger+speech component, separate player Replies and Actions groupings, low-noise route/status HUD, optional avatar/cabin visual frame; do not replace the simulation or script a fake passenger.

P2 proposed: semantics-linked response coding, culture-specific icons, currency emblem after the user chooses it, richer animated expressions.

Accept with actual native Godot and exported Chromium screenshots across conversation, unknown language, Arabic translation, rider-initiated question, road scene, market/gear, arrival and Debug; include real choice click, Save/Load, genuine two-route settlements, pointer scrolling, motion accessibility and mobile layout. Human design review remains required.

**Do not merge #77 or close #50 based on automated acceptance alone.**
