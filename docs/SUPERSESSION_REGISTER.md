# Outsider Driver — Current vs Superseded Contracts

> **Active supersession register, October 15, 2026.** Prevents implementation workers from repeating an abandoned prototype, preserving obsolete tests as product requirements, or independently recreating an existing system. This is a guide to conflict resolution based on the actual current repository; it is **not** approval for any still-pending design choice.
>
> See [Active Sandbox Roadmap](SANDBOX_EXECUTION_ROADMAP.md), [Living City design synthesis](LIVING_CITY_DESIGN_CONCLUSIONS.md), [Engineering Rules](ENGINEERING_RULES.md) and [Epic #15](https://github.com/MohamedXIV/outsider-driver-2d/issues/15).

## Precedence: what wins when two sources disagree

1. **Latest explicit user-approved direction/override**, including corrections to earlier design, wins as product intent. Preserve its date and scope in issue/docs; do not quietly reintroduce the older alternative.
2. **Current agreed contract** in [Sandbox Game DNA](SANDBOX_GAME_DNA.md), [Living City design synthesis](LIVING_CITY_DESIGN_CONCLUSIONS.md) and [active execution roadmap](SANDBOX_EXECUTION_ROADMAP.md), with their stated **approved / recommended / pending** labels. More specific new approved contracts override general historical language.
3. **Live current `main` and its tests** describe **what exists**, not necessarily **what should continue to exist**. Check open PRs and issues before writing; don't duplicate work.
4. **Archived P0–P2 plans, fixture docs and formerly green tests** establish prior technical evidence only. They **cannot override** newer product decisions.

A conflict is resolved by choosing the authoritative successor, marking the old acceptance condition obsolete, and upgrading/retiring only the code/tests actually impacted. **Do not break the running S0–S2 slice prematurely** as preparation for an unrelated task; replace a subsystem **when its successor slice is being implemented and verified**. Past green checks remain historically true; a successor must pass its **new** acceptance.

## Concrete register — what to reuse, replace or retire

| Former behavior or claim | Reality in current main | New direction / classification | Implementation rule |
|---|---|---|---|
| **Five district-nodes, straight roads, equal ten-minute segments, instant empty relocation and dashboard default** | Historical pre-reboot proof; replaced on `feat/playability-city-integration` | **IMPLEMENTED / Ready for human check #49–52**: six regions / 27 metric Curve2D road nodes, physical taxi/NPC travel and default contextual Player Mode | [Current build, contracts and evidence](CITY_PLAYTEST.md). One shared world; ten-minute population routines remain, clock unchanged, one-minute movement resolution; v12 saves. Old five-stop Web coordinate fixtures are historical, current VM/native/Web gate replaces them |
| **Authored first clinic passenger / P1–P2 fixed ride and 18-credit/6-credit repeat** | Old `scenes/main.tscn` and archived tests retained | **RETIRED as gameplay**; **REUSE as narrowly scoped technical regression** for Ink, camera/garage/engine when relevant | Never build the city, economy or encounter roadmap by adding more scripted clinic passengers. Historical costs are fixture values, not balancing targets |
| **Monolithic authoritative `GameSession` language in old rules** | `SandboxWorld` owns current live world snapshot, event ledger, money/offer outcomes; `GameSession` belongs to old ride fixture | **REPLACE outdated docs**, **REUSE valid event/command logic** | Extend cohesive current SandboxWorld/domain services; do not create a second live GameSession authority or parallel simulation ledger |
| **S2 one-time GPS / Translator / Radio starter** | Historical PR #21 evidence, **superseded in main by PR #45** | **APPROVED and IMPLEMENTED #32**: Basic Common translator preloaded + choose GPS / installed Local-language module / Radio bonus | Old starter expectations retired; no parallel mutually exclusive Translator selection. [#32 proof](SANDBOX_LANGUAGES_P0.md) |
| **S2 per-phrase partial Translator, learned `lexicon:local:route-marker`** | Historical S2 scanner and previous CI assertions; **retired in #32** | **IMPLEMENTED #32**: one whole-language installed/absent module per language, no incremental word progress | Knowledge-ledger event provenance preserved; old route-marker API and test assertions removed; domain/native/Chromium replacement acceptance PASS |
| **S1 binary `trade` / `local` NPC language and handwritten alien fallback** | Historical two-language proof superseded by #32's Trade/Common, Local and Cant | **#32 done for three shared languages**; **#33 done for stable semantic glyph scripts and EN/Arabic dialogue presentation** | Replace romanized Cant/Local text without changing Ink consequences; verified OFL fonts, RTL, skip/reduced motion and no untranslated English clue [#33](SANDBOX_LANGUAGES_P1.md) |
| **'One species = one language = one faction' simplification** | Not the new approved society model | **REJECTED** as a production assumption | Keep species/language/culture/community/faction separate in small practical data; groups can share history/language; affinity and rivalry may coexist |
| **Taxi settles using district BFS hop-count and trip countdown** | Current five-district graph + `SandboxWorld.remaining_minutes`; **no current selectable per-edge driving** | **REPLACE journey mechanics at #27–#28** with route choice, actual connected segment traversal, optional waypoints and mid-trip junction reroute | **REUSE** graph connectivity/elevation ideas, validation and once-only settlement, but do not present old timer as final driving gameplay or create visual-only path pretending to drive |
| **P0 isometric taxi/bridge/camera proof** | Archived scene/evidence exists; default sandbox UI is schematic | **REUSE useful camera/road art techniques**, not the authored ride schedule | Integrate into actual sandbox travel when useful; do not restart engine choice or build a second city viewer/controller |
| **Every NPC deeply scripted / unique NPC cast required for memory or romance** | S0 has 9 simple persistable residents and scalar trust, not meaningful cross-meeting memory | **REJECT deep scripts for every citizen**; **FUTURE** graduated Background → Persistent → Significant importance with salient memory | #26–#30 develop one NPC substrate; later #31 may allow optional out-of-taxi bonds, not compulsory romance or a separate character engine |
| **Any returning NPC knows player is human/illegal** | Not yet implemented | **REJECT global unmask assumption**; separate recognition, relationship and actual identity/legal facts | NPC memory needs witnessed sources; apparent identity, cover name and legal residency are not one boolean; concealment mechanics still an **OPEN** decision |
| **Translator automatically to English, or hover reveals the objectively right answer** | Neither is valid product rule | **REJECT**. Translation targets chosen **human UI locale**; AR shows **already known facts only** | **#33** EN/Arabic Ink verified; optional **#34** eyewear reads only actual PlayerKnowledge/GPS/arrival history and explicitly heard sourced rumor, with unknown speech excluded. [AR proof](SANDBOX_AR_P0.md) |
| **No Windows/game-feel testing required if export works** | Native Linux/Web automated runtime verified for S0–S2; Windows is **export only** | **REJECT inflated acceptance** | Distinguish code/unit tests, visible Linux, Chromium export, Windows export, actual Windows runtime, and human UX/playtest; never mark unperformed evidence PASS |

## Non-goals and pending decisions (do not silently assume approved)

- **Basic Common Translator as free default**: **ratified and shipped by #32**; the single starter bonus is GPS / installed Local-language cartridge / Radio. #33 adds bounded semantic alien glyphs and player-selected EN/Arabic Ink reveal, without artificial grammar or per-word progression. [Verified D2](SANDBOX_LANGUAGES_P1.md).
- **How the player's human appearance is concealed**, practical ID risk, specific named cultures/factions, final in-world culture/language naming and custom script aesthetics, route-preview/reroute controls, and which significant NPCs are handcrafted: intentionally undecided until relevant slice.
- **Light romance** is possible and optional, not required on every persistent NPC; off-duty meeting is a small possible follow-on, not a license to build a dating sim now.
- **AR glasses** were OPTIONAL and are now shipped in bounded form by [#34](SANDBOX_AR_P0.md). Still no general-purpose AI agents, omniscient world knowledge, huge grammar engine, custom Google Maps, hand-driven open-world traffic or unwarranted Rust/C++/performance projects.

## Mandatory pre-implementation checklist

For **every** issue/PR (including agent handoffs):

1. **Refresh reality:** fetch current `main`, active PRs, latest issue body, relevant code and tests through connected GitHub. Verify which work is already merged or being built. Never trust a stale SHA/handoff.
2. **Decide authority:** identify current approved spec, newer overrides, old proof-only implementation, and any pending choices. If contract conflicts, record the conflict in the issue/PR **before implementing**.
3. **Scope affected systems:** a short **Reuse / Replace / Retire** table with exact source paths and tests (or 'none' for a docs-only task). Preserve useful validated engine contracts; don't build duplicate sources of truth or keep old behavior around as a second mode without approval.
4. **Agree new acceptance:** when changing behavior, explicitly mark old assertions as **historical/obsolete** and add replacement deterministic + visible native/Web acceptance. No green test is a product veto against an approved newer design.
5. **Implement only dependency-ready gameplay:** a small bounded playable slice with meaningful consequences. Do not prematurely refactor unrelated S2 language code in #26 or build routes in #26 just because #27 needs them next.
6. **Close honestly:** record exact proof type (unit, native Linux, Chromium, Windows export vs run, human feel), versioned outcomes, any remaining superseded stubs, and the next dependency-ready issue.

### Short PR preflight format

~~~text
Authority: <newest approved decision / link; pending choices>
Live baseline: <main SHA; overlapping PRs/issues>
Reuse: <exact existing contracts and tests>
Replace: <obsolete behavior, path(s), and replacement tests>
Retire: <historical-only behavior and assertions>
Not implemented: <features explicitly deferred>
Validation: <actual evidence, including gaps>
~~~

**Rule of thumb:** Do not *polish* obsolete gameplay when the next milestone will *replace* it; also do not break a currently working proof until the replacement is runnable. A smaller correct successor beats maintaining two inconsistent designs.
