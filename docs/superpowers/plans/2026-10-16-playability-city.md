# Playability City Implementation Plan

> For agentic workers: use superpowers:executing-plans inline, task by task. The user explicitly chose sole implementation ownership and autonomous checkpoints.

**Goal:** One playable integrated alien-city taxi build for human evaluation.
**Architecture:** Retain authoritative SandboxWorld and cohesive domain services. Metric road geometry drives movement and time; separate Player UI presents shared commands and state.
**Tech Stack:** Godot 4.7.2, typed GDScript, Compatibility 2D, InkJS 2.4.0, Playwright.
**Spec:** docs/superpowers/specs/2026-10-16-playability-city-design.md

## Global Constraints
- True 2D; six-region charter-port working geography; no old renderer migration.
- Preserve source-backed knowledge, autonomous residents, actual fares/economy, meetings and equipment.
- One world; Player Mode default; Debug Mode reversible; no fake clock slowdown.
- No human acceptance claim; Windows export is distinct from runtime.

## Review Focus
- Switching views during Ink/travel never changes world truth.
- Arrival while reading leaves choices accessible; charges/settlement cannot repeat.
- Wrong-layer road crossings cannot turn; saved/rerouted geometry stays continuous.
- Small layouts/Arabic/expanded panels keep actions reachable.
- Unfunded or inaccessible routes fail without partial mutation.

### Task 1: Recover design and create checkpoint
- [x] Audit live issues/PRs, source design, canonical/superseded contracts.
- [x] Preserve attributed reference docs/map, record design and execution decisions.
- [ ] Commit planning checkpoint.

### Task 2: Authoritative city graph and physical travel
Files: sandbox_city_data.gd (new authored regions/stops/edges), sandbox_roads.gd (curve/distance/path API); sandbox_world.gd, population/autonomy/dispatch/save; tests/test_city.gd.
Interfaces: SandboxRoads.path(a,b,via), edge_minutes/expense/exposure, sample_edge(a,b,fraction), position_on_path, district_for, location_name; SandboxWorld.is_travelling/player_position.
- [ ] Write tests for six regions, connected metric network, curved length, varied trips, grade separation, legitimate ramp and invalid turns; observe failure.
- [ ] Implement weighted topology/geometry and world/NPC movement, save schema and validation.
- [ ] Verify graph, journey/reroute/replay/once-only fare and canonical domain regression; update obsolete geometry fixtures deliberately.
- [ ] Commit checkpoint.

### Task 3: Player/Debug and cinematic road presentation
Files: sandbox_city_view.gd, sandbox_player_ui.gd, sandbox_passenger_view.gd, sandbox_map_view.gd, sandbox_main.gd; scene/UI tests.
Interfaces: PlayerUI.bind(controller), sync(), toggle_debug(); city reads world and presentation-only fraction.
- [ ] Add tests for default mode, unchanged world on toggle, real accessible controls and layout bounds; observe failure.
- [ ] Implement close-follow curved-road city with decks/supports/ramps/depth, district facades and passenger presence.
- [ ] Implement responsive themed contextual Player UI; preserve debug diagnostics and shared commands.
- [ ] Verify native runtime/images and Player interactions; commit checkpoint.

### Task 4: Passenger dialogue, integration and balance
Files: SandboxConversation, language presentation, new travel Ink source+JSON, main, domain/scene/Web tests.
Interfaces: existing open/choose/snapshot/restore now supports travel context; world engagement protection.
- [ ] Test inride conversation, world ticks during dialogue, safe arrival and mid-dialogue reload; observe failure.
- [ ] Implement travel Ink, truthful localized phrases, quiet/end choices and passenger portrait states; retain service/AR/social access.
- [ ] Run deterministic and real native/Web fare, market, social, save/reload, route and layout checks.
- [ ] Commit checkpoint.

### Task 5: Review and delivery
- [ ] Review complete diff, fix important findings with regression tests, run final VM gate.
- [ ] Package Linux/Windows/Web builds and screenshots, update feedback/roadmap/issues with exact evidence.
- [ ] Commit, push integration branch, open PR. Merge only with authorization and safe verification.
- [ ] Leave precise continuation instructions if externally blocked; distinguish human playtest from technical completion.
