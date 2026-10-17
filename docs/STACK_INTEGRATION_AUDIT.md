# Stacked integration audit — PR #55 → #61 → #62

This report describes the bounded implementation and its acceptance limits.
Executed results belong to the **exact `head` in each validation manifest**,
not to an earlier report, a later documentation commit, or another PR's head.
The manual [integration workflow](../.github/workflows/native-street-pilot.yml)
publishes logs, screenshot artifacts and the checkout SHA for each job.
No issue is closed and no human acceptance is inferred from automation.

## Reviewed stack

| PR | Reviewed upstream head | Role and merge condition |
|---|---|---|
| #55 | `e18aa0cd1444865f0ce7f669590df201ad8de36b` | Player UI, connected city, curved road/elevation groundwork. Base `main`. Subsequent camera, walking and traffic fixes are downstream; this head alone is not the final audited build. |
| #61 | `983ed8724baf936828bb620f270a387fcbd45b7a` | Native pedestrian street pilot; base #55. Draft. Subsequent two-resident and integration fixes are in #62. |
| #62 | Read `git rev-parse HEAD`, workflow checkout and `manifest.json` | Final stack under review; base #61, branch `codex/overnight-completion`, Draft. Merge only in stack order after review; no automatic merge or Draft conversion. |

Upstream heads remain untouched. The complete final-head gate verifies the
integrated stack, not a claim that each historical head passes all new gates.
Rebase/merge changes the code identity and requires fresh validation.

## Confirmed defects corrected during this audit

* Freed/detached native actors remained in the presenter registry. Remaining
  actors could incorrectly allow a newly approaching taxi or genuine shuttle
  through the missing resident's reservation. Invalid view references are now
  removed and canonical missing/offscreen residents participate in clearance.
* Cancelling both pedestrians discarded the saved junction queue because the
  presenter assumed a primary pedestrian always existed. Empty pedestrian
  presentation now preserves and restores physical vehicles and arbitration.
* A completed counter actor remained visible after its resident began a later
  independent trip or accepted a real fare. It now retires when canonical
  transit/passenger state supersedes that completed local visit.
* Wait/Observe advanced world time without reconciling real crossing holds.
  They now use the same per-tick taxi/shuttle boundary as ordinary time.
* Saving a missing active actor or an entirely absent presenter could overwrite the last recoverable save.
  Presentation validation now precedes opening/truncating the file.
* Saved junction admission before the owner's first movement lost FIFO
  ownership. The validated token is now persisted with positions and queue.
* Restore accepted forged resumed progress and premature offscreen arrivals.
  It now checks progress against elapsed canonical ticks and independent
  arrival provenance, without converting a blocked native body into arrival.

Regression witnesses are `test_integration_actor_lifecycle_scene`,
`test_manual_time_crossing_scene`, `test_junction_preentry_scene`, and
`test_local_trip_provenance`. Earlier crossing, return, unload, staggered
multi-resident, blocked navigation, replay and collision tests remain gates.

Validation defects were also corrected: eight legacy browser scripts assumed
the superseded five-node graph, old first-passenger language traits, fixed
diagnostic coordinates and instantaneous +20 minute journeys. They now use
real visible controls/current graph and physical crossing completion. Shared
browser plumbing reads bounds only; it cannot command the world. Request clicks
are matched by persistent offer identity; freshly rebuilt/scrolled row bounds
are checked against native Godot hit testing. The two
frozen prototype journeys run against an archived source copy whose sole
configuration difference is the prototype main scene. Export filters exclude
repository reports/test resources, which have no runtime references.

## Architecture and provenance review

`SandboxWorld` remains the sole live authority for resident identity, needs,
offers, schedules, route/economy, permitted local goals and event history.
`SandboxAutonomy` and local-trip policy mutate that world; the main controller
connects real UI and nearby presentation to it. Save restore constructs a
candidate world and validates it before replacing the current world.

Each of at most two local eligible residents has an independent
`CharacterBody2D`/`NavigationAgent2D`, slot, reservation and validated arrival.
Native movement reports physical arrival; coarse offscreen travel advances
only after a sourced handoff. Replay reproduces persisted world events and
offscreen ticks, not an assertion of bit-identical physics at every frame.
Missing bodies fail closed; a blocked body cannot time out into an arrival.
The last valid save can recover a lost active body.

The player taxi and resident-owned shuttle use the same aggregate crossing
clearance. Shuttle waiting extends that resident's existing trip, including
its source-offer and signed wait history; it creates no replacement resident
or fare. The three local junction cars are explicitly **ambient** physical
kit actors, not additional citizens or a second economic simulation.
Their FIFO admission, physical exit clearance and headway are bounded to the
existing east T module; they do not claim city-wide fleet arbitration.

Street navigation is ground-only and separate from the legal vehicle graph.
Bridge supports/rendering sample existing elevated edges and ramp profiles;
apparent overlap never creates a legal graph edge or walkable connection.
Camera, UI locale, reduced motion and Debug Mode are presentation preferences.
Ink consumes sourced facts and validated intents, not private omniscience.

The main view/controller is still substantial. Taxi and shuttle adapters have
some intentionally parallel boundary checks because their canonical transit
representations differ. No evidence warranted rewriting working modules or
introducing a generic traffic framework during this defect audit.

## Issue-by-issue acceptance matrix

All statuses below mean **technical evidence subject to a green final-head
run**, never human acceptance. Issues remain open.

| Issue | Implemented scope / automated evidence | Remaining acceptance |
|---|---|---|
| #49 | Default Player Mode, reversible Debug Mode, same world; native presentation and `web_city_playability`, language/save/Ink regressions. | Human first-minute discoverability and legibility. |
| #50 | Compact contextual HUD, fare through arrival without Debug, market/modules/AR, narrow Arabic and reduced motion; native screenshots and `web_city_playability`. | Human hierarchy/taste, touch-device comfort and interaction pacing. |
| #51 | Connected legal graph, genuine varied edge length/cost, short and long fares with speech and reload; `test_city_journeys`, `test_sandbox_routes_scene`, `web_city_routes`. Web log quantifies minutes/metres/nodes. | Human breathing room, stress and passenger visibility; no optimal duration invented. |
| #52 | Sampled road geometry/tangent, lawful ramps and disconnected apparent crossings; road/grade tests and native/Web road evidence. | Visual treatment superseded by #58; human road realism remains open. |
| #56 | Bounded smooth manual zoom, touch/keyboard/wheel, closer default, persistence and narrow UI; camera native and `web_camera_zoom`. | Human preferred framing and comfort. |
| #57 | Parked and moving NPC visual interpolation independent of taxi clock; `test_npc_interpolation_scene`, related handoff/movement regressions. | Human perceived smoothness; city-wide walkers remain coarse outside the native slice. |
| #58 | Reusable orthogonal street/block kit, bounded T traffic, supported bridge deck/retaining ramp presentation, level isolation; street-kit, bridge and route tests/screenshots. | Prototype scope only. Human modular-street direction, bridge appearance and all-district art expansion remain open. No new graph connections. |
| #59 | Two genuinely eligible persistent residents (seed 29: npc:04/npc:08), separate native agents/bodies, blocked path, independent exactly-once arrival, cancellation, save/reload, near/far handoff and provenance; multi-resident/lifecycle/native gates and `web_two_residents`. | Bounded garage-to-counter corridor only; city-wide native migration is not complete or required by this pilot. Human motion/appearance check remains open. |
| #60 | Marked crossing, per-resident reservations, whole-body aggregate clearance for actual taxi and world-owned shuttle, staggered entry, collision avoidance, missing bodies, saved holds; three ambient cars with local T FIFO/headway/blocked-exit tests and `web_junction_traffic`. | Bounded module, not city-wide physical traffic. Other junctions/fleet-wide arbitration and visual feel remain future work. |
| #48 | Integrated playability reboot slices above. | Umbrella remains open for human feedback and staged broader city work. |
| #15 | One systemic sandbox with regression gates for autonomy, dispatch, economy, contacts, knowledge, Ink and persistence. | Long-term sandbox umbrella; these slices do not complete the entire game. |

Windows **runtime** and actual handheld/touch-device testing remain unverified.
Linux native execution and Chromium emulation do not establish those gates.

## Independently reproducible validation

From this committed checkout, install Godot **4.7.2** with its Web export
templates, Python 3.12+, Node 22, Playwright **1.56.0** and its Chromium binary.
Linux native needs a display (`xvfb-run` is sufficient) and Mesa/OpenGL.
Set `GODOT_BIN` to the absolute editor executable. Use writable XDG directories
in restricted environments; the templates must be under that XDG data root.

```sh
git checkout codex/overnight-completion
git pull --ff-only
git rev-parse HEAD
export GODOT_BIN=/absolute/path/to/Godot_v4.7.2-stable_linux.x86_64
export LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=2
export NODE_PATH=/absolute/path/to/node_modules
export PLAYWRIGHT_BROWSERS_PATH=/absolute/path/to/playwright-browsers
OD2D_LOGS=work/final/domain python tests/run_city_gate.py
OD2D_LOGS=work/final/native xvfb-run -a -s '-screen 0 1280x1400x24' python tests/run_city_gate.py --native
OD2D_LOGS=work/final/web python tests/run_exported_gate.py
```

The full inventory is **36 domain/adapters, 30 native scene, 16 exported
Chromium suites** (5 current Player/camera/street, 8 migrated diagnostic city,
3 canvas/frozen prototype). The Web runner rejects a dirty tracked checkout,
unclassified suites, wrong Godot version, export errors, leaked docs/tests,
nonzero browser exit and a changed head. Each browser process has a bounded
timeout with process-group cleanup; tests retain their own journey deadlines.
It exports and serves its own files; no stale external server is trusted.
Manifest hashes identify the actual exported PCKs. Screenshot filenames are
preserved in the artifacts alongside individual command logs.

For an independently visible run, dispatch `native-street-pilot.yml` with
`--ref codex/overnight-completion`. Four jobs run the complete native/domain,
current Web, diagnostic Web and frozen fixture scopes. Inspect the checkout
SHA in every job, not just a historical green badge. Human acceptance and
merge approval remain separate from successful technical validation.
