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

## P1 implementation slice — portrait speech composition (2026-10-20)

Player Mode now uses a dedicated read-only `SandboxPassengerSpeech` view for **both**
Ink passenger turns and World-owned rider-initiated speech. The real utterance
is beside the matching portrait on wide desktop, or beside a small version of
that same portrait inside the narrow scroll region. The scroll region contains
only player `RepliesSection` and optional `ActionsSection` controls during
conversation; the line is no longer mixed into a single undifferentiated list.
The native direction of untranslated alien glyphs is preserved even in Arabic
UI. The portrait does not reveal character identity, context or hidden facts.
Nothing here changes Ink commands, rider scheduling, NPC knowledge or save
state. This is an initial *layout* correction only: full art polish, custom
icons, semantic intent colors and a canonical currency name remain deferred.

`tests/test_passenger_speech_scene.gd` exercises a genuine opening Ink turn,
actual portrait/line identity, distinct button grouping, compact layout,
unknown-language direction and Debug isolation. Existing in-game Player Mode
and genuine exported Web regression suites remain required at exact head.

## Native rider-initiative acceptance correction — 2026-10-20

The original `tests/test_rider_initiative_scene.gd` contained a historical
assertion requiring a direct `Passenger` heading in the old mixed-content
player panel. That assertion became obsolete when actual speech moved beside
the passenger portrait. The revised integration test checks the **real World
rider question**, the **same resident identity** used by the live portrait,
separate `RepliesSection`/`ActionsSection`, and preserves the original
Save/Load and once-only decision/event assertions. It is a UI-specific
acceptance update on the child #77 branch; do not mistake it for a change to
the upstream rider-initiative simulation or acceptance of the visual art.

## Focused cabin-interface visual calibration — 2026-10-20

Reviewed **real successful exported Chromium screenshots** from exact-head
[run #39344278097](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/39344278097):
`web-passenger-speaks-first-en/ar`, `web-player-dialogue`,
`web-player-travel`, `web-player-arrival` and the compact Arabic screen.
Dialogue is adjacent to the real passenger in EN and Arabic, not part of the
response panel, and the genuine fare/arrival and reply buttons passed. The
presentation still feels like an early technical interface rather than final
cab art, so acceptance remains explicitly pending.

This small iteration introduces **physical cab-inspired material grouping**:
painted enamel, restrained worn-metal seam/fasteners and an avatar-side join
for the passenger-speech unit; differentiated Replies versus Actions trays
using warm vs neutral surfaces. These tones indicate component ownership, not
which choice is morally correct, safe, or favored. They are a revisable trial
based on the original [3D visual direction](https://github.com/MohamedXIV/outsider-driver/blob/main/docs/STYLE_BIBLE.md),
not the approval of a final style or a fabricated historical currency/logo.
Exact-head native, browser, phone, Arabic RTL, actual Ink, rider initiative
and Save/Load remain mandatory before a design-review build can be proposed.

## UI scene instrument and street dispatch pass — 2026-10-20

Reviewed prior passing Chromium captures from #39350544708. The major
remaining "technical Godot form" issue was the single header string
`OUTSIDER / location · N cr`, and the undifferentiated street
`Wait / Talk / Accept / Decline / [fare]` action list. These were
presentational, not authoritative World/Ink decisions.

The driver HUD now shows the **actual current stop** as a place heading,
**region/time/grounded travel state** as a quieter instrument line, and the
existing numeric `cr` amount in its own small money counter. This is
**not** currency canon; Rin/Tal/Vara are still undecided. The system
Debug toggle remains visibly separated rather than disguised as gameplay.
The Street panel preserves the stable Wait target, then presents
**SelectedFareSection** (actions on the selected, actual visible fare) and
**FaresSection** (real open local fares) in separate readable trays; the
compact viewport no longer repeats helper/narrator prose between them.
The map legend is now a concise key rather than a tutorial paragraph.
No offers, prices, eligibility, risk or player decisions are fabricated.

Native regression now asserts distinct location/wallet/device surfaces,
stable mobile layout and a real local dispatch group; the full linked
Chromium click/route tests remain required. Gear/device visuals are a
separate future step; no unrelated simulation or controller rewrite.

## Cab instruments, fitting and market counter — 2026-10-20

Verified [#39357802273](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/39357802273)
**fully green on exact HEAD** for the previous Street/telemetry changes.
The exported Web screenshot of `web-gear.png` still showed a single flat
technical list of disabled buy/install buttons. New UI compartmentalizes
**actual installed cab hardware** from **physical fitting/controls** and
**Linguist market purchases**, matching the earlier 3D fiction of a patched
older taxi with real local-market access. `SandboxCabGearPlate` renders a
small enamel plate with simple GPS road fork, radio tuning dial, translator
cartridge markings, and eyewear silhouette. These are read-only **functional
pictograms**, not invented alien written text or finalized cultural emblems.

Starter remains exactly one real GPS / Local translator / Radio choice.
Equipment statuses are read from `starter_device`, `modules_installed`,
`ar_owned`, and `ar_equipped`. All purchases and installs remain the
original controller actions and disabled-state gates; the presented
numeric prices remain 8/9/5 technical credits, never a named fiction
currency. No additional radio language, official permit, translator skill,
market stock, or income is granted by these plates. The UI keeps the real
Concourse Market travel command and 06:00–20:00 Linguist hours.

`tests/test_cab_gear_scene.gd` covers the actual World-backed starter
selection, read-only view, real controller interaction, Arabic RTL, 44px
buttons, responsive compact sheet and Debug exclusion. The existing
Chromium integration must still purchase/install Local and Cant, equip AR
and perform one real fare. This slice is deliberately **not** the final
visual identity or a general-purpose inventory rewrite.

## In-world Gear screen: cross-tab navigation and city priority (2026-10-20)

Exact-head [CI #39361967888](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/39361967888)
**passed all native + Chromium suites** on `3e58c0b`, confirming actual
GPS selection, market purchases, Local/Cant installation, AR wear, real trips
and Save/Load. Screenshot review exposed a UI issue unrelated to World:
when switching into Gear from a scrolled-down Settings/Street panel, Godot
reused the previous tab's scroll offset, so the cab equipment heading and
top instrument plates could be missing entirely. The fix resets scroll
**only when changing tabs**, preserving position on purchase and live
refreshes of the same page. Active navigation has a selected visual state.

An unneeded "No nearby fares" cross-tab guidance panel also took up a large
part of the city while using Gear. Gear now suppresses **routine** guidance,
but an actual open conversation or pending rider-initiated question still
qualifies for cross-tab attention. This adds no knowledge or gameplay effects.

`test_cab_gear_scene.gd` now validates initial gear layout, tab ownership,
cross-tab top restoration, same-tab scroll preservation and quiet nonurgent
Gear mode. Human review still required; no new style, currency or World
mechanics were approved.
