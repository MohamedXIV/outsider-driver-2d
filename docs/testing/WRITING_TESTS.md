# Writing tests

Tests are `tests/test_*.gd` scripts run with `--script` by `tests/run_city_gate.py`. Domain tests use `--headless`; files ending in `_scene` (and the few listed in the gate) run without `--headless` with `--audio-driver Dummy`.

## Template

```gdscript
extends SceneTree

func _initialize() -> void:
	var world: SandboxWorld = SandboxWorld.new(8)
	if not Check.ok(world.open_offers().size() > 0, "seed 8 has open offers"): return
	if not Check.ok(not world.advance(0), "advance(0) is refused"): return
	Check.finish(self, "MY_SYSTEM domain")
```

## Rules

1. Every check is `if not Check.ok(condition, "message"): return`. Keep the `return`. A failed check quits the tree with code 1, but GDScript keeps running the rest of the function until it returns.
2. Put a specific message in: `Check.ok` prints `FAIL <file>:<line>: <message>`, and that line is what you read first.
3. End with `Check.finish(self, "NAME")`. It prints `PASS NAME` and quits 0. The gate needs a `PASS` marker in every `test_*` file.
4. Scene tests that `await` need the same pattern inside `_run()`. Do not leave a failed check followed by another `await`.
5. A failing test is killed by the gate on its first `FAIL ` line. The 90 s timeout is only a backstop for hangs.

## Running one test through the gate

```sh
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 OD2D_ONLY=test_sandbox python3 tests/run_city_gate.py
```

`OD2D_ONLY` takes a file stem. The gate still needs a clean tracked tree and runs the import step first.

## Negative control

`tests/support/fail_fast_control.gd` is not a real test. It fails immediately and then hangs. Copy it to `tests/test_zz_fail_fast_control.gd`, run it through the gate, and confirm it fails in well under 5 s. Delete the copy afterwards. Measured: 0.3 s direct; the gate run adds the import step.

## Current status

Converted to `Check`: `test_sandbox`, `test_city_save_validation`, `test_cab_gear_scene`. The other `tests/test_*.gd` files still use `assert()`. A failed `assert` under `--script` does not exit, so those tests hang until the 90 s timeout. Convert a file when you touch it.

## ADR: test framework (GdUnit4 / GUT)

- Status: **not adopted**. Owner approval required before any adoption (Epic #89, test framework decision).
- Context: we need fast failure, readable diagnostics and CI output across ~60 scripts, mixed domain and scene tests, and a gate that runs the exact pinned Godot 4.7.2.
- Option A, keep `Check` (this change): ~90 lines, no addon, works with the existing gate and `--script` runner. Gives fast failure and file:line. Does not give test discovery, parameterised tests, mocks or a runner UI.
- Option B, GdUnit4 or GUT: richer runner, discovery and assertions. Each needs an addon pinned to a Godot version, its own runner and output format, and the gate would need rewriting around it. Not evaluated against Godot 4.7.2 here; if we revisit it, measure first.
- Decision for now: keep `Check`. Revisit when the number of tests makes discovery and parameterisation worth an addon.
