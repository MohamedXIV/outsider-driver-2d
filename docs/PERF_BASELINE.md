# Perf baseline (#94, Epic #89)

Native Godot 4.7.2 numbers from `tests/perf/profile_long_run.gd`. This is a **software-rendered Linux run**, not a GPU, WASM or Windows measurement. Do not quote these as player-facing frame times.

## Machine and scenario

- Godot 4.7.2-stable (official), `Engine.get_version_info()`.
- CPU: Intel Xeon @ 2.80 GHz, **2 cores**. Renderer: `llvmpipe` (software) under `xvfb-run -a`, `--audio-driver Dummy`.
- Seed 8. Ledger phase: the world is advanced with `world.advance(60)` only (no rendering), then the live scene is measured for 10 s per target with the clock frozen (`_process(0.0)`), so the numbers are presentation and per-frame scans, not world ticks.
- Probes: `OD2D_PERF_PROBE=1`. Sections are coarse: `frame.process`, `corridor.step`, `world.advance` (the whole `advance_elapsed` call, **tick systems are not split**), `main.render`, `city.paint.<layer>`, `city.draw_people`.

## Verdict on the ledger hypothesis

Hypothesis (from #86/#95): frame cost grows with the append-only event ledger because many systems scan it.

- **Confirmed, linear, but not sufficient.** One scan of the ledger for a stop that was never reached costs 0.24 ms at 1 008 events and 6.4 ms at 10 000 events (`scan.txt`, domain only). That is about 0.6 µs per event per scan.
- **Partly consistent in the scene.** `city.paint.ground` rose from 11.5 ms to 20.3 ms between 1 328 and 10 108 events. The scan growth over the same range is about 6 ms, which fits roughly one full-ledger scan per frame. **That call count is inferred, not counted.**
- **Not the driver at #86's 1–2k range.** At 1 328–2 078 events the scan is 0.24–0.5 ms per call, and most of the ground-paint cost is elsewhere (about 5 ms, not scaled by the ledger in these runs).
- **Per-frame sync is flat.** `frame.process` stayed at 0.67–0.83 ms from 1 k to 10 k events.
- **The bulk of frame time here is software rendering.** Frame intervals are 84–110 ms p50 on llvmpipe. That floor dwarfs every ledger term measured here.

Status: hypothesis partially confirmed. The ledger scan is real and linear, and it grows to roughly 6 ms per frame at 10 k events. It does not, on this data, explain a progressive FPS loss at 1–2 k events. The #86 progressive drop is still unexplained.

## Ledger phase (run 3, current code, `ledger-run3.txt`)

Frame intervals are `await process_frame` gaps over a 10 s window, about 90–125 frames each.

| target | events | minute | p50 ms | p95 ms | `frame.process` µs | `city.paint.ground` µs | `city.paint.above` µs | `city.draw_people` µs |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 0 | 480 | 84.6 | – | 226 | 477 | 99 | 189 |
| 1 000 | 1 328 | 1 860 | 93.3 | – | 673 | 11 496 | 1 073 | 5 721 |
| 2 000 | 2 078 | 1 980 | 92.8 | – | 727 | 13 065 | 1 198 | 6 314 |
| 5 000 | 5 027 | 2 400 | 106.2 | – | 772 | 16 862 | 1 400 | 7 102 |
| 10 000 | 10 108 | 3 060 | 108.0 | – | 830 | 20 325 | 1 415 | 7 242 |

Run-to-run noise: p50 at 10 k was 107.4 (run 1) and 110.2 (run 2), against 108.0 in run 3. The 0-event row differs in world content (few people visible at minute 480), so compare rows 1 000 and up.

Runs 1 and 2 (`ledger-run1-pre-paint-probe.txt`, `ledger-run2-pre-paint-probe.txt`) ran before the `city.paint.*` probe existed. Their p50 values are in the same range.

## Long run (scripted, four six-hour segments, `long-run.txt`, `long-run-per-second.csv`)

| segment | minute | events | p50 ms | p95 ms | `frame.process` µs | `corridor.step` µs | `world.advance` µs |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 842 | 83 | 76.7 | 94.6 | 963 | 373 | 528 |
| 1 | 1 204 | 162 | 72.5 | 85.9 | 387 | 171 | 112 |
| 2 | 1 566 | 205 | 72.6 | 87.6 | 717 | 283 | 165 |
| 3 | 1 928 | 1 554 | 96.1 | 122.3 | **11 309** | **10 761** | 296 |

**Unexplained:** segment 3 spikes in `frame.process` and `corridor.step` at about 1.5 k events, while the ledger phase had only 0.7 ms `frame.process` at a similar count. So this spike is state-dependent, not ledger size. One run only. Needs a repeat and finer probes inside the tick systems. The long run was recorded before the `city.paint` probe was added; the rest of the code was the same.

## Scan microbench (`scan.txt`, domain only, headless, 200 reps)

| events | minute | µs per call (unreached stop) |
|---:|---:|---:|
| 0 | 480 | 1.0 |
| 1 008 | 12 060 | 237 |
| 2 000 | 27 300 | 499 |
| 5 007 | 73 980 | 3 788 |
| 10 000 | 151 260 | 6 377 |

Minutes differ because this phase advances the domain without scene interplay. The scan does not read minutes, so the event count is what matters.

## Probe overhead A/B (`overhead-probe-ab.txt`)

2 000 000 iterations of a loop body with and without a `PerfProbe.begin/end` pair, probe disabled (`OD2D_PERF_PROBE` unset):

- Baseline loop: about 59–64 ms.
- With disabled probe pairs: about 714–737 ms.
- **About 325–340 ns per begin/end pair** in the GDScript interpreter.

That is not free. At about 8 pairs per frame it is about 3 µs per frame, under 0.01% of a 100 ms frame on this machine. "Disabled adds no measurable cost" is therefore only true at frame scale, and this is measured, not assumed.

## Limits

- Software renderer on 2 cores. Not representative of a GPU, of WASM or of Windows playtests.
- Tick systems are not split out. `world.advance` is one section, so tick-system ordering and cost remain unmeasured.
- Scene-level sections are coarse. The ledger scan is confirmed by microbenchmark, not by per-call counting inside the frame.
- The #87 matched seed-8 perf scene was not run here. Its loop was reused, not its numbers. Compare with it on the same runner before quoting cross-PR numbers.

## Reproduce

```sh
# Probe overhead A/B (probe OFF)
OD2D_PERF_PHASE=overhead $GODOT --headless --path . --script res://tests/perf/profile_long_run.gd
# Ledger hypothesis (native, needs a display)
OD2D_PERF_PROBE=1 OD2D_PERF_PHASE=ledger xvfb-run -a $GODOT --path . --audio-driver Dummy --script res://tests/perf/profile_long_run.gd
# Long run with per-second CSV
OD2D_PERF_PROBE=1 OD2D_PERF_PHASE=long OD2D_PERF_OUT=/some/dir xvfb-run -a $GODOT --path . --audio-driver Dummy --script res://tests/perf/profile_long_run.gd
# Domain-only ledger scan
OD2D_PERF_PHASE=scan $GODOT --headless --path . --script res://tests/perf/profile_long_run.gd
```

Raw outputs are in `docs/perf/raw/`.
