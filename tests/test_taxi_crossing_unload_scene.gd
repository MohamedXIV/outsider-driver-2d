extends SceneTree

# Fault-inject a native actor unloading DURING the player's real route hold.
# The world-owned local trip and its offscreen position, not the missing node,
# must determine if/when the taxi can resume.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene._process(scene.REAL_SECONDS_PER_STEP)
	assert(scene._street_pilot!=null)
	assert(scene._world.reposition("market","margin_gate"))
	var walker: SandboxPedestrianActor=scene._street_pilot.pedestrian
	var npc_id: String=scene._street_pilot.walking_npc_id
	# Crossing is occupied near the NORTH asphalt edge, so one minute of
	# coarse offscreen movement does not yet clear the south-bound body.
	walker.position=Vector2(SandboxStreetModule.CROSS_X,
			SandboxStreetModule.ROAD.position.y+1.0)
	walker.crossing_reserved=true
	walker.crossing_completed=false
	walker.set_physics_process(false)
	walker._agent.avoidance_enabled=false
	var held: bool=false
	for i in range(25):
		scene._process(1.0)
		if not scene._world.route_hold_id.is_empty():
			held=true
			break
	assert(held)
	var remaining: int=scene._world.remaining_minutes
	var position: Vector3=scene._world.player_position()
	var progress: float=SandboxStreetModule.progress_of(walker.position)
	assert(not SandboxStreetModule.crossing_finished(progress))
	assert(not SandboxLocalPedestrianTrip.crossing_cleared_without_actor(scene._world),
			"A live world walker must block even if its native node disappears")
	assert(SandboxLocalPedestrianTrip.handoff(scene._world,npc_id,progress))
	assert(scene._world.resident(npc_id)["local_pedestrian_trip"]["status"]=="offscreen")
	assert(not SandboxLocalPedestrianTrip.crossing_cleared_without_actor(scene._world))
	scene._reset_local_pedestrian()
	assert(scene._street_pilot==null)
	scene._update_player_crossing_yield()
	assert(scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID,
			"Missing native actor incorrectly released a physically occupied crossing")
	assert(scene._world.remaining_minutes==remaining)
	assert(scene._world.player_position().is_equal_approx(position))
	var saved: SandboxWorld=SandboxWorld.new()
	assert(saved.restore_snapshot(scene._world.snapshot()),
			"An unloaded pedestrian and held taxi must survive world restore")
	assert(saved.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	assert(scene._world.advance(1))
	var coarse: float=SandboxLocalPedestrianTrip.offscreen_progress(scene._world,npc_id)
	assert(coarse>progress)
	assert(not SandboxStreetModule.crossing_finished(coarse),
			"One coarse minute should not clear this near-edge walker")
	assert(not SandboxLocalPedestrianTrip.crossing_cleared_without_actor(scene._world))
	scene._update_player_crossing_yield()
	assert(scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	# The same resident gets a new native actor when the loaded area is
	# reconciled, without fabricating a second world record or losing hold.
	scene._sync_local_pedestrian()
	assert(scene._street_pilot!=null)
	assert(scene._street_pilot.walking_npc_id==npc_id)
	assert(scene._street_pilot.world==scene._world)
	assert(scene._world.resident(npc_id)["local_pedestrian_trip"]["status"]=="walking")
	assert(not SandboxStreetModule.crossing_clear(scene._street_pilot.pedestrian.position))
	scene._street_pilot.pedestrian.set_physics_process(false)
	scene._process(1.0)
	assert(scene._world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	assert(scene._world.remaining_minutes==remaining)
	# Physical completion after reloading finally resumes this exact taxi.
	scene._street_pilot.pedestrian.position=Vector2(SandboxStreetModule.CROSS_X,
			SandboxStreetModule.crossing_clear_y())
	scene._street_pilot.pedestrian.crossing_completed=true
	scene._process(1.0)
	assert(scene._world.route_hold_id.is_empty())
	assert(scene._world.remaining_minutes<remaining)
	assert(not scene._world.player_position().is_equal_approx(position))
	var starts: int=0
	var ends: int=0
	for event in scene._world.events:
		if event["kind"]=="taxi_yield_started": starts+=1
		if event["kind"]=="taxi_yield_ended": ends+=1
	assert(starts==1 and ends==1)
	assert(saved.restore_snapshot(scene._world.snapshot()))

	# World-only clearance while no actor exists: a truly completed coarse
	# crossing may clear the hold, but a partially crossed NPC may not.
	var coarse_world: SandboxWorld=SandboxWorld.new(8)
	var other_id: String=SandboxLocalPedestrianTrip.candidate(coarse_world)
	assert(not other_id.is_empty())
	assert(SandboxLocalPedestrianTrip.begin(coarse_world,other_id,
			SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	assert(SandboxLocalPedestrianTrip.handoff(coarse_world,other_id,progress))
	assert(not SandboxLocalPedestrianTrip.crossing_cleared_without_actor(coarse_world))
	assert(coarse_world.advance(2))
	assert(SandboxLocalPedestrianTrip.crossing_cleared_without_actor(coarse_world))
	assert(SandboxWorld.new().restore_snapshot(coarse_world.snapshot()))
	print("TAXI_CROSSING_UNLOAD_SCENE_PASS missing actor guarded, offscreen progress, one world resident, native reload and held route continuation")
	quit()
