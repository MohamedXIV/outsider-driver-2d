extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	for medical in [false,true]:
		if not await _case(medical): quit(1);return
	print("WORLD_VEHICLE_HORIZON_PASS bounded physical budget brakes to rest and resumes only after the World commits")
	quit()

func _case(medical: bool) -> bool:
	var world: SandboxWorld=SandboxWorld.new(9 if medical else 8)
	if medical:
		var offer: Dictionary={}
		for candidate in world.open_offers():
			if candidate["origin"]=="garage" and SandboxPassengerAlight.applicable(candidate): offer=candidate;break
		assert(not offer.is_empty() and world.accept(str(offer["id"])))
	else: assert(world.reposition("market","margin_gate"))
	var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(body);assert(body.bind(world,"player"))
	await physics_frame
	var previous: float=0.0
	var last: Vector2=body.position
	for frame in range(300):
		assert(body.step(1.0/60.0))
		var speed: float=float(world.vehicle_execution["player"]["speed"])
		assert(previous-speed<=SandboxVehicleKinematics.SERVICE_BRAKE/60.0+.001)
		previous=speed
		if frame==298: last=body.position
		await physics_frame
	assert(body.position.distance_to(last)<.001)
	if previous>.05:
		push_error("The taxi is stationary at its World execution limit but reports nonzero physical speed");return false
	assert(world.minute==SandboxWorld.START_MINUTE and SandboxWorld.new().restore_snapshot(world.snapshot()))
	assert(world.advance_elapsed(1))
	for frame in range(60):
		assert(body.step(1.0/60.0));await physics_frame
	assert(body.position.distance_to(last)>1.0)
	body.release(0.0);body.queue_free();await physics_frame
	return true
