extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	scene._world=SandboxWorld.new(29);scene._city.world=scene._world;scene._process(.1)
	for actor in scene._street_pilot.pedestrians.values():
		actor.set_physics_process(false);actor._agent.avoidance_enabled=false
		actor.position=Vector2(312 if actor.slot==0 else 328,350);actor.crossing_reserved=true
	assert(scene._world.reposition("market","margin_gate"))
	scene._on_wait()
	assert(not scene._world.route_hold_id.is_empty(),"Manual Wait must reconcile crossing priority at every world tick")
	var at: Vector3=scene._world.player_position()
	scene._on_observe()
	assert(scene._world.player_position().is_equal_approx(at))
	var held: bool=false
	for npc in scene._world.residents:
		if npc.get("transit_hold_crossing","")==SandboxStreetRouteBinding.CROSSING_ID: held=true
	assert(held,"Manual observation must also hold genuinely generated world-owned shuttles")
	assert(SandboxWorld.new().restore_snapshot(scene._world.snapshot()))
	print("MANUAL_TIME_CROSSING_PASS Wait/Observe share per-tick taxi and genuine shuttle crossing priority")
	quit()
