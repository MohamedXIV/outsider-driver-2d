# World-owned physical vehicle corridor

The automatic Main corridor is implemented on runtime `7faa5cc45e6ad77bc25c5bb7e54573a6d58e34b4`. The later `14c1609` changes only three restored-scene regressions so they retain the real physical executor and wait for actual World commitment. World owns city time, source journeys, validated waits/reservations, population and settlements; nearby physical bodies execute those journeys and report bounded progress. The renderer consumes the same canonical poses.

Coverage is deliberately bounded to four authored ground-road profiles with proximity hysteresis, plus source-backed clinic curb arrival and empty municipal return to the depot. Other routes use aggregate handoff. This does not establish whole-city physical traffic or human acceptance. The following sections retain the foundation assumptions, reproduced failures and subsequent repairs chronologically; statements about missing Main activation refer to those earlier candidates.

Sequential actual Main Native/Web evidence and precise capture limitations are in `docs/evidence/r05-main-7faa/`. Full gate results remain associated with their recorded exact heads; milestone acceptance is pending. No HUD presentation files are changed.

## Historical foundation before Main activation

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

The first integration candidate `a0b234a` failed the Native city-journeys timeout;
its Domain attempt was stopped during investigation. They are not accepted gates.
A real seed9 medical route also reproduced a terminal cursor stuck at
42.9999778/43 while the Vector2 endpoint no longer changed. The follow-up uses
monotone cumulative lane arc length (including bends), and commits the exact
endpoint only within .001 projected units after braking below .05. Focused genuine
two-journey, contact/meeting and terminal braking checks pass after this repair.

## Clinic curb ownership follow-up

A genuine seed9 medical fare reproduced a 43.3316-pixel gap between the incoming
taxi endpoint and the previous clinic walker spawn. New physically bound clinic
trips use an explicit saved `clinic-curb-v1` arrival policy: the final authored
segment blends into the clinic frontage bay. Older execution snapshots without
that policy retain their old geometry. Planned road minutes remain unchanged;
any physical delay is recorded by the existing World wait contract.

The actual completed fare transfers its terminal World pose/source into the
resident's alight record. The pedestrian starts 14 pixels outside the car centre,
clearing the 6.5-pixel vehicle half-width and 6-pixel walker radius, then walks
outward to the real clinic doorway. Snapshot validation reconstructs this curb
and its original entered journey; pose forgery or deleting the curb is rejected.
The same parked taxi footprint remains collidable until the next real journey.
No new resident, fare, settlement, or synthetic driver is created.

Focused native arrival/braking, curb transfer, physical walking, parked occupancy,
Save/Load, forged-curb rejection and next departure pass. The previously failing
city-presentation test assumed planned minutes guaranteed arrival; its retained
trace showed a stopped endpoint with one genuine World delay still outstanding.
The test now advances to actual arrival within a bounded delay and validates the
World snapshot before requesting the next route. All presentation assertions remain.

## Angular clearance and automatic two-vehicle verification

A focused genuine-taxi repro placed a small marked obstacle just outside the
initial rectangle. The previous translation-only query allowed the taxi's corner
to penetrate it while turning at zero speed. The physical adapter now queries
predicted oriented footprints and covers the bounded angular sweep before it
reports the next pose. The regression fails before this change and passes after
it; variable-delta braking, native body/turn/reload, arrival and corridor checks
also pass locally. Emergency clearance failure retains the previous safe heading.

The automatic coordinator test stages a real seed1 reposition and lets the city
produce its genuine npc:08 shuttle. It verifies both automatically attached
bodies' polygons every frame, exact poses after reloading an occupied reservation,
and both vehicles draining the exclusive connector without population changes.
This is a controlled real-journey conflict test, not a spontaneous demand claim.

Native real-time Main clinic frames and full read-only World traces are retained
under `docs/evidence/r05-collision-corridor/clinic-e0ef24c`. That source's Domain
46/46 passed; its full Native run failed the integration lifecycle test's second
planned-duration assumption. The latter now waits for actual bounded World
arrival before issuing its next route; all identity/queue assertions are retained
and its focused run passes. No full integrated final gate is claimed yet.

## Genuine clinic shuttle arrival and fractional departure follow-up

A real seed9 municipal trip reproduced disappearance of the vehicle at passenger
arrival. Physically bound clinic shuttles now have a separate authored frontage
bay and transfer into a World-owned empty return to the actual depot over authored
roads. `vehicle_departures` is sourced by the genuine alternative-arrival event,
original public departure and physical execution entry. It contains no resident,
fare or economic tick. World minutes and validated execution waits advance it.
Its stable `shuttle:<original-source>` identity survives rider exit, body
replacement, offscreen handoff and Save/Load. On reaching the depot it remains
parked rather than vanishing in view. This authored continuation is deliberately
limited to clinic arrivals, rather than inventing a whole municipal fleet.

The actual rider exits outside the saved bus footprint and moves along the clinic
frontage on World time. Close-range collision proxies use that same canonical
pose and real resident ID, including removal/reentry; no duplicate NPC is added.
Forged service poses or deleting a source-owned service record fail restoration.
Focused native shuttle arrival, identity transfer, empty departure, saved service,
handoff and resident threshold checks pass locally.

A separate retained native repro started a new taxi trip at clock fraction .6.
The prior binder jumped forward from the parked curb because it treated the
entire fraction as elapsed journey time. New real accept/reposition events stamp
their World clock fraction, and binding subtracts only that initial offset. The
existing zero-elapsed executor callback reconciles the new real journey before
presentation. This keeps render synchronization read-only and retains the actual
parked pose/heading. Invalid source fractions are rejected; older events default
to zero. Focused nonzero-fraction departure and native alight regression pass.

Full Native on be83706 exposed one more old planned-duration assumption in
`test_passenger_alight_scene`; it now waits for actual bounded physical arrival,
retaining all walking, Save/Load, legal curb and exactly-once assertions. Its
focused run passes. Full integrated gates for this follow-up are still pending.

Clinic curb exits now request the same exclusive World junction reservation as
incoming connectors. A retained two-real-journey repro failed when an empty
shuttle's curb merge ignored a taxi's active claim; the corrected merge returns a
zero-progress stop and survives snapshot validation. This applies to the newly
authored curb policies and preserves legacy connector save records.

Native scene tests that use a planned duration as an arrival command share
`tests/native_route_checks.gd`: advance planned time, then allow at most 60 sourced
World delay minutes, require actual arrival, and validate the snapshot. Their
original pose, currency, identity, route, native motion and settlement assertions
remain. Tests deliberately restoring only a domain copy explicitly hand off its
absent native presenters at the saved fractional clock; scene restores continue
to recreate physical bodies and do not use that aggregate-only option.

## Saved numeric identity and terminal admission

The df0b2c3 full Domain run failed `test_sandbox_ar`; a retained diff showed the
new clock zero changing from float to int through JSON. It also reproduced an
unloadable save for an authoritative fraction one ULP below one. Clock stamps
now preserve the existing one-picosecond upper margin and integral ledger zero.

Native df0b2c3 reached the peer-scene reload assertion and failed exact event
identity: Native progress/base/fraction types and some coordinate mantissa bits
were lost by JSON. Assertions were retained. New saves include Godot's built-in
object-free Variant encoding of the same World, checked against the readable
JSON before restoration. Altering either representation rejects Load; legacy
JSON-only v12 saves remain readable. The full numeric round-trip regression now
covers zero, a nontrivial fraction, near-one, physical execution entries and
legacy/mismatched payloads. Focused float, AR and unmodified Native peer checks
pass. This is a serialization detail, not a second runtime World or clock.

Curb arrivals now reserve the same clinic conflict area as curb departures and
through connectors. A retained genuine taxi/shuttle repro failed before this
arrival-window change; the corrected arriving shuttle stops for the taxi's
existing exclusive claim and restores its queue consistently. Upstream moving
vehicles no longer report a junction-stop reason merely because a junction lies
far ahead. Six real-time Main public-shuttle frames and full read-only snapshots
from df0b2c3 are retained under `public-df0b2c3`; they are distinct from final-head
suite acceptance and the contested-arrival test.

## Rerouting physical progress and bounded execution speed

A genuine seed9 medical fare was driven by the native body across its first
road, then handed off normally. Queuing a depot reroute before the slower
integer route counter reached that same node erased its physical cursor and
jumped the presentation back. The retained repro failed before this change.
`SandboxVehicleReroute` now retains the already-driven prefix and chooses a
junction whose turn has not begun. Pending geometry is shared by execution and
reservations. When World applies the suffix it rebases route coordinates while
keeping the actual pose, speed, heading and incoming authored turn context.
A sourced rebase event and refreshed far anchor survive Save/Load; removing that
context is rejected. A second genuine market fare tests the live occupied clinic
turn, including transferring its reservation to the carried turn without moving
the body. Existing domain-only route planning keeps its prior policy.

The execution-budget boundary also reproduced the terminal-speed defect: a taxi
could stop at its allowed two-minute lookahead while still reporting cruise.
It now service-brakes against that moving World boundary as well as the final
goal, and resumes after World commits. Native tests cover both a real reposition
and a real medical fare with the future clinic control present.

The e74159c full Native attempt timed out in the unchanged 24-hour autonomy
scene. Instrumented six-hour commands took 30.701, 12.784 and 24.956 seconds,
with the last command not completing within the retained attempt. Reusing the
same curve table for predictive samples and the same shape-query object, plus
sleeping an entirely stationary loaded set until the next World boundary, ran
all four commands in 6.632, 2.653, 5.909 and 11.631 seconds and passed all original
autonomy/population/reload assertions. Actual reported poses and final angular
clearance still use exact authored geometry; physical substeps remain 1/60.
Rejected physical reports now fail visibly instead of silently holding a car.

Focused routes, execution, junctions, numeric Save/Load, handoff/live rerouting,
lookahead braking, genuine two-car conflict, variable delta and public shuttle
arrival checks all pass on the working follow-up. e74159c itself has Domain
46/46 and current Chromium 6/6 PASS; its full Native timeout is not a PASS.
The new follow-up still needs its own complete gates. Evidence directories are
excluded from Godot imports/exports; the raw GitHub artifacts remain available.

## Manual-time peer clearance and clinic frontage admission

The exact `14c1609` Native run failed the heading scene on the next genuine
clinic-to-docks journey. A read-only repro found two actual taxi/shuttle bodies
within 0.52 pixels, while their kinematic server transforms still reflected the
previous engine physics frame. Manual World advancement executes multiple body
steps before that frame; forcing a node transform did not change this server
behavior. The new regression failed on intersecting genuine footprints before
the repair and now completes three real seed8 reposition journeys, with the
independent municipal trip, nine residents and no fare settlements.

Managed peer queries now use the current World-accepted oriented body footprints.
Native motion sweeps retain ordinary obstacle/pedestrian/crossing collision and
exclude only those peers whose current footprints are checked explicitly. The
existing angular sweep and World reservation/report validation remain in force.
No saved state schema, source journey, planned road duration or clock is added.

The third journey also reproduced an incoming taxi and a real empty service
blocking one another outside the clinic's ordinary lane connector. While another
journey owns the clinic reservation, native braking now queues outside the full
authored curb offset plus shuttle standback envelope. World records the resulting
waits through the same source-validated ledger. This provides space for the
reserved curb merge to clear without changing the saved reservation contract.

The heading regression now supplies physical motion before inspecting the
instantaneous canonical edge commitment; it retains the original heading and
steering limits and additionally asserts that the actual internal segment changes.
Focused heading, conflict, variable-delta, rotation, saved turn, horizon and
three-journey manual clearance checks pass individually. A batch turn attempt
ended without a completion marker; its direct rerun passed, and it is not counted
as a complete-suite pass. Full final gates remain required.

The `7faa5cc` exported all attempt passed five current cases and stopped at the
passenger-alight 240-second deadline before debug/fixture ran. A fresh read-only
repro retained an advancing genuine taxi at minute 512, segment 3, with no
settlement yet. The Web test now allows 600 seconds of software-WebGL observation;
its actual clinic arrival, identity, exactly-once economy, walking and reload
assertions are unchanged. This deadline change is not a Web pass claim.

## Reserved zebra, independent queues and retained held poses

The exact `8d74f4a` full Native run failed shared crossing priority: the real
npc:07 shuttle held at the zebra while the following taxi physically stopped
before its integer approach window. Advancing planned minutes could not make
that follower independently latch. The new `SandboxVehicleCrossings` module
reads existing World pedestrian reservation events and current accepted vehicle
footprints. Bodies service-brake before the whole 26-unit paint envelope; World
then latches an at-rest physical approach or a real held leader's nearby queue.
Native approaches do not fall back to a stale integer cursor. Aggregate legacy
approaches retain their existing policy.

Each new physical taxi yield records its actual journey source, progress, pose
and heading in the existing World start event. An early held snapshot requires
that original evidence and the validated execution registry. Its validity does
not depend on the leader remaining held: the two real journeys can release
independently. Deleting either the hold evidence, execution source or required
handoff event is rejected. A retained early hold also survives native unload and
reentry; its pose and heading remain fixed while unrelated city minutes advance.
No new clock, fabricated resident, economic settlement or save version is added.

A domain regression also reproduced the occupancy query ignoring an accepted
native footprint ahead of its integer cursor. Pedestrian admission now checks the
whole native rectangle against the authored zebra paint, in both taxi and real
municipal queries, rather than advancing or delaying admission from that cursor.

Focused domain and Native checks pass for both road directions, shuttle/player
co-yield, independent release, unload/reload, source deletion rejection and held
heading retention. At 30, 60 and 120 Hz and a .1-second native delta, actual
reserved-zebra bodies accelerate, service-brake to rest before the paint, save a
valid held pose and resume after the genuine reservation clears. The first new
two-second observation still showed lawful deceleration (1.71 units/s); a bounded
actual-stop observation replaces that arbitrary sampling instant without relaxing
the acceleration/braking, stopped pose or release assertions.

Pre-physics v12 holds without execution provenance can project a car onto the
paint. The coordinator preserves that legacy projection until clearance instead
of adding a blocking physical footprint there. After release, native execution
enters at the identical visible position. New physically sourced held snapshots
retain their native bodies and exact state. This bounded compatibility behavior
is not a claim that old projection-only saves had physical collision.

The `8d74f4a` Domain 46-case suite passed; its full Native run failed the shared
crossing assertion above. Its exported attempt failed at a 30-second screenshot
capture deadline, without a gameplay assertion failure. Those attempts are not
accepted final suites. Complete gates on the crossing follow-up remain required.

## Clearing paint already occupied when a pedestrian reserves

Exact `2f830983c2c39bd130ce77a411acf047617eef28` completed Domain 46/46 and
Native 51/51 locally. A further genuine native repro then reserved the real
npc:02 errand after an actually moving taxi had entered paint at progress
2.124879, speed 36. The earlier guard could strand that taxi inside the zebra
while the safe-pavement pedestrian was waiting for it to clear.

The existing right-of-way rule now also applies to the real corridor: a body
already occupying paint clears it before a newly reserving waiting pedestrian
enters. Such a body cannot latch a new World yield there. Native sweeps still
protect any physically committed walker, and following vehicles still brake
before the reserved paint. The regression advances genuine World minutes and
requires the occupied taxi to clear without a painted-area hold.

Compatibility admission also covers older sourced player/shuttle holds already
inside paint, and aggregate municipal holds with no native registry. Their exact
visible pose and World wait remain; a blocking native body is deferred until the
pedestrian clears. Entry afterward preserves identity and visible position.
Current physically sourced holds before the paint keep their native bodies.
This is an explicit compatibility/aggregate transition, not a claim of physical
collision for older projection-only states.

Twelve focused domain/Native crossing cases pass on this follow-up, including
late reservation, both directions, co-yield, snapshots, manual clock and the four
braking deltas. The additional aggregate/sourced compatibility variants pass in
the corridor regression. The parent head's complete suites do not substitute for
final exact-head CI on this follow-up.
