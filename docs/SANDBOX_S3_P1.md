# S3 P1 — Witnessed NPC-to-NPC Contacts

> **Verified October 16, 2026:** [#29](https://github.com/MohamedXIV/outsider-driver-2d/issues/29) follows [S3 P0 autonomous routines](SANDBOX_S3_P0.md) and the [Routes P0–P1 player journey](SANDBOX_ROUTES_P1.md). Green [Godot 4.7.2 CI #38811261745](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38811261745), tested gameplay SHA `3a0699fd45f6ced09ca58e52d000ef4c2e184f3a` (the documentation commit follows). Linux visible scene and exported Chromium pointer/Save/Load were actually exercised, Windows was **exported but not run**.

## Executable contract

- `SandboxSocial.pick` only proposes a real meeting when **two persistent residents have the same district, are not in transit, and currently share a usable language**. Each can participate at most once per day, contacts checked once per hour and deterministic resident ordering; no phantom meetings, scripted named encounters or per-person LLM workers.
- NPCs now have small distinct identity components (`species`, `community`) and existing languages. **They are NOT equivalent dimensions:** different species can share the same language, and community and home can differ. Names `kind:a`, etc., are provisional engineering identifiers, not finalized alien canon. The later three-language product taxonomy remains #32.
- Group tendencies are grounded but bounded. `affinity` counts shared home, language and community; `rivalry` independently counts work and neighborhood competition. Both can be positive or high simultaneously; individuals are not forced to hate anyone based on their species. This is a minimal relation prior, **not** a CK3/Paradox-style diplomacy engine.
- `SandboxWorld._apply_peer_contact` executes the actual transfer and owns `npc_peer_contact` events. A solvent neighbor may transfer **2 credits** to an NPC with a high current need; this changes **both** wallets and future available ride budget. Independently, speaker shares **their own home** with the specific recipient: `peer_knowledge["residence:<speaker>"]` records exact value, speaker ID and **source world event ID**. Both record a bounded personal contact. No other resident or player gains the information via global broadcasting.
- Restoring a world checks each stored peer fact is supported by a matching `npc_peer_contact` event naming the correct receiver/fact/value; forged source IDs fail. Deterministic 24h replay works before and after 12h save/reload on seeds 8, 9 and 17. A single unified SandboxWorld owns simulation, money, contacts, future demand and the player taxi; no second GameSession.

## Visible and headless verification

- `tests/test_sandbox_peer.gd`: first real meeting in seed 8/9/17 at physical co-presence, different species sharing local language, independent affinity/rivalry, receiver's sourced autobiographical fact, no leaked fact to uninvolved NPCs, repeatable 24h deterministic replay and forged event rejection.
- `tests/test_sandbox_peer_scene.gd`: actually presses **Observe +6h** inside the default Godot sandbox, verifies a real peer world event and recipient's knowledge, captures `sandbox/peer-contacts-idle.png` and saved/restored result.
- `tests/web_sandbox_peer.cjs`: exported Chromium starts with zero peer contacts, presses the real 1280x720 Observer button, sees counters become nonzero and a named co-presence, reloads a persisted world and sees the same known facts. `peer-contacts-web.png`, `peer-restored-web.png` reviewed: seed8 produced **3 contacts and 3 sourced peer facts by 14:00** in this small test world. The screenshot is an **engineering inspector**, not a final playable map or omniscient player knowledge UI.
- [CI #38811261745](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38811261745): canonical Ink source/bytecode, all S0–S3/Route P0–P1 domain/native/browser regressions and new P1 social checks PASS. Artifacts **12007904401** (Linux/Windows/Web playable builds) and **12008228978** (native/Web screenshots) retained ~21 days.

## Supersession and bounded scope

**Reuse:** existing stable NPC IDs, S3 work/rest/independent travel, shared event ledger, world-owned real fare and source-checked knowledge principle, current two-language prototype.

**Replace:** previous **absence of NPC peer interaction**. The NPCs now actually meet and exchange resources/information in one co-present contract instead of magically transmitting rumors.

**Retire:** no tests/old camera were resurrected. This does **not** implement the full final species/languages/culture/factions, nor authorize translated dialogue for unsupported languages. S2 partial-translation prototype will be replaced by binary language modules under #32.

**Still open:** [#30 personally witnessed player-driver memory and recognition](https://github.com/MohamedXIV/outsider-driver-2d/issues/30), rumor transmission beyond direct private meetings, optional significant relationships/off-duty visits #31, believable large city balancing, final isometric illustrated cab, and human/Windows runtime acceptance.
