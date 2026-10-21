extends SceneTree

# Regression: a blocked native resident's genuine pose is outside the
# authorised offscreen path corridor. We must NOT queue_free the only body
# while the World still owns a walking crossing reservation.
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene._reset_local_pedestrian()
	var world: SandboxWorld=SandboxWorld.new(29)
	scene._world=world
	scene._city.world=world
	scene._vehicle_corridor.attach(world)
	scene._process(1.0) # Genuine World tick starts two eligible errands.
	await physics_frame
	var pilot: SandboxStreetPilot=scene._street_pilot
	assert(pilot!=null and pilot.pedestrians.size()==2)
	var first: SandboxPedestrianActor=pilot.pedestrians["npc:04"]
	var second: SandboxPedestrianActor=pilot.pedestrians["npc:08"]
	first.set_physics_process(false);second.set_physics_process(false)
	var old: Dictionary={}
	for id in ["npc:04","npc:08"]:
		old[id]=int(world.events.filter(func(e: Dictionary)->bool:
			return e.get("kind","")=="local_pedestrian_handoff" and e.get("subject","")==id).size())
	assert(world.resident("npc:04")["local_pedestrian_trip"]["status"]=="walking")
	assert(world.resident("npc:08")["local_pedestrian_trip"]["status"]=="walking")
	# Emulate a real physics avoidance displacement outside the 24px valid
	# handoff corridor. This is a test-only obstruction, NOT a teleport policy.
	var good: Vector2=first.position
	first.position=good+Vector2(0,-38.0)
	assert(first.position.distance_to(SandboxStreetModule.position_at(
			SandboxStreetModule.progress_of(first.position,first.slot),first.slot))>24.0)
	world.player_district="clinic" # Force actual presenter to unload; no World tick.
	scene._sync_local_pedestrian()
	assert(scene._street_pilot==pilot and is_instance_valid(first),
		"Rejected handoff must preserve the ONLY native body and collision authority")
	for id in ["npc:04","npc:08"]:
		assert(world.resident(id)["local_pedestrian_trip"]["status"]=="walking",
			"No partial handoff allowed when either real body is invalid")
		var count: int=0
		for evt in world.events:
			if evt.get("kind","")=="local_pedestrian_handoff" and evt.get("subject","")==id: count+=1
		assert(count==int(old[id]),"Failed handoff must not append a fake event")
	# When avoidance returns to legal pavement, both bodies can hand off
	# atomically and their event-owned trajectories resume without duplicates.
	first.position=good
	scene._sync_local_pedestrian()
	assert(scene._street_pilot==null)
	for id in ["npc:04","npc:08"]:
		assert(world.resident(id)["local_pedestrian_trip"]["status"]=="offscreen")
		assert(SandboxLocalPedestrianTrip.valid_history(world.resident(id),world.events,world.minute))
	print("FAILED_HANDOFF_SAFETY_PASS off-path body retained, no partial events, exact eventual handoff")
	quit()
