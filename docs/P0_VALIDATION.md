# P0 Evidence and Validation

## Currently executed
Not yet run. A targeted GitHub Actions smoke job exists solely because this environment has no local Godot binary, internet downloads, or active ShellWarden tunnel.

The job imports the project in Godot 4.6.3, runs the domain/projection test script, starts the scene headlessly, and attempts software-rendered PNG capture through Xvfb. The job runs only on relevant changes to the P0 branch, or manually.

**CI execution ≠ game acceptance.** Review resulting images for camera framing, bridge occlusion, taxi position and the ramp. Desktop/Web exports remain separate gates.

### Commands
```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --quit-after 90
```

## Visual checks

- Crossing on ground should go *behind* bridge deck but not disappear at unrelated positions.
- Taxi should climb a continuous authored ramp and reappear *above* the bridge.
- Camera follows direction with moderate look-ahead and zooms out at intersections.
- The current placeholders are vector polygons, not final art; visually judge geometry and legibility only.

## Export gates

Browser and desktop builds require official Godot export templates and actual launch/smoke on each target; **neither can be inferred from headless CI**.

See [Issue #1](https://github.com/MohamedXIV/outsider-driver-2d/issues/1).
