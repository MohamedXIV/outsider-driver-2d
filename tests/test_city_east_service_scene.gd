extends SceneTree

# Actual CharacterBody entry on the new corridor, with one World clock and
# restored native physical pose. Pure route geometry alone is not enough.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var world: SandboxWorld = SandboxWorld.new(8)
    assert(world.reposition("terraces", "east_ramp_foot"))
    var target_segment: int = world.route_nodes.find("east_service")
    assert(target_segment >= 0)
    for minute in range(180):
        if world.route_segment >= target_segment:
            break
        assert(world.is_travelling() and world.advance(1))
    assert(world.is_travelling() and world.route_segment == target_segment)
    assert(world.route_nodes[world.route_segment + 1] == "east_ramp_foot")

    var corridor: SandboxWorldVehicleCorridor = SandboxWorldVehicleCorridor.new()
    root.add_child(corridor)
    corridor.attach(world)
    await physics_frame
    assert(corridor.bodies.has("player"), "Real new road must admit native taxi")
    var start: Vector2 = corridor.bodies["player"].position
    assert(start.is_finite())
    for frame in range(60):
        corridor.step(1.0 / 60.0)
        world.vehicle_fraction = float(frame + 1) / 60.0 if frame < 59 else 0.0
        await physics_frame
    var moved: Vector2 = corridor.bodies["player"].position
    assert(moved.is_finite() and moved.distance_to(start) > 1.0,
        "Native taxi must physically advance along the service lane")
    assert(world.advance_elapsed(1))
    var copy: SandboxWorld = SandboxWorld.new()
    assert(copy.restore_snapshot(world.snapshot()),
        "New metric edge must retain valid mid-journey state")
    corridor.attach(copy)
    assert(corridor.bodies.has("player"))
    assert(corridor.bodies["player"].position.distance_to(moved) < .01,
        "Native taxi restore must preserve its exact actual road pose")
    assert(copy.route_nodes.has("east_ramp_top") and copy.is_travelling())
    corridor.queue_free()
    await process_frame
    print("CITY_EAST_SERVICE_SCENE_PASS authentic taxi body, service segment, native restoration")
    quit()
