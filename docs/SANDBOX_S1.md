# Sandbox S1 — Contextual Semantic Ink (work in progress)

This milestone connects the **real S0 population and offer**, not a fixed passenger script, to one reusable Ink conversational policy. It does not generate NPC histories, languages or trip motives in Ink: the simulation supplies them.

## Ownership boundary

- `SandboxWorld` owns the offer's origin, destination, fare, purpose, validity, NPC funds, language, temperament and changing need. It alone validates `accept(offer_id)` / `decline(offer_id)`, and records the canonical event.
- `SandboxConversation` reads a live, local open offer and its NPC. It builds a copy of `understands_speaker`, `urgent`, `temperament`, `destination` and `purpose`. No passenger ID branches, and no claims about another NPC's mind.
- Reusable authored `stories/sandbox_dialogue.ink` has speech-act metadata `intent:request_trip`, `intent:ask_destination`; choice tags `action:accept_offer`, `action:decline_offer` represent **proposed commands**. These tags do not mutate world truth; world commands may reject illegal dispatch, expired offers or duplicate attempts. No server/LLM dependency.
- `InkBridge` now optionally injects validated primitive globals before the story advances, keeping existing prototype reads/choices/tags and save support intact.
- `SandboxSave` v2 stores the full authoritative world **and** the still-pending story state. On reload, a conversation is reconstructed only for the identical available local offer; an already expired or completed request is not revived by old dialogue.
- The real Godot sandbox now has **Talk to NPC** beside existing direct dispatch commands and an interaction panel. Time continues to pass while speaking, so the NPC may leave and their request may expire.

## Language, truth and authored fallback

A resident who speaks the player's understood trade language can name the requested `destination` and reason `purpose`. A resident whose local alien language is not understood only produces **authored, deliberately unintelligible utterances** and gestures; a text label does not suddenly provide translation. The dispatch/map still displays route metadata independently of speech, so *knowing a mapped destination* is not equivalent to understanding its spoken name, motives or local grammar.

Repeated semantic intent across real NPCs yields different deterministic fallback phrasing based on language/temperament/urgency. There is no LLM requirement, inference of unknown translations or arbitrarily generated world knowledge. Later we may allow a carefully constrained LLM to **rephrase approved grounded lines only**.

## Engineering validation

- `tests/test_sandbox_dialogue.gd`: same intent applied to 2 seed-8 dockside NPCs with different language contexts, and a trade-speaking seed-9 resident; asks destination in Ink, restores an unanswered choice, accepts or declines through world commands, rejects an inaccessible official job and duplicate settlement, and rejects expired offers.
- `tests/test_sandbox_scene.gd`: opens the real scene, converses with an untranslated resident, saves/reloads pending Ink, accepts through the native choice button and completes a route.
- `tests/web_sandbox_smoke.cjs`: exported Chromium click-through including live unknown-language utterance, pending Ink save → browser reload → restore → accept → paid fare → new seeded city.
- The CI uses pinned inkjs 2.4.0 compiler; the canonical compiled `.ink.json` is committed alongside the `.ink` source and equality-checked (after BOM normalization) for offline Godot launch.

## What S1 does not yet provide

A full linguistic progression/Translator lexicon, social relationships or character memory, dynamic negotiation, offline multilingual localization, general-purpose intent ontology, optional LLM integration, return-to-cinematic road presentation, real Windows runtime and human feel tests. These remain explicit follow-ups on [Sandbox Foundation #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15). The S0 map art is still schematic, and authored fallback is intentionally a small **reusable** dialogue policy rather than a passenger scenario.

## Verified runtime evidence — October 15, 2026

**PASS:** [Godot 4.7.2 Linux/Web/Windows-export CI #38700179310](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38700179310) on gameplay, tests and compiled Ink commit `c2bef385f8bf518d1f20ff8fc7f26371a64c6024`. It includes compiler-parity proof for both the archived P1 story and new S1 shared `.ink`/`.ink.json`; all P1/P2/S0 domain regressions; real `SANDBOX_SEMANTIC_INK_PASS` with **unknown-language NPC at seed 8, trade-language NPC at seeds 8 and 9, official-work rejection, decline, mid-choice rehydration, expiry, duplicate prevention**; actual native sandbox scene click-through; Linux runtime export/boot; real Chromium interactive dialogue/save/page-reload/restore/paid fare/reseed; and Windows **export only**.

Screenshot evidence in [the CI artifacts](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38700179310): `sandbox-unknown-speech.png`, `sandbox-restored-dialogue.png`, `sandbox-settled.png`, native `sandbox/speaking-unknown-language.png`, `sandbox/restored-ink-choice.png`, `sandbox/settled-demand.png`. Browser screenshot confirms NPC 01's unfamiliar language remains unintelligible after asking a destination; the pending Ink decision survives browser reload. The **same** world subsequently settles the fare once, using its own authoritative domain system. Art is still a schematic debug layout, not final approved isometric/cinematic gameplay.

CI also packaged **outsider-driver-playtest-builds** artifact `11956435640` (Windows/Linux/Web), screenshot artifact `11956425612`, both currently retained about 21 days. Real Windows play, human pacing/readability, dynamic translator progression, contextual memory and wider sandbox design still need separate acceptance.

A previous S1 run exposed an Ink authoring error: an `intro` knot had no initial divert, resulting in an empty story frame. After adding `-> intro`, semantic tags and effects were verified. A later native assertion referred to a newly auto-selected offer rather than the original accepted offer and was corrected. The committed bytecode is now canonical with normalized compiler output, including a real newline rather than a literal backslash-n. These are regression gates, not claims of finished production text.
