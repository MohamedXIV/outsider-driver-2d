# World vehicle execution — integration in progress

This branch adds a bounded execution contract and a replaceable native body for existing player trips and genuine municipal shuttle trips. The main scene does **not** instantiate these bodies yet. This is not completion of issue #67 or an accepted living-streets milestone.

World retains the route, its original planned minutes, population and settlement authority. A nearby body may report monotonic progress up to two route minutes ahead of the integer cursor. Before committing a city minute, World records `vehicle_execution_wait` if the physical cursor has not reached the next route minute. Other actors and city time continue. Municipal pause/arrival changes are accounted for by those source-specific wait events, alongside the existing zebra ledger. A body cannot create residents, start trips or settle fares.

World snapshots retain source journey, route, progress, physical position, speed, heading and hold reason. Departure uses the existing real arrival anchor. Save validation checks genuine journey identity, finite bounded state, directed-route position and entry provenance. Far handoff records the exact within-minute anchor and continues from that progress. Existing version-12 snapshots without an execution registry remain supported.

`SandboxWorldVehicleBody` sweeps a 25×13 collision rectangle matching the visible vehicle footprint along the authored route. Its target speed observes clearance and the shared acceleration/service-brake limits. A final sweep fails closed for newly inserted obstacles. The body writes its resulting pose into World; the renderer reads that same pose. The focused native test requires nonzero movement before braking, a saved stop and renewed movement after obstacle removal.

Still required before main-scene activation:

- Production coordination/fairness for the saved exclusive connector admission; focused domain ownership/release is now implemented and tested.
- Native multi-vehicle and Web visual acceptance of the corrected metric widths/road envelopes.
- Source-backed departure queues/bays where aggregate services initially overlap.
- Loaded-corridor coordinator, deterministic manual-time execution, reroute rebasing and scene reload/reentry.
- Full genuine two-fare and shuttle native/Web visual verification after activation.

`SandboxVehicleJunctions` grants one World-owned reservation per authored lane connector junction. A second real vehicle cannot report progress into the occupied connector. Entry/release events reconstruct the saved reservation ledger; forged ownership is rejected. A focused test uses seed 1's real `npc:08` municipal service and the actual player reposition route to demonstrate saved exclusion and subsequent admission after clearance. This is a domain test, not a full native multi-car visual acceptance.

The read-only `docs/evidence/r05-world-execution/lane_clearance_audit.gd` measured minima of 6.44 px (basin–clinic), 5.46 px (clinic–docks), 4.14 px (freight) and 3.77 px (garage feeder) before the correction, below the 13 px visible body width. Authored widths are now 240 metric units; every sampled opposing/same-direction lane pair has at least 17 px separation, including four units of clearance. Asphalt widths follow the projected outer lanes and full body width. Ground roads paint in separate passes with joined ground junction caps; decorative lots reserve the wider road envelopes. The focused clearance test checks all authored profiles independently of the drawing implementation.

Evidence includes the before/after numerical audit, a native screenshot and its reproducible observer. That image is a controlled actual garage→clinic→docks reposition at World minute 521, with nine real residents; it verifies road presentation, not enabled physical-corridor gameplay. The observer pauses the scene's automatic clock and advances the real World route. No native collision acceptance is inferred from a single image.

Verification at `6614e3d`: all 45 domain tests and all 41 native tests passed under Godot 4.7.2. At runtime head `1b9cd57`, all 46 domain tests and all 42 native tests passed after the heading/handoff and clearance changes. The additional variable-delta native regression passed locally at that runtime and adds one native case. No Web or human acceptance is inferred from these results. Five controlled native collision samples with canonical World/render/body traces are in `docs/evidence/r05-world-execution/native-collision/`.

No HUD presentation files are changed. This branch is isolated from the canonical PR73/PR75 heads until the integration above is ready.

## Corridor follow-up: arrival and departure anchors

A real medical fare reproduced a terminal-body bug: reaching the physical goal still reported speed 36. The body now reserves braking distance to its actual final point. A new native regression checks gradual deceleration, a stopped saved goal, exactly one real settlement, canonical/render parked-position continuity and departure from the same pose/heading. Forged or deleted parking records are rejected against the actual journey completion and preceding execution ledger.

`vehicle_parking` is optional for older version-12 saves. A completed physically executed player trip records its final pose in World rather than reverting the canonical position to the graph-node centre. Execution tangents include the real departure anchor, and a reversed new journey starts with the saved parked heading; the bounded steering/acceleration layer then aligns the car. Automatic corridor coordination remains in progress.

## Automatic bounded corridor follow-up

The follow-up corridor branch instantiates `SandboxWorldVehicleCorridor` under
CityView. It maps only the genuine player and existing shuttle passenger IDs to
invisible collision bodies on the four authored ground road profiles. Entry is
420 projected units from the player; exit is 540, giving hysteresis. Unloaded
native cursors hand off at the World fractional clock, including after Load.
Bodies are removed with collision disabled immediately when replacing World.

Main supplies elapsed physical slices before `advance_elapsed()` commits each
World minute. Manual `advance()` uses the same executor, splitting at the saved
fraction and preserving it afterward. Snapshots validate and retain that fraction;
older v12 snapshots default to zero. Near-horizon reentry includes the fraction in
the execution bound. World alone records waits and settles actual fares.

This enables automatic execution, but full-game regression and lifecycle visual
acceptance are pending on this follow-up. The PR78 results above describe its
foundation head and must not be represented as testing the integrated follow-up.
Parked collision occupancy, public vehicle arrival ownership and angular clearance
still require focused validation before claiming the milestone complete.
