extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var world: SandboxWorld=SandboxWorld.new(9)
	var offer: Dictionary={}
	for item in world.open_offers():
		if item["origin"]=="garage" and SandboxPassengerAlight.applicable(item): offer=item;break
	assert(not offer.is_empty() and world.accept(str(offer["id"])))
	assert(world.advance(world.remaining_minutes-2))
	var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(body);assert(body.bind(world,"player"))
	var travel: Dictionary=SandboxVehicleExecution.trip(world,"player")
	var total: float=SandboxRoads.path_minutes(SandboxVehicleExecution.nodes_of(travel))
	var target: Vector2=SandboxVehicleExecution.point(travel,total)
	var previous: float=0.0
	var reached: bool=false
	await physics_frame
	for frame in range(600):
		if not body.step(1.0/60.0):
			push_error("Body failed before reaching its actual route goal");quit(1);return
		var state: Dictionary=world.vehicle_execution["player"]
		var speed: float=float(state["speed"])
		assert(speed-previous<=SandboxVehicleKinematics.ACCELERATION/60.0+.001)
		assert(previous-speed<=SandboxVehicleKinematics.SERVICE_BRAKE/60.0+.001)
		previous=speed
		if float(state["progress"])+SandboxVehicleExecution.EPSILON>=total:
			if speed>.05:
				push_error("A vehicle at its goal must report a stopped physical speed; got "+str(speed))
				quit(1);return
			reached=true;break
		if (frame+1)%60==0: assert(world.advance_elapsed(1))
		await physics_frame
	assert(reached)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	assert(world.advance_elapsed(world.remaining_minutes))
	assert(not world.is_travelling())
	assert(SandboxCityView.project(world.player_position()).distance_to(target)<.001,"World must retain the real parked pose")
	assert(SandboxDirectedLanes.taxi_screen(world,.6).distance_to(target)<.001)
	assert(world.events.filter(func(event: Dictionary)->bool:return event["kind"]=="fare_settled" and event["subject"]==offer["id"]).size()==1)
	var parked_heading: float=body.rotation
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	var bad: Dictionary=world.snapshot()
	bad["vehicle_parking"]["player"]["x"]+=20.0
	assert(not SandboxWorld.new().restore_snapshot(bad))
	bad=world.snapshot();bad["vehicle_parking"]={}
	assert(not SandboxWorld.new().restore_snapshot(bad))
	body.queue_free();await physics_frame
	assert(world.reposition("garage","margin_gate"))
	var departing: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new();root.add_child(departing)
	assert(departing.bind(world,"player"))
	assert(departing.position.distance_to(target)<.001)
	assert(absf(angle_difference(departing.rotation,parked_heading))<.001,"A new trip must start from the real parked heading")
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	print("WORLD_VEHICLE_ARRIVAL_PASS gradual terminal braking, saved stop, one genuine settlement")
	quit()
