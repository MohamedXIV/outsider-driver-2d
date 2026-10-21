extends SceneTree

# Two actual world-owned trips (player taxi + independently departing
# resident shuttle) approach the same grounded zebra concurrently.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene._process(scene.REAL_SECONDS_PER_STEP)
	assert(scene._street_pilot!=null)
	var walker: SandboxPedestrianActor=scene._street_pilot.pedestrian
	walker.position=Vector2(SandboxStreetModule.CROSS_X,
			SandboxStreetModule.NORTH_Y+6.0)
	walker.crossing_reserved=true
	walker.crossing_completed=false
	walker.set_physics_process(false)
	walker._agent.avoidance_enabled=false
	var shuttle_id: String=""
	for i in range(90):
		for npc in scene._world.residents:
			if npc.get("transit_method","")=="shuttle" \
					and int(npc["transit_started"])==scene._world.minute \
					and SandboxStreetRouteBinding.crossing_fraction(
							str(npc["transit_nodes"][0]),str(npc["transit_nodes"][1]))>=0.0:
				shuttle_id=str(npc["id"])
				break
		if not shuttle_id.is_empty():break
		scene._process(1.0)
	assert(not shuttle_id.is_empty(),"A legitimate concurrent shuttle did not depart")
	assert(scene._world.reposition("market","margin_gate"))
	assert(SandboxStreetRouteBinding.on_edge(scene._world))
	var both_held: bool=false
	for i in range(20):
		scene._process(1.0)
		if scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID \
				and scene._world.resident(shuttle_id).get("transit_hold_crossing","")==SandboxStreetRouteBinding.CROSSING_ID:
			both_held=true
			break
	assert(both_held,"Player and real shuttle did not independently yield at the same zebra")
	assert(SandboxWorld.new().restore_snapshot(scene._world.snapshot()))
	var independent: SandboxWorld=SandboxWorld.new()
	assert(independent.restore_snapshot(scene._world.snapshot()))
	assert(independent.release_shuttle_crossing_yield(shuttle_id))
	assert(independent.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	assert(SandboxWorld.new().restore_snapshot(independent.snapshot()),"One real leader releasing must not invalidate the other independently held source")
	var forged: Dictionary=scene._world.snapshot()
	for event in forged["events"]:
		if event["kind"]=="taxi_yield_started": event["detail"].erase("execution")
	assert(not SandboxWorld.new().restore_snapshot(forged),"Early queue holds require the original source/pose evidence in their World event")
	forged=scene._world.snapshot()
	forged["vehicle_execution"].erase("player")
	assert(not SandboxWorld.new().restore_snapshot(forged),"An early physical queue hold requires its genuine native execution source")
	# Unrelated NPC animation must keep fractional progress while these two
	# real trips yield. Each held actor already clamps its own fraction.
	scene._elapsed=0.0
	scene._process(0.25)
	assert(is_equal_approx(scene._city.visual_fraction,0.25),
			"Taxi yield must not freeze the shared NPC render clock")
	var player_point: Vector3=scene._world.player_position()
	var npc_point: Vector3=scene._world.npc_position(scene._world.resident(shuttle_id))
	var remaining: int=scene._world.remaining_minutes
	var arrival: int=int(scene._world.resident(shuttle_id)["transit_until"])
	scene._process(2.0)
	assert(scene._world.player_position().is_equal_approx(player_point))
	assert(scene._world.npc_position(scene._world.resident(shuttle_id)).is_equal_approx(npc_point))
	assert(scene._world.remaining_minutes==remaining)
	assert(int(scene._world.resident(shuttle_id)["transit_until"])==arrival+2)
	scene._on_save()
	scene._on_load()
	assert(scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	assert(scene._world.resident(shuttle_id)["transit_hold_crossing"]==SandboxStreetRouteBinding.CROSSING_ID)
	var restored: SandboxPedestrianActor=scene._street_pilot.pedestrian
	restored.set_physics_process(false)
	restored.crossing_completed=true
	restored.position=Vector2(SandboxStreetModule.CROSS_X,SandboxStreetModule.LANE_Y)
	scene._process(1.0)
	assert(scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	assert(scene._world.resident(shuttle_id)["transit_hold_crossing"]==SandboxStreetRouteBinding.CROSSING_ID)
	restored.position=Vector2(SandboxStreetModule.CROSS_X,SandboxStreetModule.crossing_clear_y())
	scene._process(1.0)
	assert(scene._world.route_hold_id.is_empty())
	assert(scene._world.resident(shuttle_id)["transit_hold_crossing"]=="")
	assert(scene._world.player_position().distance_to(player_point)>0.001)
	assert(scene._world.npc_position(scene._world.resident(shuttle_id)).distance_to(npc_point)>0.001)
	assert(SandboxWorld.new().restore_snapshot(scene._world.snapshot()))
	var taxi_starts: int=0
	var taxi_ends: int=0
	var shuttle_starts: int=0
	var shuttle_ends: int=0
	for evt in scene._world.events:
		match str(evt["kind"]):
			"taxi_yield_started": taxi_starts+=1
			"taxi_yield_ended": taxi_ends+=1
			"npc_shuttle_yield_started":
				if evt["subject"]==shuttle_id:shuttle_starts+=1
			"npc_shuttle_yield_ended":
				if evt["subject"]==shuttle_id:shuttle_ends+=1
	assert(taxi_starts==1 and taxi_ends==1 and shuttle_starts==1 and shuttle_ends==1)
	print("SHARED_CROSSING_PRIORITY_SCENE_PASS real taxi and world shuttle co-yield, independent held clocks, restore, physical clearance and matched ledgers")
	quit()
