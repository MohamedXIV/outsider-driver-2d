# Real World taxi / municipal service component — native and Web

Runtime: `1e16dddfd4f267eaead6d24af6812ea1ed39e0e8` from Draft PR78, pinned Godot 4.7.2. This evidence-only branch contains documentation, not the runtime implementation. Do not merge its old runtime base or run its observers as though that base were PR78.

The controlled fixture uses World seed 1 and a genuine player reposition toward docks through clinic. It advances 41 canonical minutes, binds the actual player journey, and holds that execution cursor while city time advances ten minutes. Existing resident `npc:08` independently starts a real municipal trip at minute 523. At minute 531 both actual native presenters are attached; no residents, fares or settlements are fabricated. This deliberately staged component test is not a spontaneous production playthrough.

Four chronological samples show reservation denial/approach, the shuttle turning while the taxi brakes at the connector, the same poses and saved ownership after World snapshot restore, and both vehicles clearing. Each native step checks physical rectangle polygon overlap; both real IDs drain the exclusive clinic connector. World snapshots, source IDs, raw World coordinates, render positions, native positions, speed, heading and reservation ownership are retained. Population remains nine.

The main-scene automatic proximity coordinator is **not enabled**. Departure queues/bays, reroute/manual-clock integration and remaining actor lifecycle acceptance are still required. These captures do not certify human driving, Windows runtime, automatic corridor gameplay, or the product's genuine two-fare Chromium case.

## Native

`native/observer.gd.txt` was run as an editor SceneTree script against the exact runtime above with a native X11/software display. Copy it to `work/observer.gd` in that runtime checkout and invoke the pinned Godot editor with `--path . --script work/observer.gd`; it writes `work/two-world-vehicle-frames/`. `queued` denotes denied admission while approaching; the subsequent turning/restored samples show the nearly stopped taxi.

## Chromium/WebGL

A `git archive` of the exact runtime was exported. Only `project.godot`'s main scene changed among original files; a diagnostic Node2D scene/script was added. `web/provenance.json` records those overrides and the exported PCK/observer hashes. All production World, road, native body and renderer source files remained unchanged.

The observer uses always-on `_require` checks because Release exports remove editor `assert` expressions. Initial harness attempts which relied on editor assertions or a transient screenshot timing window were discarded; they are not accepted module results. The final observer captures unmodified WebGL viewport PNG bytes at `RenderingServer.frame_post_draw`, so pixels correspond to the recorded World/body/render state. The browser harness reads emitted records/images, checks genuine IDs, population, canonical/render/native agreement, restored poses, cleared ownership and zero browser errors. It does not write World state.

`web/observer.gd.txt`, `main_scene.tscn.txt` and `browser_probe.cjs.txt` reproduce the isolated diagnostic export. This fixture replaces the main scene for observation; it is not the normal game export or an input path hidden in the shipped game. The sampled native/Web body positions match numerically; see `comparison.json`. Images may differ by renderer.
