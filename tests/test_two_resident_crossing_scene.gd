extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene);scene.set_process(false)
	scene._world=SandboxWorld.new(29);scene._city.world=scene._world;scene._process(scene.REAL_SECONDS_PER_STEP)
	var pilot: SandboxStreetPilot=scene._street_pilot
	assert(pilot.pedestrians.size()==2)
	for actor in pilot.pedestrians.values():
		actor.set_physics_process(false);actor._agent.avoidance_enabled=false
		actor.position=Vector2(312 if actor.npc_id=="npc:04" else 328,319);actor.crossing_reserved=true
	# Independent real shuttle departure, produced by offer expiry/routines.
	var shuttle_id: String=""
	for minute in range(400):
		for npc in scene._world.residents:
			if npc.get("transit_hold_crossing","")==SandboxStreetRouteBinding.CROSSING_ID:
				shuttle_id=str(npc["id"]);break
		if not shuttle_id.is_empty(): break
		scene._process(1.0)
	assert(not shuttle_id.is_empty(),"Seeded world must produce a genuine shuttle through this road")
	assert(scene._world.reposition("market","margin_gate"))
	for minute in range(15):
		scene._process(1.0)
		if not scene._world.route_hold_id.is_empty(): break
	assert(not scene._world.route_hold_id.is_empty())
	pilot.pedestrians["npc:04"].position=Vector2(312,390)
	pilot.pedestrians["npc:04"].crossing_completed=true
	scene._process(1.0)
	assert(not scene._world.route_hold_id.is_empty() and not scene._world.resident(shuttle_id)["transit_hold_crossing"].is_empty(),"A staggered second reservation must retain both vehicle holds")
	pilot.pedestrians["npc:08"].position=Vector2(328,350)
	pilot.pedestrians["npc:08"].crossing_completed=true # stale flag cannot release the remaining body
	var taxi_at: Vector3=scene._world.player_position()
	var shuttle_at: Vector3=scene._world.npc_position(scene._world.resident(shuttle_id))
	scene._process(2.0)
	assert(scene._world.player_position().is_equal_approx(taxi_at))
	assert(scene._world.npc_position(scene._world.resident(shuttle_id)).is_equal_approx(shuttle_at))
	assert(not pilot.cancel_resident("npc:08"),"A pedestrian cannot disappear inside the lane")
	var points: Dictionary={}
	for id in pilot.pedestrians: points[id]=pilot.pedestrians[id].position
	DirAccess.make_dir_recursive_absolute("/tmp/od2d-multi-evidence")
	scene._render()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/od2d-multi-evidence/01-two-resident-hold.png")
	scene._on_save();scene._on_load();pilot=scene._street_pilot
	assert(pilot.pedestrians.size()==2)
	for id in points:
		assert(pilot.pedestrians[id].position.distance_to(points[id])<.01)
		pilot.pedestrians[id].set_physics_process(false);pilot.pedestrians[id]._agent.avoidance_enabled=false
	scene._process(.25)
	assert(not scene._world.route_hold_id.is_empty())
	assert(not scene._world.resident(shuttle_id)["transit_hold_crossing"].is_empty())
	# A missing actor is not a release signal for that resident's reservation.
	var missing: Node=pilot.pedestrians["npc:08"]
	pilot.pedestrians.erase("npc:08");pilot.remove_child(missing)
	scene._process(.25)
	assert(not pilot.pedestrians.has("npc:08"),"Missing native bodies must not respawn at a fabricated start pose")
	assert(not scene._world.route_hold_id.is_empty())
	pilot.add_child(missing);pilot.pedestrians["npc:08"]=missing
	missing.position=Vector2(328,SandboxStreetModule.crossing_clear_y())
	scene._process(1.0)
	assert(scene._world.route_hold_id.is_empty())
	assert(scene._world.resident(shuttle_id)["transit_hold_crossing"]=="")
	assert(SandboxWorld.new().restore_snapshot(scene._world.snapshot()))
	# Per-ID spatial anchors survive an unload and same-minute reload exactly.
	# Use the presenter's actual handoff boundary without altering world route provenance.
	pilot.handoff_all()
	var state: Dictionary=pilot.visual_snapshot()
	var world: SandboxWorld=scene._world
	pilot.queue_free();scene._street_pilot=null
	await process_frame
	for id in points: assert(world.resident(id)["local_pedestrian_trip"]["status"]=="offscreen")
	var resumed: SandboxStreetPilot=SandboxStreetPilot.new();resumed.world=world;resumed.embedded=true
	root.add_child(resumed)
	for id in points:
		assert(resumed.pedestrians[id].position.distance_to(Vector2(state["actors"][id]["pedestrian_x"],state["actors"][id]["pedestrian_y"]))<.01)
	# A safely waiting reservation may be cancelled independently of its peer.
	resumed.pedestrians["npc:08"].position=Vector2(300,313)
	assert(resumed.cancel_resident("npc:08"))
	world.advance(12)
	assert(not SandboxLocalPedestrianTrip.arrive(world,"npc:08",SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	print("TWO_RESIDENT_CROSSING_PASS real taxi and real shuttle, all-body release, stale flags, save, missing actor, per-ID handoff and cancellation")
	quit()
