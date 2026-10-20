# Controlled native vehicle execution evidence

Runtime source: `1b9cd577f4c5f11eff5891dac55b5b88b60ff384`, Godot 4.7.2, native X11/software rendering. The following documentation/test-only commit contains these captures without changing runtime code.

The observer instantiates the actual sandbox scene, pauses its automatic clock, authorizes a genuine garage→market reposition through margin_gate, and explicitly attaches the new native adapter to the real player ID. The red square is a controlled native collision obstacle, not a resident or fare. Five chronological samples show entry, acceleration, held position, the same position after World snapshot restore, and departure after obstacle removal. These are sampled frames of the controlled run, not five adjacent rendered frames or human acceptance.

`frames.json` records the genuine source event, World minute, population, canonical World position, render position, native body position, speed and heading. The held and restored samples coincide; World time advances while the original 23 planned route minutes remain unchanged. Native execution makes progress after obstacle removal. Population stays nine. This is a real reposition, not a passenger-fare playthrough.

Reproduce using `godot --path . --script docs/evidence/r05-world-execution/native-collision/observer.gd` with a native display; captures go to `work/vehicle-native-frames/`. The automatic production corridor coordinator is **not enabled** by this observer or branch. The default main scene still uses the established deterministic vehicle presentation. Two-fare Chromium acceptance and full milestone completion must be verified after that coordinator is implemented.

`variable-delta.log` records the actual native body braking test at 1/30, 1/60, 1/120 and 0.1 seconds. The formal regression is `tests/test_world_vehicle_delta_scene.gd`.
