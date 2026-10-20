extends SceneTree
const NativeRouteChecks=preload("res://tests/native_route_checks.gd")

# A genuine driven return trip from Market approaches the garage zebra from
# the opposite road direction. Unlike the pure-world test, this loads the
# actual Player Mode scene and its native pedestrian actor.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var returning_world: SandboxWorld = null
	# Pick an actual seeded world with an available garage resident after
	# completing an ordinary outward journey; never forge a NPC or route.
	for seed in range(8,16):
		var candidate_world: SandboxWorld=SandboxWorld.new(seed)
		assert(candidate_world.reposition("market","margin_gate"))
		assert(NativeRouteChecks.finish(candidate_world))
		assert(candidate_world.player_district=="market" and not candidate_world.is_travelling())
		assert(candidate_world.reposition("garage","margin_gate"))
		for i in range(candidate_world.remaining_minutes):
			if SandboxStreetRouteBinding.on_edge(candidate_world):
				break
			assert(candidate_world.advance(1))
		if SandboxStreetRouteBinding.on_edge(candidate_world) \
				and not SandboxLocalPedestrianTrip.candidate(candidate_world).is_empty():
			returning_world=candidate_world
			break
	assert(returning_world!=null,"No seeded world had a real walker for a return-leg traffic test")
	assert(returning_world.route_nodes[returning_world.route_segment]=="margin_gate")
	assert(returning_world.route_nodes[returning_world.route_segment+1]=="garage")
	assert(SandboxStreetRouteBinding.in_neighborhood(returning_world))

	var scene: Node2D=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	# Scene uses the complete world that actually drove Market -> Patchworks.
	scene._world=returning_world
	scene._city.world=returning_world
	scene._process(0.1)
	assert(scene._street_pilot!=null,
			"Reverse approach must instantiate a native walker before the crosswalk")
	assert(scene._street_pilot.world==returning_world)
	var walker: SandboxPedestrianActor=scene._street_pilot.pedestrian
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
	assert(found_hold,"Returning player taxi never yielded to a real native walker")
	assert(SandboxStreetRouteBinding.on_edge(scene._world))
	var saved_position: Vector3=scene._world.player_position()
	var remaining: int=scene._world.remaining_minutes
	scene._on_save()
	scene._on_load()
	assert(scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	assert(scene._street_pilot!=null and scene._street_pilot.pedestrian.crossing_reserved)
	assert(scene._world.player_position().is_equal_approx(saved_position))
	var restored_walker: SandboxPedestrianActor=scene._street_pilot.pedestrian
	restored_walker.set_physics_process(false)
	restored_walker.position=Vector2(SandboxStreetModule.CROSS_X,SandboxStreetModule.LANE_Y)
	scene._process(2.0)
	assert(scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	assert(scene._world.remaining_minutes==remaining)
	# The completion flag alone never releases the returning taxi.
	restored_walker.crossing_completed=true
	scene._process(1.0)
	assert(scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	restored_walker.position=Vector2(SandboxStreetModule.CROSS_X,
			SandboxStreetModule.crossing_clear_y())
	scene._process(1.0)
	assert(scene._world.route_hold_id.is_empty())
	assert(scene._world.remaining_minutes<remaining)
	assert(not scene._world.player_position().is_equal_approx(saved_position))
	assert(NativeRouteChecks.finish(scene._world))
	assert(scene._world.player_district=="garage" and not scene._world.is_travelling())
	var starts: int=0
	var ends: int=0
	for evt in scene._world.events:
		if evt["kind"]=="taxi_yield_started": starts+=1
		if evt["kind"]=="taxi_yield_ended": ends+=1
	assert(starts==1 and ends==1)
	print("TAXI_CROSSING_RETURN_SCENE_PASS real market-to-garage trip, native walker, reverse yield, held save and physical release")
	quit()
