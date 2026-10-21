extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene);scene.set_process(false)
	scene._world=SandboxWorld.new(29);scene._city.world=scene._world
	scene._process(scene.REAL_SECONDS_PER_STEP)
	var pilot: Node=scene._street_pilot
	assert(pilot.get("pedestrians") is Dictionary,"The native presenter must host two real resident bodies")
	assert(pilot.pedestrians.size()==2 and scene._world.residents.size()==9)
	assert(pilot.pedestrians.has("npc:04") and pilot.pedestrians.has("npc:08"))
	var first: Node=pilot.pedestrians["npc:04"]
	var second: Node=pilot.pedestrians["npc:08"]
	assert(first._agent!=second._agent)
	# A clipped/unreachable path is not an arrival. Restore the legal goal afterward.
	first.position=Vector2(312,313);first.crossing_reserved=true;pilot.reconcile_reservations()
	first.destination=Vector2(210,260);first._target_set=false
	for i in range(90): await physics_frame
	assert(first.path_blocked and scene._world.resident(first.npc_id)["local_pedestrian_trip"]["crossing_state"]=="approach")
	assert(not first.did_arrive and scene._world.resident(first.npc_id)["local_pedestrian_trip"]["status"]=="walking")
	first.destination=SandboxStreetModule.SITE;first._target_set=false
	for i in range(1500):
		await physics_frame
		assert(first.position.distance_to(second.position)>=13.0,"Native pedestrian bodies overlap")
		if first.did_arrive and second.did_arrive: break
	print("ACTORS_END ",first.position," ",second.position," velocities ",first.velocity," ",second.velocity," reserved ",first.crossing_reserved," ",second.crossing_reserved," car ",pilot.car.position)
	assert(absf(pilot.car.position.y-SandboxStreetModule.LANE_Y)<.5 and absf(pilot.follower.position.y-SandboxStreetModule.LANE_Y)<.5,"Embedded physics cars must follow the rotated street axis")
	assert(first.did_arrive and second.did_arrive,"Both real native residents must reach their separate counter slots")
	for id in pilot.pedestrians:
		var arrivals: int=0
		for evt in scene._world.events:
			if evt["subject"]==id and evt["kind"]=="local_pedestrian_arrived": arrivals+=1
		assert(arrivals==1)
	assert(SandboxWorld.new().restore_snapshot(scene._world.snapshot()))
	# Completed errands must not erase saved native bodies / local traffic.
	scene._on_save();scene._on_load()
	assert(scene._street_pilot!=null and scene._street_pilot.pedestrians.size()==2)
	for id in scene._street_pilot.pedestrians:
		assert(scene._street_pilot.pedestrians[id].did_arrive)
	print("TWO_RESIDENT_SCENE_PASS genuine seed 29 residents, blocked path, native avoidance, independent once-only arrivals")
	quit()
