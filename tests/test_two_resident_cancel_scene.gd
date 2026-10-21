extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene);scene.set_process(false)
	scene._world=SandboxWorld.new(29);scene._city.world=scene._world;scene._process(scene.REAL_SECONDS_PER_STEP)
	var pilot: SandboxStreetPilot=scene._street_pilot
	for actor in pilot.pedestrians.values():
		actor.set_physics_process(false);actor._agent.avoidance_enabled=false;actor.crossing_reserved=true
	pilot.pedestrians["npc:04"].position=Vector2(312,350)
	pilot.pedestrians["npc:08"].position=Vector2(328,313)
	assert(scene._world.reposition("market","margin_gate"))
	for tick in range(15):
		scene._process(1)
		if not scene._world.route_hold_id.is_empty(): break
	assert(not scene._world.route_hold_id.is_empty())
	var at: Vector3=scene._world.player_position()
	assert(pilot.cancel_resident("npc:08"))
	scene._process(1)
	assert(not scene._world.route_hold_id.is_empty() and scene._world.player_position().is_equal_approx(at))
	scene._on_save();scene._on_load();pilot=scene._street_pilot
	assert(pilot.pedestrians.size()==1 and pilot.pedestrians.has("npc:04"))
	assert(scene._world.resident("npc:08")["local_pedestrian_trip"]["status"]=="cancelled")
	pilot.pedestrians["npc:04"].set_physics_process(false)
	pilot.pedestrians["npc:04"]._agent.avoidance_enabled=false
	pilot.pedestrians["npc:04"].position=Vector2(312,390)
	scene._process(1)
	assert(scene._world.route_hold_id.is_empty())
	assert(not SandboxLocalPedestrianTrip.arrive(scene._world,"npc:08",SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	assert(SandboxWorld.new().restore_snapshot(scene._world.snapshot()))
	print("TWO_RESIDENT_CANCEL_PASS safe cancellation releases only its owner, remaining body holds taxi, cancelled identity/save provenance retained")
	quit()
