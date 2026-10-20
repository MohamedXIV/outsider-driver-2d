extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(world.reposition("docks","clinic"))
	assert(world.advance(41))
	var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(body)
	assert(body.bind(world,"player"))
	await physics_frame
	var restored: bool=false
	for frame in range(240):
		var old_heading: float=body.rotation
		assert(body.step(1.0/60.0))
		assert(absf(angle_difference(SandboxCityView.world_road_heading(world),body.rotation))<.001,"Renderer must read the saved physical heading")
		assert(absf(angle_difference(old_heading,body.rotation))<=SandboxVehicleKinematics.TURN_RATE/60.0+.0001)
		var progress: float=float(world.vehicle_execution["player"]["progress"])
		if not restored and progress>42.5:
			var copy: SandboxWorld=SandboxWorld.new()
			assert(copy.restore_snapshot(world.snapshot()))
			var old_position: Vector2=body.position
			var old_rotation: float=body.rotation
			body.queue_free()
			await physics_frame
			world=copy
			body=SandboxWorldVehicleBody.new()
			root.add_child(body)
			assert(body.bind(world,"player"))
			assert(body.position.distance_to(old_position)<.001)
			assert(absf(angle_difference(body.rotation,old_rotation))<.001)
			restored=true
		if (frame+1)%60==0: assert(world.advance_elapsed(1))
		await physics_frame
	assert(restored)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	assert(world.vehicle_junctions.is_empty())
	print("WORLD_VEHICLE_TURN_PASS true route, bounded native heading, saved connector, exact pose rebind, cleared reservation")
	quit()
