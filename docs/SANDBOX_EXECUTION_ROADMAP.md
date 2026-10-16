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
| S3 P0 — independent work/rest and alternative trips | **Merged** [PR #37](https://github.com/MohamedXIV/outsider-driver-2d/pull/37), [proof](SANDBOX_S3_P0.md) |
| Routes P0–P1 — selected paths, actual taxi motion and next-junction rerouting | **Merged** [PR #39](https://github.com/MohamedXIV/outsider-driver-2d/pull/39) / [#40](https://github.com/MohamedXIV/outsider-driver-2d/pull/40), [proof](SANDBOX_ROUTES_P1.md) |
| S3 P1 — source-backed NPC-to-NPC aid and co-present knowledge | **Merged** [PR #41](https://github.com/MohamedXIV/outsider-driver-2d/pull/41), [proof](SANDBOX_S3_P1.md) |
| S3 P2 — remembered player encounters and returning-passenger contextual Ink | **Verified code** [PR #42](https://github.com/MohamedXIV/outsider-driver-2d/pull/42), [green CI](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38817277932); [proof](SANDBOX_S3_P2.md) |

**Critical limitations now:** the default scene remains a **schematic debug sandbox**, but the taxi travels real selectable segments and supports junction rerouting. NPC autonomous routines, peer knowledge, returning-driver memory and **one real voluntary off-duty meeting** have native/Web technical proof. This is not a fully detailed city or a dating sim. The implemented S2 **partial** translation remains experimental and will be replaced by the approved binary language-module design at #32; **Basic Common default loadout remains pending explicit approval**. Windows runtime, visual quality and human gameplay pacing are unverified.

## Execution waves (small playable slices, not huge phases)

| Priority | Task | Dependency | Player-visible exit proof |
|---|---|---|---|
| **DONE — A** | **[#26 S3 P0: NPC autonomous routines & travel alternatives](https://github.com/MohamedXIV/outsider-driver-2d/issues/26)** | **PASS** [PR #37](https://github.com/MohamedXIV/outsider-driver-2d/pull/37) | Work/rest and timed alternatives demonstrably evolve for 24h without the player; native/Linux/Web proof [#38767914997](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38767914997) |
| **DONE — B1** | [#27 Routes P0: path selection + visible semi-auto taxi](https://github.com/MohamedXIV/outsider-driver-2d/issues/27) | #26 **complete** | Two different true connected paths, map/waypoint selection and actual segment-by-segment taxi movement |
| **B2** | [#28 Routes P1: junction reroute + rider consequences](https://github.com/MohamedXIV/outsider-driver-2d/issues/28) | #27 | **Implemented/verified (PR #40, CI #38809189586):** queued connected suffix at next junction, NPC accept/refuse changes trust, live Linux+Chromium and save/replay |
| **C1** | [#29 S3 P1: NPC↔NPC contacts and local knowledge](https://github.com/MohamedXIV/outsider-driver-2d/issues/29) | #26 | **Verified technical slice (PR #41, CI #38811261745):** grounded co-presence, source-backed knowledge, modest peer aid and native/Web replay |
| **DONE — C2** | [#30 S3 P2: recognition, memories and cover identity](https://github.com/MohamedXIV/outsider-driver-2d/issues/30) | #26, #29 | **CI PASS #38817277932, PR #42:** a repeat genuine offer with sourced memory changes shared Ink; legal/human identity remains unknown |
| **DONE — C3** | [#31 Relationships P0: optional off-duty meeting](https://github.com/MohamedXIV/outsider-driver-2d/issues/31) | #30 | **Merged PR #43, CI #38823128499 PASS:** real repeat fares unlock voluntary time/place invite; player attends/declines/misses; native + Chromium Ink meeting and mid-event Save/Load |
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


## Verified C3 closure — October 16, 2026

[Relationships P0 PR #43](https://github.com/MohamedXIV/outsider-driver-2d/pull/43) merged at `4bcbb354f9a00eeb9cd4c9219e1dcd2b617f8314`. [Godot 4.7.2 run #38823128499](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38823128499) **PASS** on gameplay head `2fb75b0dcc54d773937d37b1be65f7b6ff01bf43`; follow-up was docs only. Genuine repeat taxi passenger, source-backed invitation, accepted/declined/late/missed appointment, bounded off-duty kiosk scene with contextual Ink, frozen active-dialogue time and mid-meeting Save/Load. Native Linux scene and exported Chromium real interactions PASS. Windows was exported, **not** executed; human playtest/feel remains unverified. [Detailed acceptance](SANDBOX_RELATIONSHIPS_P0.md).

**NEXT — #32:** three shared languages, binary modules and real physical-market install/purchase are approved design direction, but the Basic Common preinstalled loadout and exact starting bonus (GPS / secondary module / Radio) are **recommended, NOT ratified**. The #32 implementation must explicitly settle how the current S2 starter is superseded before rewriting starter/UI/tests; no silent assumption or parallel temporary translator. #33 depends on #32, #34 is optional and later.
