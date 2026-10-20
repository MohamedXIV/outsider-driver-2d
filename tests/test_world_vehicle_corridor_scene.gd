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
	# A pre-physics v12 hold has no native pose provenance. Keep its existing
	# projection until pedestrian clearance; then enter without a visual jump.
	var legacy: SandboxWorld=SandboxWorld.new(8)
	assert(legacy.reposition("market","margin_gate"))
	while not SandboxStreetRouteBinding.approaching(legacy): assert(legacy.advance(1))
	assert(legacy.begin_crossing_yield() and legacy.vehicle_execution.is_empty())
	var projected: Vector2=SandboxDirectedLanes.taxi_screen(legacy,0.0)
	var legacy_corridor: SandboxWorldVehicleCorridor=SandboxWorldVehicleCorridor.new()
	root.add_child(legacy_corridor);legacy_corridor.attach(legacy)
	assert(not legacy_corridor.bodies.has("player"),"A legacy held projection must not materialize a blocking body on the reserved paint")
	assert(legacy.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID and SandboxDirectedLanes.taxi_screen(legacy,0.0).distance_to(projected)<.001)
	assert(legacy.release_crossing_yield())
	legacy_corridor.reconcile()
	assert(legacy_corridor.bodies.has("player") and legacy_corridor.bodies["player"].position.distance_to(projected)<.001)
	assert(SandboxWorld.new().restore_snapshot(legacy.snapshot()))
	print("WORLD_VEHICLE_CORRIDOR_PASS automatic genuine ID, execution, exact reload, old World detach, canonical time skip")
	quit()
