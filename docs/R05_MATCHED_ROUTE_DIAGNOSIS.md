# Matched host long-route diagnosis for Living Streets (#83)

This is a **diagnostic only**; it neither changes gameplay nor relaxes
`tests/web_city_routes.cjs` or its 240-second acceptance guard.

## Observed evidence before the experiment
- Exact-head GitHub Actions #39554155076, base `f7b014c`: same genuine
  long fare and subsequent shorter fare **PASS** in 345.68s overall.
  The separate exported two-resident suite took 102.53s.
- Codex's constrained two-CPU runtime head `abf819f`: the same long fare
  had 33 world minutes left when its Web 240s gate expired.
  The *other* exported two-resident suite required 269.22s locally.
- This **~2.63x independent test duration difference** is consistent with
  host-capacity effects; it is not enough to prove there was no regression.

## One paired exact-environment run

`.github/workflows/r05-living-route-audit.yml` runs on the *diagnostic
branch only* and consumes GitHub Actions minutes once. It reuses the same
runner, installed Godot 4.7.2, Node, Chromium, SwiftShader and Web harness.
It exports and exercises `f7b014c` (upstream passed base) followed by
`3c59a080` (unchanged runtime/test code of PR #83) **sequentially**.
Each run accepts the exact authored route through `east_ramp_foot` in
Player Mode, talks to the real rider, saves/reloads during the trip and
requires one real fare settlement. Original regression source is not edited.

`qa/long_route_probe.cjs` records both the World minute and remaining
route minutes, real vehicle segment/hold, rendered pose and wall-clock time
every ten seconds. Artifacts include exported PCK SHA256, full chronological
telemetry, per-run result JSON and `comparison.json`. The paired probe has
a longer **diagnostic** ceiling to allow slow machines to finish and collect
evidence; this does not alter the existing 240s acceptance test.

If both passes are comparable, keep the source unchanged and decide whether
the Web runner's wall budget ought to be explicitly calibrated separately,
with a stall watchdog and never weakened arrival or economic assertions.
If Living Streets is materially slower on the **same** runner or its World
minutes stall despite moving browser frames, profile/repair the specific
physical/World update path before any PR acceptance.

No CI, merge, Windows or human gameplay success is assumed before reading
the actual paired result. Draft PRs #83/#77/#81 remain untouched.
