# World vehicle execution — integration in progress

This branch adds a bounded execution contract and a replaceable native body for existing player trips and genuine municipal shuttle trips. The main scene does **not** instantiate these bodies yet. This is not completion of issue #67 or an accepted living-streets milestone.

World retains the route, its original planned minutes, population and settlement authority. A nearby body may report monotonic progress up to two route minutes ahead of the integer cursor. Before committing a city minute, World records `vehicle_execution_wait` if the physical cursor has not reached the next route minute. Other actors and city time continue. Municipal pause/arrival changes are accounted for by those source-specific wait events, alongside the existing zebra ledger. A body cannot create residents, start trips or settle fares.

World snapshots retain source journey, route, progress, physical position, speed, heading and hold reason. Departure uses the existing real arrival anchor. Save validation checks genuine journey identity, finite bounded state, directed-route position and entry provenance. Far handoff records the exact within-minute anchor and continues from that progress. Existing version-12 snapshots without an execution registry remain supported.

`SandboxWorldVehicleBody` sweeps a 25×13 collision rectangle matching the visible vehicle footprint along the authored route. Its target speed observes clearance and the shared acceleration/service-brake limits. A final sweep fails closed for newly inserted obstacles. The body writes its resulting pose into World; the renderer reads that same pose. The focused native test requires nonzero movement before braking, a saved stop and renewed movement after obstacle removal.

Still required before main-scene activation:

- Production coordination/fairness for the saved exclusive connector admission; focused domain ownership/release is now implemented and tested.
- Sufficient authored opposing-lane clearance for the actual collision footprint.
- Source-backed departure queues/bays where aggregate services initially overlap.
- Loaded-corridor coordinator, deterministic manual-time execution and scene reload/reentry.
- Full genuine two-fare and shuttle native/Web visual verification after activation.

`SandboxVehicleJunctions` grants one World-owned reservation per authored lane connector junction. A second real vehicle cannot report progress into the occupied connector. Entry/release events reconstruct the saved reservation ledger; forged ownership is rejected. A focused test uses seed 1's real `npc:08` municipal service and the actual player reposition route to demonstrate saved exclusion and subsequent admission after clearance. This is a domain test, not a full native multi-car visual acceptance.

No HUD presentation files are changed. This branch is isolated from the canonical PR73/PR75 heads until the integration above is ready.
