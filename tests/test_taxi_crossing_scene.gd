extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node2D=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene._process(0.1)
	assert(scene._street_pilot!=null)
	var zebra: Vector2=scene._street_pilot.to_global(Vector2(
			SandboxStreetModule.CROSS_X,SandboxStreetModule.LANE_Y))
	assert(zebra.distance_to(SandboxStreetRouteBinding.crossing_position())<0.01)
	assert(scene._world.reposition("market","margin_gate"))
	scene._sync_local_pedestrian()
	assert(scene._street_pilot!=null, "Nearby physical pedestrian must stay loaded during road approach")
	var walker: SandboxPedestrianActor=scene._street_pilot.pedestrian
	# Simulate a pedestrian physically COMMITTED to this crossing. Freeze only
	# the test pedestrian's controller to guarantee a multi-tick driver wait;
	# real active crossing is covered by the street pilot scene test.
	walker.position=Vector2(SandboxStreetModule.CROSS_X,SandboxStreetModule.NORTH_Y+6)
	walker.crossing_reserved=true
	walker.crossing_completed=false
	walker.set_physics_process(false)
	walker._agent.avoidance_enabled=false
	var found_hold: bool=false
	for i in range(25):
		scene._process(1.0)
		if not scene._world.route_hold_id.is_empty():
			found_hold=true
			break
	assert(found_hold,"Taxi did not yield on the actual route edge")
	assert(scene._street_pilot!=null)
	assert(SandboxStreetRouteBinding.on_edge(scene._world))
	var point: Vector3=scene._world.player_position()
	var remaining: int=scene._world.remaining_minutes
	scene._on_save()
	scene._on_load()
	assert(scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	assert(scene._street_pilot!=null)
	assert(scene._street_pilot.pedestrian.crossing_reserved)
	assert(scene._world.player_position().is_equal_approx(point))
	scene._street_pilot.pedestrian.set_physics_process(false)
	scene._process(2.0)
	assert(scene._world.remaining_minutes==remaining)
	assert(scene._world.player_position().is_equal_approx(point))
	assert(scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	# Finish the pedestrian's physical crossing, then the REAL taxi resumes.
	scene._street_pilot.pedestrian.crossing_completed=true
	scene._process(1.0)
	assert(scene._world.route_hold_id.is_empty())
	assert(scene._world.remaining_minutes<remaining)
	assert(not scene._world.player_position().is_equal_approx(point))
	var starts: int=0
	var ends: int=0
	for evt in scene._world.events:
		if evt["kind"]=="taxi_yield_started": starts+=1
		if evt["kind"]=="taxi_yield_ended": ends+=1
	assert(starts==1 and ends==1)
	print("TAXI_CROSSING_SCENE_PASS actual player ride yields to native pedestrian at a world-aligned crossing and persists")
	quit()
