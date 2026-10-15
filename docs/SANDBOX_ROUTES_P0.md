# Routes P0 — Connected Choices and Actual Player-Taxi Movement

> **Status:** player-facing vertical slice built for [#27](https://github.com/MohamedXIV/outsider-driver-2d/issues/27), companion to S3 P0 [#26](https://github.com/MohamedXIV/outsider-driver-2d/issues/26); next is [#28](https://github.com/MohamedXIV/outsider-driver-2d/issues/28) (rerouting and rider responses). This is still temporary schematic UI and does **not** prove final driving camera, real traffic or human gameplay quality.

## What is real

- A selected systemic offer provides origin/destination. `SandboxRoads.path(from,to,via)` computes deterministic connected graph paths with bounded BFS across the **existing authored graph**; no bespoke AStar is necessary for its five districts. Invalid or cyclic detours are rejected.
- **Map-pin default** keeps ordinary short trips simple. A player can choose an alternate **via district** with a touch-friendly OptionButton or click the actual corresponding district marker on the schematic city. The same waypoint is honored when accepting through **direct UI or S1 Ink dialogue**. No waypoint selection mid-trip in P0.
- Demo Docks → Shelter offers two **physically valid** paths: **Docks → Market → Shelter** (20 simulated minutes, 0 road-cost, posted Market–Shelter checkpoint adds 1 exposure) versus **Docks → Depot → Shelter** (30 simulated minutes, 2-credit road expense, zero checkpoint exposure). Actual costs follow their traversed edges, not generic risk dice. Checkpoint-risk previews require known GPS graph information; uninformed drivers are not handed hidden facts.
- `SandboxWorld` exclusively owns `route_nodes`, `route_segment`, `route_edge_elapsed`, `remaining_minutes` derived from the route, fare and risk. On each authoritative 10-minute world step, the taxi advances along its current connected road segment; only when the segment finishes can it move to the next node and commit a `route_segment_completed` event. Arrival settles the fare **exactly once**. A fare cannot be started without sufficient money for the selected route's road expense.
- `SandboxCityView` interpolates between the world-owned endpoints using only elapsed **presentation frame fraction** between authoritative world ticks; it does **not** secretly progress or settle the trip. Screenshots show the cab physically **halfway along Depot → Shelter** while the world knows it has 10 minutes remaining.
- Existing autonomous NPC routines and trips from S3 continue during player travel, and all existing S1 dialogue decisions remain world-validated.
- Save envelope v5 / world schema v4 intentionally **do not** migrate experimental saves. Route legs, selected edges, progress and event provenance are validated on reload; forged disconnected or inconsistent paths are refused.

## Explicit Reuse / Replace / Retire

**Reuse:** SandboxWorld world authority/event ledger, S1 Ink bridge, existing graph, once-only fare, S2 device knowledge and S3 autonomous population, P0 camera/projection expertise.

**Replace:** player fare's formerly authoritative `remaining_minutes`-only completion with segment progress + route selection. Existing `remaining_minutes` remains an accurately derived **display** amount, not a second independent completion mechanism.

**Retire:** no historical P0–P2 clinic test fixture removed; that journey is not new gameplay. No obsolete partial-translator mechanism extended.

**Deferred:** mid-trip rerouting at junctions (#28), NPC-consent/detour negotiation (#28), player **reposition** animation (still a temporary atomic graph move), full road terrain/elevation, traffic, police AI, hardware/performance tuning, final visual presentation, Windows **runtime** and human UX playtest. The small demo's 1-point checkpoint hazard and 2-credit toll are **prototype edge coefficients**, not city-wide economic balance.

## Verification

- `tests/test_sandbox_routes.gd` confirms two genuine paths with distinct time/cost/risk, invalid waypoint rejection, real 10m and 20m progress, persisted **mid-edge** route, rejected forged saves and one settlement.
- `tests/test_sandbox_routes_scene.gd` drives actual Godot UI and captures map-selected preview, taxi between waypoints, resumed route and arrival.
- `tests/web_sandbox_routes.cjs` clicks the **real Depot map pin** in Chromium, accepts an actual generated offer, waits to the midpoint, saves/reloads and finishes a single fare, while S0–S3 Web regressions also execute.
- At implementation, `Godot 4.7.2` official compiler/import, Linux run, Windows **export** and real exported Chromium walk-through are the acceptance. An exported Windows binary is **not** Windows gameplay evidence.

**Caveat:** S2's binary language-module redesign is a later task [#32](https://github.com/MohamedXIV/outsider-driver-2d/issues/32); no reason to replace that working experimental proof during routing.
