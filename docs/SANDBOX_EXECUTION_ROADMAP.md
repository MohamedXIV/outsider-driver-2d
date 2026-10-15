# Outsider Driver — Active Sandbox Execution Roadmap

> **Active roadmap, October 15, 2026.** This supersedes the **archived prototype** `ROADMAP.md` for future sandbox implementation. It contains the dependency order for small independently verifiable PRs, not a promise that the designs already run. It is linked to the GitHub Epic and detailed issues.
>
> **Epic:** [#15 — Sandbox Foundation](https://github.com/MohamedXIV/outsider-driver-2d/issues/15). **Canonical design:** [Living City Conclusions](LIVING_CITY_DESIGN_CONCLUSIONS.md) and [Sandbox Game DNA](SANDBOX_GAME_DNA.md).

## Verified foundation — do not reimplement

| Slice | Status and evidence |
|---|---|
| S0 — seeded population, independent generated offers, five-district BFS, fare events and persistence | **Merged** [PR #17](https://github.com/MohamedXIV/outsider-driver-2d/pull/17) |
| S1 — live NPC-context Ink speech acts, blocked/accepted choices, alien fallback, pending dialogue save/reload | **Merged** [PR #19](https://github.com/MohamedXIV/outsider-driver-2d/pull/19) |
| S2 — starter GPS/Translator/Radio and first earned route marker; working native and Web proof | **Merged** [PR #21](https://github.com/MohamedXIV/outsider-driver-2d/pull/21), [green CI](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38707320272) |
| S3 P0 — work/rest routines, independent timed shuttle/walk alternatives, 24-hour idle replay and native/Web observation | **Merged** [PR #37](https://github.com/MohamedXIV/outsider-driver-2d/pull/37), [green CI](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38767914997); [proof](SANDBOX_S3_P0.md) |

**Critical limitations now:** S0–S2 is still a schematic debug sandbox; its taxi currently completes a district trip after a timer, not along a selectable visual route. NPC needs, work/rest and ignored-demand alternatives now change without the player, but routine pacing is still a small untuned proof; deep social memory and peer relations are not implemented. The implemented S2 **partial** translation proof is *not* the simplified production language/module design. Actual Windows gameplay and human pacing/visual acceptance are untested.

## Execution waves (small playable slices, not huge phases)

| Priority | Task | Dependency | Player-visible exit proof |
|---|---|---|---|
| **DONE — A** | **[#26 S3 P0: NPC autonomous routines & travel alternatives](https://github.com/MohamedXIV/outsider-driver-2d/issues/26)** | **PASS** [PR #37](https://github.com/MohamedXIV/outsider-driver-2d/pull/37) | Work/rest and timed alternatives demonstrably evolve for 24h without the player; native/Linux/Web proof [#38767914997](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38767914997) |
| **NOW — B1** | [#27 Routes P0: path selection + visible semi-auto taxi](https://github.com/MohamedXIV/outsider-driver-2d/issues/27) | #26 **complete** | Two different true connected paths, map/waypoint selection and actual segment-by-segment taxi movement |
| **B2** | [#28 Routes P1: junction reroute + rider consequences](https://github.com/MohamedXIV/outsider-driver-2d/issues/28) | #27 | **Implemented/verified (PR #40, CI #38809189586):** queued connected suffix at next junction, NPC accept/refuse changes trust, live Linux+Chromium and save/replay |
| **C1** | [#29 S3 P1: NPC↔NPC contacts and local knowledge](https://github.com/MohamedXIV/outsider-driver-2d/issues/29) | #26 | **Verified technical slice (PR #41, CI #38811261745):** grounded co-presence, source-backed knowledge, modest peer aid and native/Web replay |
| **C2** | [#30 S3 P2: recognition, memories and cover identity](https://github.com/MohamedXIV/outsider-driver-2d/issues/30) | #26, #29 | Returning passenger remembers a real encounter yet need not know driver is human / undocumented |
| **C3** | [#31 Relationships P0: optional off-duty meeting](https://github.com/MohamedXIV/outsider-driver-2d/issues/31) | #30 | One recurring contact invites the driver to a bounded location at a real time, can be missed/declined, with persistent consequence |
| **D1** | [#32 Languages P0: 3 shared languages + market modules](https://github.com/MohamedXIV/outsider-driver-2d/issues/32) | #29 for shared-community data | Two different species sharing language use ONE purchasable full-support module; no partial translation |
| **D2** | [#33 Languages P1: scripts, translation reveal and localization](https://github.com/MohamedXIV/outsider-driver-2d/issues/33) | #32 | Alien glyphs are stable; translation is into selected interface language, including Arabic RTL; animation can be skipped |
| **OPTIONAL E** | [#34 AR knowledge-only contextual hints](https://github.com/MohamedXIV/outsider-driver-2d/issues/34) | #32, preferably #33 | Purchased headgear shows only player-known facts with rumor/source, no hidden-answer cheats |

**Milestone/area-level tracking:** [#22 Living NPCs](https://github.com/MohamedXIV/outsider-driver-2d/issues/22) covers #26, #29, #30; [#24 Route Gameplay](https://github.com/MohamedXIV/outsider-driver-2d/issues/24) covers #27–#28; [#23 Languages & Equipment](https://github.com/MohamedXIV/outsider-driver-2d/issues/23) covers #32–#34. #31 is a deliberate small follow-on to #30, NOT a dating-system prerequisite for S3.

## Explicit ordering rules

1. **#26 COMPLETE** with [S3 P0 proof](SANDBOX_S3_P0.md). Do not rebuild basic idle-day NPC autonomy, expand obsolete S2 partial translation, or tune full city traffic before player driving works.
2. **Implement #27 NEXT**: player-facing selectable paths and real taxi travel; then #28 junction reroute; do not finish a giant social simulation or introduce hundreds of character records before the taxi has selectable paths. #29 can proceed after #26 when ready, but **not as a blocker** for #27.
3. Build on concrete encounter outcomes for #29–#31. A recurring driver can be *recognized* without the NPC learning the driver's human origin, legal status or real name. More detailed characters can emerge from normal NPCs, but large handcrafted companion questlines are not required.
4. **Only then** broaden language/equipment presentation (#32–#33). Languages are shared across species; start with **three**, fourth only if useful. Module access is binary installed/absent, not gradual linguistic proficiency. The proposed Basic Translator with Common preinstalled and one GPS / extra-language / Radio bonus starter is still a **recommended, not yet ratified** final loadout.
5. Headset AR #34 is **optional**, not a critical dependency for completing the core taxi sandbox. It never invents facts or gives optimal answer flags.

## Mandatory supersession preflight — avoid repeating retired work

Before picking up ANY child issue: read [Current vs Superseded Contracts](SUPERSESSION_REGISTER.md), [Engineering Rules](ENGINEERING_RULES.md) and latest current user decisions. Inspect live `main`, PRs, issues and relevant code/tests; do not assume a previous handoff is still true.

Every implementation PR must explicitly identify **Reuse / Replace / Retire**, affected modules and obsolete acceptance tests. If an old CI assertion encodes **superseded behavior**, update/replace that assertion with a test of the new approved behavior; do not silently preserve both. Retain frozen engine/compiler proofs only while they still prove useful compatibility.

The documentation may contain *historical* or *recommended* features, but only currently approved contracts become implementation requirements. Scope and dependencies are revised before code when changed by newer decisions.

## Minimum Done contract for each child PR

- **Simulation-owned causality:** single authoritative World state; typed commands/events with stable IDs and explainable sources. No Ink/LLM/UI source of truth.
- **Determinism:** same seed and player commands reproduce outcomes; no duplicate charges/trips, and save/reload mid-situation retains correct consequences.
- **Actual play evidence:** headless native correctness plus **visible** Linux Godot scene/screenshots and **exported Chromium Web** interactions, not just pure unit tests or a design mockup. Windows **export** is distinct from tested Windows **runtime** and neither proves human UX.
- **Regression:** keep S0–S2 correctness/invariants that remain valid; deliberately replace outdated gameplay expectations (especially partial Translator and historical route timer) once their successor implementation is approved and tested. Frozen P0–P2 clinic proof may remain an isolated compiler/engine smoke; it never defines the current gameplay.
- **Small cohesive code changes:** no monolithic world controller growth, no one-file-per-10-lines explosion, no premature C++/Rust/Workers or expensive performance exercises. Use existing Godot systems including AStar2D only when truly useful.
- **No speculative CI runs:** use a meaningful CI gate for gameplay acceptance, not for editing a roadmap or issue. Never check a task as done merely because a source file exists.

## Deferred and genuinely unresolved

The visual legibility and exact timing of route-choice UI, true protagonist disguise/humanity detectability, exact named language scripts, the optional nature of NPC affection/romance, and the proposed Common default translator loadout remain decisions at the relevant implementation step. Avoid creating research-only epics until a playable slice demands them.

This is a **working execution board**, not a rigid time estimate. Adjust the ordering when actual dependencies or playtest evidence justify it. The fundamental priority is **an autonomous city AND a taxi whose route choices visibly matter**.
