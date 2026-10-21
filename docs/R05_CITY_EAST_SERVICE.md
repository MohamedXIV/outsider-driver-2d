# #51 — Outer Margin / Upper Terraces service access (bounded city-depth slice)

## Why
The R05 city already has six regions, ten genuine pickup/service stops and
27 graph nodes. The old issue opening paragraph describes the **superseded**
five-district schematic. This slice adds an alternative *physical route*, not
longer clocks, cosmetic detours, artificial waiting or another World authority.

## Authored topology
Existing `cut` is connected by ordinary ground streets to
`east_service` (Eastern Repair Blocks, 16000/0/7000) and
`east_ramp_foot` (Escarpment Service Gate, 16000/0/4400).
A 3.4km horizontal ascent rises **180m (~5.3% grade)** to
`east_ramp_top` (Service Ascent, 16000/180/1000).
The elevated continuation meets the real `upper_bend` street junction,
then existing `terraces`. Speed limits are 18, 20, 25 and 24 km/h on the
four edges. Direct crossings have no illegal links or grade-hopping.

Edges are real `SandboxCityData` metric geometry with `SandboxRoads` time
derived from sampled length and per-edge speeds. `SandboxWorld` still owns
route selection, event provenance, taxi progress, fuel, residents and saves.
`east_ramp_foot` is a player-selectable via node, **not** a fabricated new
passenger stop or NPC household. Service-stop demand/identities are unchanged.
Straight modular roads are deliberate; no invented complex curves.

## Evidence / gates
- `test_city_east_service.gd`: topology, grade, alternate real route,
  measured distance and duration, exact midtrip save/replay, once-only
  segment events, no fabricated fare.
- `test_city_east_service_scene.gd`: genuine native taxi enters the new
  street, moves with the physical execution contract, and restores exactly.
- Existing native/Chromium two-fare journey contracts now select this real
  service-gate waypoint for the first authentic seeded fare, including
  authored in-ride speech, mid-route Native+Web Save/Load and once-only
  settlement, followed by a second shorter actual NPC-generated fare.
  Test execution must pass on the *exact new head* before claiming proof.
- Real player evaluation of city breathing-room, individual NPC activity,
  new route legibility, Linux/Windows and longer journey comfort remains
  outstanding. Automated replay and screenshots do not mean accepted pacing.

The bounded road supports core city expansion without prematurely rebuilding
all six neighbourhoods or investing in UI polish.
