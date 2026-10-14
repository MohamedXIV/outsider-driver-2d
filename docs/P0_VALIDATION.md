# P0 Manual Validation Checklist

The initial Godot scene uses **placeholder 2D polygons**, not approved final art.

## Desktop

1. Open `project.godot` in Godot 4.x and run the scene.
2. Confirm the taxi starts on the ground road and camera follows with look-ahead.
3. Confirm the taxi goes **under** the elevated cross-road and is occluded by the bridge deck when appropriate.
4. Confirm it follows the loop and ramp to level +1, then appears **above** the bridge.
5. Confirm visible camera expansion near the crossing. Press `R` to replay.
6. Run `godot --headless --path . --editor --quit` and `godot --headless --path . --script res://tests/test_core.gd`.

## Web

Export through Godot's Compatibility/Web pipeline once official export templates are present, serve on an HTTP server, and repeat steps 2–5 in a browser. Confirm resources load and inputs work.

## Explicit status

Checks in this file are **instructions, not proof of passing**. A reviewer must record actual platform, Godot version, rendered screenshots, command output, and observations before P0 closure.

Upcoming: real authored road pieces, passenger presentation and Ink integration. None are claimed implemented by this P0 draw-proof.
