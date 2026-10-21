extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	# Select a reproducible population, without editing residents or motives.
	scene._world=SandboxWorld.new(29);scene._city.world=scene._world
	var saw_crossing: bool=false
	var saw_adjacent: bool=false
	var did_save: bool=false
	var checked_missing: bool=false
	for frame in range(2400):
		await physics_frame
		var pilot: SandboxStreetPilot=scene._street_pilot
		if pilot==null or pilot.pedestrians.size()!=2: continue
		assert(scene._world.residents.size()==9)
		var first: SandboxPedestrianActor=pilot.pedestrians["npc:04"]
		var second: SandboxPedestrianActor=pilot.pedestrians["npc:08"]
		if not checked_missing:
			# A temporarily missing body has no trusted replacement pose.
			pilot.pedestrians.erase(second.npc_id);pilot.remove_child(second)
			scene._sync_local_pedestrian()
			assert(not pilot.pedestrians.has(second.npc_id), "Missing native bodies must fail closed instead of respawning at START")
			pilot.add_child(second);pilot.pedestrians[second.npc_id]=second
			checked_missing=true
		assert(first.position.distance_to(second.position)>=13.0)
		for actor in [first,second]:
			if actor.position.y>330 and actor.position.y<374:
				assert(absf(actor.position.x-SandboxStreetModule.CROSS_X)<17.0)
				assert(actor.global_position.distance_to(pilot.car.global_position)>13.0)
				saw_crossing=true
				if not did_save:
					pilot.reconcile_reservations()
					var poses: Dictionary=pilot.visual_snapshot()
					var ledger: Array=scene._world.events.duplicate(true)
					scene._on_save();scene._on_load()
					assert(scene._world.events==ledger, "Load must preserve the event ledger exactly")
					for id in poses["actors"]:
						var saved: Dictionary=poses["actors"][id]
						assert(scene._street_pilot.pedestrians[id].position.distance_to(Vector2(saved["pedestrian_x"],saved["pedestrian_y"]))<.001)
					did_save=true
					break
		if did_save and pilot!=scene._street_pilot: continue
		if second.position.x>570: saw_adjacent=true
		if frame%120==0:
			print("LIVING_TRACE minute=",scene._world.minute," first=",first.position," second=",second.position,
				" reserved=",pilot.crossing_occupied()," car=",pilot.car.position," goal=",first.destination," arrived=",first.did_arrive," blocked=",first.path_blocked," next=",first._agent.get_next_path_position()," velocity=",first.velocity," local_next=",pilot.to_local(first._agent.get_next_path_position())," agent_goal=",pilot.to_local(first._agent.target_position)," finished=",first._agent.is_navigation_finished())
		if first.did_arrive and second.did_arrive:
			assert(pilot.car_yielded)
			break
	assert(did_save and saw_crossing and saw_adjacent)
	for id in ["npc:04","npc:08"]:
		assert(scene._world.resident(id)["local_pedestrian_trip"]["status"]=="arrived")
		var departures: int=0
		var arrivals: int=0
		for event in scene._world.events:
			if event["subject"]!=id: continue
			if event["kind"]=="local_pedestrian_departed": departures+=1
			if event["kind"]=="local_pedestrian_arrived": arrivals+=1
		assert(departures==1 and arrivals==1)
	assert(SandboxWorld.new().restore_snapshot(scene._world.snapshot()))
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("/tmp/od2d-living-evidence")
	assert(root.get_texture().get_image().save_png("/tmp/od2d-living-evidence/arrived.png")==OK)
	print("LIVING_STREETS_SCENE_PASS normal World ticks, two real agents, legal crossing, traffic yield, mid-crossing save and adjacent-block arrival")
	quit()
