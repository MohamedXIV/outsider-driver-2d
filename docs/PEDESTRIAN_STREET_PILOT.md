# Patchworks street-navigation pilot — implementation in progress

This **bounded standalone proof scene** is opened as `res://scenes/street_pilot.tscn`. It is **not yet the city-wide runtime navigation system**, and is intentionally not the default playable game scene.

## What is real in the proof
- Godot `NavigationRegion2D` with two distinct manually authored `NavigationPolygon` sidewalks. Vehicle pavement is NOT part of pedestrian polygons.
- `NavigationLink2D` crossing at the **only** marked zebra crossing.
- Actual `CharacterBody2D` resident with `NavigationAgent2D` and built-in local avoidance; the script applies velocity via Godot physics.
- A physical prototype `CharacterBody2D` car on a lane; yielding is governed by an explicit crossing rule rather than arbitrary navmesh traversal.
- One real `SandboxWorld` seeded resident (`npc:07`, garage home) is given a local parts-counter errand and reports real arrival to the same world, which validates intent and commits one provenance event. This is a **test fixture**, not a fixed first passenger or automatic city-wide errand.
- Simple orthogonal pavement, frontage/building blocks and crossing markers to validate the modular street-building approach from #58.

## What is NOT implemented
- Migration of all existing autonomous walking residents away from `SandboxRoads.position_on_path`.
- Integration of this actor into the normal `sandbox.tscn` drive/pickup flow; persistent mid-walk physics position serialization and near/far ownership handoff.
- Complete taxi physics/lane movement, complex intersection controls, signals, crowd avoidance or traffic simulation.
- No runtime gates have been claimed passed solely because the code is present. Run `tests/test_street_pilot_scene.gd` with a matching Godot 4.7.2 editor and native renderer before promotion.

## Next increment
After actual native visual proof, derive the sidewalk polygons, road lanes and crosswalk links from reusable street modules, integrate a resident's genuine world-generated pedestrian goal into the main scene, and ensure physics arrival is authoritative for nearby walkers. Preserve cheap off-screen schedules for distant residents and avoid frame-rate dependent economic randomness.

Feedback: [#59](https://github.com/MohamedXIV/outsider-driver-2d/issues/59), [#60](https://github.com/MohamedXIV/outsider-driver-2d/issues/60), [#58](https://github.com/MohamedXIV/outsider-driver-2d/issues/58), [#57](https://github.com/MohamedXIV/outsider-driver-2d/issues/57).
