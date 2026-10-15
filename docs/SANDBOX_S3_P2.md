# S3 P2 — Returning Driver Recognition and Sourced Encounter Memory

> **Validated technical slice — October 16, 2026.** [Issue #30](https://github.com/MohamedXIV/outsider-driver-2d/issues/30), [PR #42](https://github.com/MohamedXIV/outsider-driver-2d/pull/42). [Godot 4.7.2 CI #38817277932](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38817277932) **PASS** at tested gameplay head `e54812d623e17584aaa214a1e882e5d002f6bcc6` (follow-up documentation changes only).

## Game contract

An NPC **remembering the taxi and driver** is not equivalent to knowing the driver's real name, species, residence status or covert identity. Memory is sourced to interactions that NPC actually experienced: a **completed real ride** recorded as a `fare_settled` world event, or a **locally witnessed refusal** linked to `offer_declined`. A remote offer decline does not create false face-to-face memory.

`SandboxDriverMemory` keeps at most six source-backed encounters per stable NPC ID. Completed rides carry greater salience than one-off refusal: one successful trip marks the driver as recognized, a single minor refusal does **not**, and multiple completed visits may elevate the same ordinary resident to a significant contact. This is **not** a second NPC class or an invitation/romance subsystem. Existing `trust` remains a separate relationship measure.

`driver_identity_facts` is deliberately empty. No fair payment, repeated ride, or sight of the car automatically unlocks claims like 'human', 'undocumented', true name or cover identity. Future actual evidence systems must authorize any such knowledge.

`SandboxWorld` alone records source world events and stores/reloads the NPC memory. Restore validates memory kind, exact originating offer/NPC, event ID, minute, salience, bounded count and absence of fabricated identity knowledge. Experimental save envelope **v8** and world snapshot **v7** require no migration of superseded early sandbox saves.

## Verified player-visible change

The **same actual passenger** who completes a ride later produces another need/offer from ongoing NPC simulation. The same reusable Ink source, now parameterized by `recognizes_driver`, yields a recognition-specific response. For an **untranslated** local-language passenger, the alien line remains untranslated: the player observes a gesture acknowledging the cab, **not magic fluency or automatic identity disclosure**. Trade-language speakers can recognize the driver in words.

The debug UI shows `RETURNING CAB` on the selected offer and a count of NPCs who recognize the taxi. These are prototype inspector aids, not omniscient production equipment or a final cab artwork layout.

## Acceptance evidence

- `tests/test_sandbox_driver_memory.gd`: authentic seed8 local trip; no memory before settlement; event-backed first memory; remote rejection produces no first-hand memory; autonomous genuine repeat passenger offer; changed Ink initial speech; save-and-reload of live Ink+world; second ride elevates contact; forged event source or 'human' fact rejected; deterministic extra seed.
- `tests/test_sandbox_driver_scene.gd`: real default Godot scene, accepts an actual fare, waits for independent new request, selects that same returning resident in the visible `ItemList`, opens contextual conversation, screenshots, saves/reloads an unfinished Ink frame.
- `tests/web_sandbox_driver.cjs`: real exported Chromium mouse interactions with the first fare, actual independent time and a repeat offer; same changed Ink text, untranslated alien words, Save/Reload of the returning encounter. Reviewed `driver-returning-web.png` and `sandbox/returning-cab-native.png` visually: seed8 visitor `npc:01` recognizes the taxi while the player still cannot decode local language. Full legacy P0–S3/Routes/peer cases remain green.
- [CI #38817277932](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38817277932): Linux native/scene and exported Web execution **PASS**; Windows **export** only. Build artifact **12011481145**, visual evidence artifact **12011351408** (~21-day retention). **No actual Windows runtime or human feel test** has been performed.

## Reuse / Replace / Retire and next boundaries

**Reuse:** established NPC identity, co-present social and world events, trust, real taxi routes, shared semantic Ink and authoritative Save/Load.

**Replace:** inert single-number trust as the **only** sign of a repeat encounter; there is now a sourced and player-visible returning passenger.

**Retire:** no new scripted named passenger scheduler, no binary global 'unmask' gate, no forced romance, no second character engine. S2's partial Translator remains **existing experimental proof**, to be replaced at [#32](https://github.com/MohamedXIV/outsider-driver-2d/issues/32), not expanded here.

**Next:** [#31 voluntary off-duty meeting](https://github.com/MohamedXIV/outsider-driver-2d/issues/31), or re-prioritize the simplified language market [#32](https://github.com/MohamedXIV/outsider-driver-2d/issues/32) after confirmation of the unresolved Common starter loadout. Real long-term relationship pacing, social gossip beyond direct sourced knowledge, and full player identity concealment are still open.
