extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(world.reposition("market","margin_gate"))
	var corridor: SandboxWorldVehicleCorridor=SandboxWorldVehicleCorridor.new()
	root.add_child(corridor)
	corridor.attach(world)
	assert(corridor.bodies.has("player"))
	await physics_frame
	var initial: Vector2=corridor.bodies["player"].position
	for frame in range(60):
		corridor.step(1.0/60.0)
		world.vehicle_fraction=float(frame+1)/60.0 if frame<59 else 0.0
		await physics_frame
	assert(corridor.bodies["player"].position.distance_to(initial)>1.0)
	assert(world.advance_elapsed(1))
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	var copy: SandboxWorld=SandboxWorld.new()
	assert(copy.restore_snapshot(world.snapshot()))
	var saved: Vector2=corridor.bodies["player"].position
	corridor.attach(copy)
	assert(corridor.bodies["player"].position.distance_to(saved)<.001)
	assert(not world.vehicle_executor.is_valid())
	assert(copy.vehicle_executor.is_valid())
	assert(copy.advance(2))
	assert(SandboxWorld.new().restore_snapshot(copy.snapshot()))
	corridor.queue_free()
	await process_frame
	assert(not copy.vehicle_executor.is_valid())
	print("WORLD_VEHICLE_CORRIDOR_PASS automatic genuine ID, execution, exact reload, old World detach, canonical time skip")
	quit()
