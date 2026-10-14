# P0 Validation — evidence log

## Godot 4.6.3 Linux editor: verified (2026-10-14)

[Targeted CI run #38611865760](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38611865760), head `40412ac`:
- Godot 4.6.3 stable downloaded and started.
- Headless import/parse **PASS**.
- `tests/test_core.gd` **PASS** (including road footprint overlap at crossing).
- Headless scene startup **PASS**.
- Xvfb/software GL captured 360 genuine rendering frames, archived as four snapshots.

Visual review of first capture: close follow, road network, flat bridge, and taxi on elevated road are visible. **Remaining:** capture exact crossing (first sampling landed just past it); distinguish bridge thickness/supports; validate exports on Linux/Web.

## Next targeted pass

The next run samples the **actual underpass** near frame 67, ramp near frame 205 and elevated deck near frame 245, plus start/end. It also attempts Linux executable export and Web export/browser smoke. These checks are **PENDING** until run results are inspected; don't mark them PASS from workflow configuration alone.

## Acceptance

- Correct occlusion at exact ground-level crossing.
- Continuous ramp with no teleport; taxi above deck after climb.
- Camera follow and framing legible on representative frames.
- Valid Linux desktop executable and Web build tested in a browser.
- Placeholder vector scene **does not constitute final visuals**.

The connected local ShellWarden tunnel was unavailable; a single targeted CI job is used for required engine validation. Minimize repeated GitHub Actions runs after evidence is collected.

See [Issue #1](https://github.com/MohamedXIV/outsider-driver-2d/issues/1).
