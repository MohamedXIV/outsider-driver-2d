# Refactor plan: architecture hardening

> **Canonical tracking:** Epic #89 on GitHub. This file is the versioned copy of the Epic body so the plan travels with the code. If they disagree, the Epic issue wins; update this file in the same PR that changes the plan.
>
> Written 2026-10-24 against stack head `feat/r05-playtest-reliability-86` @ `581d283` (see *Integration baseline*). Numbers in *Evidence* will drift as the stack moves; re-measure before relying on them.

# Why this Epic exists

The Godot project is **healthy at its core and structurally overgrown**. The simulation is deterministic, engine-independent and versioned (a real strength to preserve), but the presentation layer, persistence, tests, docs and CI have grown faster than their structure. This Epic restructures the project **incrementally, without a rewrite and without changing gameplay**, so that future work (and future agents) can add features safely. It also gives performance work a measured basis instead of guesses (see #86).

This is **not** a decision to leave Godot. Engine choice was evaluated separately; the conclusion was to stay on Godot 4.7.2 and fix structure and measurement first.

# Evidence (read this before trusting any number)

**Measured by reading code / running scripts (2026-10-24):**
- `main` = `05ea3fd`. Live work is a stack of 15 Draft PRs; stack head `feat/r05-playtest-reliability-86` @ `581d283` is **243 commits ahead, 300 files changed**. All structural claims below are about the **stack head** unless marked `main`.
- God scene script: `scripts/sandbox/sandbox_main.gd` **1482 lines / 69 funcs** (main: 1058 / 50). `sandbox_world.gd` **1066 / 46** (main: 808 / 40). `sandbox_player_ui.gd` 752 / 32. `scripts/sandbox/` holds 55 files in one flat folder.
- `restore_snapshot` was a single **270-line** function on `main` returning only `false`.
- Entities (residents, offers, events, vehicle state...) are untyped `Dictionary`s with string keys (60 `Dictionary` mentions in `sandbox_world.gd` on `main`).
- Content/tuning constants are literals in code (languages, purposes, prices, fare formula...).
- ~18 scans of the append-only `events` ledger across 15 files at the stack head (list in #95).
- 115 `tests/test_*.gd`, 19 Playwright `.cjs` suites, 233 files in `docs/`, 15 workflows.
- `sandbox_main.gd` reaches into ~40 distinct world fields/methods directly (`_world.active_offer_id` 19×, `player_district` 15×, ...), and `_render()` is called from ~40 sites on `main`.
- Testing pitfall observed on Godot 4.7.2: a failed `assert` under `--script` does **not** exit; the process runs until the gate's 90 s timeout.
- Strength: no `randi/randf/RandomNumberGenerator` in the domain; ordering derives from stable ids and the seed; `SCHEMA_VERSION`ed snapshot; stable ids; event provenance.

**Measured, but narrow:** native headless Godot on `main` with 2290 events: `_render()` 1171 µs → 292 µs with ledger indexes (PR #88); `advance(10)` ~250 µs unchanged. **Not measured:** WebAssembly, real rendering, the stack head, Windows. These numbers show a real but small cost; they do **not** explain #86's progressive FPS loss by themselves.

**Hypothesis, unverified:** frame cost grows with the ledger because some scans sit on per-frame paths. #94 exists to confirm or falsify this with data.

# Principles

1. **Behaviour-preserving first.** Prove it with golden snapshot hashes (#91).
2. **Measure, then optimise.** No performance claim without before/after numbers (#94).
3. **Domain is engine-independent and deterministic.** No `Node`, `JavaScriptBridge`, `OS`, `Time`, or RNG in domain code. Enforced mechanically (#93).
4. **Typed inside, dictionaries at the boundary.** Persistence converts; gameplay code uses classes (#98).
5. **Definitions are data, state is saved.** Content is JSON loaded and validated at startup (#103).
6. **Presentation never owns truth.** It talks to one facade (#105), receives change signals (#104), and can rebuild entirely from state.
7. **Call down, signal up.** Panels get dependencies through `setup(session)`; no autoload manager singletons, no service locator.
8. **Small PRs, one concern each.** Mechanical moves (folders) happen last, alone (#111).
9. **Ledger is provenance: never prune it; index it** (#95).

# Target architecture (proposal)

```
scripts/
  domain/        model/ systems/ commands/ persistence/ content/ world/   (no Node, no RNG, no Time)
  narrative/     Ink bridge + conversation (typed boundary to the domain)
  presentation/  panels/ map/ vehicles/ pedestrians/ ui/                  (reads read-models, submits commands)
  platform/      web_bridge, telemetry (the ONLY JavaScriptBridge users)
  app/           bootstrap (composition root), SandboxSession (facade)
  debug/         PerfProbe, dev tools
content/         *.json definitions (languages, districts/roads, market, tuning...)
tests/           unit/ integration/ native/ web/ perf/ support/ golden/
docs/            README index, design/, adr/, evidence/, archive/
```
Dependency direction: `presentation → app/session → domain`; `platform` is called by presentation/app only; **domain imports nothing above it**.

# Integration baseline  ← OWNER MUST FILL (see #90)

> **Current status: UNDECIDED.** Until filled, only issues labelled `safe-before-gate` may start, as **Draft** PRs against `feat/r05-playtest-reliability-86` (@ `581d283`, 2026-10-24).
>
> Baseline branch: `_____`  ·  SHA: `_____`  ·  decided on: `_____`

# Work breakdown (check items off as PRs merge)

### Phase 0 · Gate
- [ ] #90 **R00** Decide and land the integration baseline (main is 243 commits behind the live R05 stack) · size S · depends on: none · needs owner decision

### Phase 1 · Safety net and measurement
- [ ] #91 **R01** Golden snapshot regression harness (safety net for every refactor) · size S · depends on: none · safe before gate
- [ ] #92 **R02** Fast-failing test assertions and shared test helper · size S · depends on: none · safe before gate
- [ ] #93 **R03** Architecture guard tests (static layer rules with a ratcheting allowlist) · size S · depends on: #92 · safe before gate
- [ ] #94 **R04** Frame-cost profiling harness: measure before optimising (relates to #86) · size M · depends on: none · safe before gate
- [ ] #95 **R05** Index the event ledger and remove full-ledger scans · size M · depends on: #91, #94 · safe before gate
- [ ] #96 **R06** Publish the Web test dataset only under automation or ?telemetry · size S · depends on: #94 · safe before gate

### Phase 2 · Domain restructure
- [ ] #97 **R07** Retire the frozen P0-P2 prototype code after a supersession audit · size M · depends on: #90, #91 · needs owner decision
- [ ] #98 **R08** Typed domain models foundation: WorldEvent, event-kind constants, Result type · size M · depends on: #90, #91, #92, #93
- [ ] #99 **R09** Typed Resident, Offer and Meeting models · size L · depends on: #98
- [ ] #100 **R10** Typed motion/vehicle/pedestrian state (vehicle_execution, junctions, crossings, parking, departures) · size L · depends on: #99
- [ ] #101 **R11** Extract persistence: snapshot/restore into a dedicated module with per-section validators and error reasons · size L · depends on: #90, #91, #95
- [ ] #102 **R12** Split SandboxWorld: state container + command handlers + ordered tick pipeline (no circular static coupling) · size L · depends on: #101, #99
- [ ] #103 **R13** Data-driven content: definitions in JSON with a loader and validator · size M · depends on: #90, #91

### Phase 3 · Presentation restructure
- [ ] #104 **R14** Domain change notifications (signals) to replace the global _render() · size M · depends on: #102
- [ ] #105 **R15** SandboxSession facade: the only entry point presentation uses (commands + read models) · size M · depends on: #102, #104
- [ ] #106 **R16** Decompose sandbox_main.gd into focused panels (1482 lines / 69 funcs on the stack head) · size L · depends on: #105, #90
- [ ] #107 **R17** Decompose sandbox_player_ui.gd (752 lines) and city/map views along the same panel rules · size M · depends on: #106
- [ ] #108 **R18** Platform layer: single home for JavaScriptBridge, Web telemetry and hitbox publishing · size M · depends on: #96, #106

### Phase 4 · Hygiene (docs, CI, folders)
- [ ] #109 **R19** Documentation consolidation: index, taxonomy, ADRs, accurate AGENTS.md (233 doc files on the stack head) · size M · depends on: #90
- [ ] #110 **R20** Consolidate GitHub Actions (15 per-feature workflows) into a small gated set · size M · depends on: #90, #92
- [ ] #111 **R21** Folder structure migration (flat scripts/sandbox with 55 files → layered tree) · size M · depends on: #97, #106, #107, #108, #102, #101 · needs owner decision

**Suggested order inside a phase follows the dependency lists.** Phase 1 issues are independent of the stack's churn and give every later issue its safety net; start there.

# Rules for every refactor PR

1. **No behaviour change.** Golden hashes (#91) identical before/after. If an intentional change is needed, regenerate goldens in a **separate commit** and explain why.
2. **Supersession preflight** (rule 11 in `docs/ENGINEERING_RULES.md`): check `docs/SUPERSESSION_REGISTER.md`, live branches/PRs/issues, and relevant tests; classify touched code Reuse / Replace / Retire; no two competing sources of truth.
3. **Protected surfaces** (from #82): `sandbox_city_data.gd`, `sandbox_directed_lanes.gd`, `tests/web_city_routes.cjs` (#51/#81); `sandbox_player_ui.gd`, player-guidance assets, `web_city_playability.cjs` (#50/#77). Do not edit them until those PRs have landed, unless the issue says so.
4. **Draft PRs only**, small, one concern; do not merge, mark ready, close issues, publish releases (owner does).
5. **Godot 4.7.2 exactly.** `run_city_gate.py` refuses other versions and requires a clean tracked tree.
6. **Report accurately:** list exactly which checks ran (and on which commit), which did not, and why. No Windows/human-feel claims from CI.
7. **Evidence in the PR:** before/after numbers for perf claims; screenshots for UI moves; the failing-then-passing output for new tests.
8. **Avoid GitHub Actions minutes:** prefer local/focused runs; one exact-head full run when worth it.
9. **Don't over-engineer:** no abstractions without an immediate caller; no file per ten lines (AGENTS.md).
10. **Update docs in the same PR** when a contract or location changes.

# Verification toolkit

```bash
# Godot 4.7.2 (exact version required by the gate)
curl -fsSL https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip -o godot.zip
unzip -q godot.zip && chmod +x Godot_v4.7.2-stable_linux.x86_64
export GODOT_BIN="$PWD/Godot_v4.7.2-stable_linux.x86_64"

$GODOT_BIN --headless --path . --import                       # import (first run, after adding scripts)
python3 tests/run_city_gate.py                                # domain + adapters (headless)
python3 tests/run_city_gate.py --native                       # native/scene tests (needs display or xvfb; NOT --headless)
$GODOT_BIN --headless --path . --script res://tests/test_X.gd # one test
```
Pitfalls seen in practice:
- A failing `assert` in a `--script` test **hangs** until a timeout instead of exiting (fixed by #92). Always run tests with a `timeout`.
- In one headless cloud sandbox, scene (`*_scene`) tests run with `--headless` hung until timeout **even on the unmodified base**; the gate runs native tests without `--headless`. Treat scene tests as unverified unless you ran them with a display/xvfb.
- Godot import generates untracked `*.uid` / `*.import` files. Do not commit them unless the repo already tracks them (`git ls-files | grep -c '\.uid$'`); the gate needs a clean tracked tree.
- Shallow clones: `git fetch origin <branch>` before diffing; push from a freshly fetched base (a stale shallow base re-uploads the tree).
- GitHub GraphQL is blocked in agent sessions: use `gh api` REST (`gh pr create` fails).
- Refactors can change dictionary key insertion order; hash golden data with sorted keys: `JSON.stringify(x, "", true, true)`.

# Definition of done (proposed targets; adjust with evidence)

- Golden hashes exist and have not changed except in explicitly justified commits.
- No file in `presentation/` > 500 lines; `sandbox_main.gd` < 200; `SandboxWorld` < 300; functions < 80 lines (ratcheted by #93).
- Zero full-ledger scans outside the index/persistence code; before/after numbers recorded in `docs/PERF_BASELINE.md`.
- `grep JavaScriptBridge scripts` → only `scripts/platform/`; no RNG/Node/OS in `domain/`.
- Presentation references no `SandboxWorld`; every disabled control can show its reason.
- Content tunables live in `content/*.json` with a validator.
- ≤ 5 workflows; `docs/README.md` indexes every doc; `AGENTS.md` matches the structure.
- Retired prototype code removed; tag preserved.

# Decisions owner must make (agents must not decide)

| # | Decision | Where |
|---|---|---|
| 1 | Integration strategy / baseline branch | #90 |
| 2 | Retire the frozen P0–P2 prototype? | #97 |
| 3 | In-house `Check` helper vs adopting GdUnit4/GUT | #92 |
| 4 | Content format (JSON proposed) and location | #103 |
| 5 | Target folder tree and freeze window | #111 |

# Non-goals

- Rewriting in another engine, adding C++/GDExtension, Inochi2D/Live2D, or new gameplay features.
- Pruning the event ledger, or inventing save-migration machinery ("no lock-in to old saves").
- Replacing or re-implementing the native pedestrian/traffic systems being fixed under #82/#86.
- Final art/UI polish (tracked under #48/#50).

# Relationship to existing work

- Parent design contract: #15 (Sandbox foundation). Active product priority: #48 (Playability Reboot), #82 (Living Streets), **#86 (playtest blockers; takes priority over any refactor PR that would touch the same files)**.
- Prior perf work: PR #88 (`perf/event-indexes`, stale base) is superseded by #95 and #96.
- Plan document: `docs/REFACTOR_PLAN.md` (same content, versioned with the code).

# How to pick up an issue (humans and agents)

1. Open the Epic, read *Integration baseline* and *Rules for every refactor PR*.
2. Pick an unchecked issue whose dependencies are done (or that is `safe-before-gate`).
3. Comment "taking #N" to avoid duplicate work; create a branch from the baseline; open a **Draft** PR that links the issue.
4. Follow the issue's tasks, acceptance and verification literally; if reality differs from the issue's evidence (the stack moves fast), update the issue with what you found.
5. Stop when acceptance is met. Do not widen scope.


# Appendix: issue index

| Ref | Issue | Title | Size | Depends on |
|---|---|---|---|---|
| R00 | #90 | [Gate] Decide and land the integration baseline (main is 243 commits behind the live R05 stack) | S | none |
| R01 | #91 | Golden snapshot regression harness (safety net for every refactor) | S | none |
| R02 | #92 | Fast-failing test assertions and shared test helper | S | none |
| R03 | #93 | Architecture guard tests (static layer rules with a ratcheting allowlist) | S | #92 |
| R04 | #94 | Frame-cost profiling harness: measure before optimising (relates to #86) | M | none |
| R05 | #95 | Index the event ledger and remove full-ledger scans | M | #91, #94 |
| R06 | #96 | Publish the Web test dataset only under automation or ?telemetry | S | #94 |
| R07 | #97 | Retire the frozen P0-P2 prototype code after a supersession audit | M | #90, #91 |
| R08 | #98 | Typed domain models foundation: WorldEvent, event-kind constants, Result type | M | #90, #91, #92, #93 |
| R09 | #99 | Typed Resident, Offer and Meeting models | L | #98 |
| R10 | #100 | Typed motion/vehicle/pedestrian state (vehicle_execution, junctions, crossings, parking, departures) | L | #99 |
| R11 | #101 | Extract persistence: snapshot/restore into a dedicated module with per-section validators and error reasons | L | #90, #91, #95 |
| R12 | #102 | Split SandboxWorld: state container + command handlers + ordered tick pipeline (no circular static coupling) | L | #101, #99 |
| R13 | #103 | Data-driven content: definitions in JSON with a loader and validator | M | #90, #91 |
| R14 | #104 | Domain change notifications (signals) to replace the global _render() | M | #102 |
| R15 | #105 | SandboxSession facade: the only entry point presentation uses (commands + read models) | M | #102, #104 |
| R16 | #106 | Decompose sandbox_main.gd into focused panels (1482 lines / 69 funcs on the stack head) | L | #105, #90 |
| R17 | #107 | Decompose sandbox_player_ui.gd (752 lines) and city/map views along the same panel rules | M | #106 |
| R18 | #108 | Platform layer: single home for JavaScriptBridge, Web telemetry and hitbox publishing | M | #96, #106 |
| R19 | #109 | Documentation consolidation: index, taxonomy, ADRs, accurate AGENTS.md (233 doc files on the stack head) | M | #90 |
| R20 | #110 | Consolidate GitHub Actions (15 per-feature workflows) into a small gated set | M | #90, #92 |
| R21 | #111 | Folder structure migration (flat scripts/sandbox with 55 files → layered tree) | M | #97, #106, #107, #108, #102, #101 |
