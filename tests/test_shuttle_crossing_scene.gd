extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene._process(scene.REAL_SECONDS_PER_STEP)
	assert(scene._street_pilot!=null,"Player Mode needs a genuine local resident")
	var walker: SandboxPedestrianActor=scene._street_pilot.pedestrian
	walker.position=Vector2(SandboxStreetModule.CROSS_X,
			SandboxStreetModule.NORTH_Y+6.0)
	walker.crossing_reserved=true
	walker.crossing_completed=false
	walker.set_physics_process(false)
	walker._agent.avoidance_enabled=false
	var target: String=""
	for i in range(100):
		scene._process(1.0)
		for npc in scene._world.residents:
			if npc.get("transit_hold_crossing","")==SandboxStreetRouteBinding.CROSSING_ID:
				target=str(npc["id"])
				break
		if not target.is_empty(): break
	assert(not target.is_empty(),"Live Player Mode failed to hold the genuine world shuttle")
	var npc: Dictionary=scene._world.resident(target)
	var point: Vector3=scene._world.npc_position(npc)
	var arrive_at: int=int(npc["transit_until"])
	scene._process(3.0)
	assert(scene._world.npc_position(scene._world.resident(target)).is_equal_approx(point))
	assert(int(scene._world.resident(target)["transit_until"])==arrive_at+3)
	# Mid-yield scene persistence must not desynchronize the world ledger.
	scene._on_save()
	scene._on_load()
	assert(scene._world.resident(target)["transit_hold_crossing"]==SandboxStreetRouteBinding.CROSSING_ID)
	assert(scene._world.npc_position(scene._world.resident(target)).is_equal_approx(point))
	var loaded: SandboxPedestrianActor=scene._street_pilot.pedestrian
	loaded.set_physics_process(false)
	loaded.crossing_completed=true
	loaded.position=Vector2(SandboxStreetModule.CROSS_X,SandboxStreetModule.LANE_Y)
	scene._process(1.0)
	assert(scene._world.resident(target)["transit_hold_crossing"]==SandboxStreetRouteBinding.CROSSING_ID)
	loaded.position=Vector2(SandboxStreetModule.CROSS_X,SandboxStreetModule.crossing_clear_y())
	scene._process(1.0)
	assert(scene._world.resident(target)["transit_hold_crossing"]=="")
	assert(scene._world.npc_position(scene._world.resident(target)).distance_to(point)>0.001)
	assert(SandboxWorld.new().restore_snapshot(scene._world.snapshot()))
	print("SHUTTLE_CROSSING_SCENE_PASS real Player Mode shuttle hold, scene restore, body clearance and resumed world route")
	quit()
