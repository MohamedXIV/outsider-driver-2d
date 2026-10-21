extends SceneTree

# Actual shared street scene: two WORLD-created residents appear, and a REAL
# player reposition approaches their legal crossing while Godot physics runs.
# No manual rider, fake reservation, hand-moved actor or injected yield.
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
	# One genuine World minute creates the two seeded local purposes.
	scene._process(1.0)
	await physics_frame
	assert(scene._street_pilot!=null and scene._street_pilot.pedestrians.size()==2)
	assert(world.resident("npc:04")["local_pedestrian_trip"]["status"]=="walking")
	assert(world.resident("npc:08")["local_pedestrian_trip"]["status"]=="walking")
	var candidate: Array[String]=SandboxRoads.path(world.player_district,"margin_gate")
	var needed: int=maxi(1,ceili(SandboxRoads.path_metres(candidate)/5000.0)) + SandboxRoads.path_expense(candidate)
	print("PLAYTEST_SHARED_PRECONDITION ",JSON.stringify({
		"district":world.player_district,"minute":world.minute,
		"travelling":world.is_travelling(),"meeting":world.meeting_in_progress(),
		"credits":world.credits,"cost":needed,"route":candidate,
		"pedestrians":scene._street_pilot.pedestrians.size()}))
	if not world.reposition("margin_gate"):
		printerr("PLAYTEST_SHARED_CANNOT_REPOSITION real World refused departure")
		quit(1)
		return
	var starting_minutes: int=world.remaining_minutes
	var saw_both: bool=false
	var saw_crossing: bool=false
	var saw_real_hold: bool=false
	var max_hold_minutes: int=0
	var held_from: int=-1
	var last_minute: int=world.minute
	var final_minute: int=-1
	for frame in range(2400):
		scene._process(1.0/60.0)
		await physics_frame
		if scene._street_pilot!=null:
			var pilot: SandboxStreetPilot=scene._street_pilot
			if pilot.pedestrians.has("npc:04") and pilot.pedestrians.has("npc:08"):
				saw_both=true
				var first: SandboxPedestrianActor=pilot.pedestrians["npc:04"]
				var second: SandboxPedestrianActor=pilot.pedestrians["npc:08"]
				assert(first.position.distance_to(second.position)>=12.0,
					"Native avoidance must not stack two distinct walking bodies")
				for actor in [first,second]:
					if SandboxStreetModule.ROAD.has_point(actor.position): saw_crossing=true
		if not world.route_hold_id.is_empty():
			saw_real_hold=true
			if held_from<0: held_from=world.minute
			max_hold_minutes=maxi(max_hold_minutes,world.minute-held_from)
			assert(max_hold_minutes<18,"Real player crossing hold failed to release with walking bodies")
		else:
			held_from=-1
		if frame%120==0:
			var native: Dictionary=world.vehicle_execution.get("player",{})
			print("PLAYTEST_SHARED_STREET_TRACE ",JSON.stringify({
				"minute":world.minute,"remaining":world.remaining_minutes,
				"hold":world.route_hold_id,"taxi_native":native.get("native",false),
				"taxi_speed":native.get("speed",0.0),"taxi_reason":native.get("reason",""),
				"two_bodies_loaded":saw_both,"walker_road":saw_crossing,
				"car_count":scene._vehicle_corridor.bodies.size(),
				"node_count":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))}))
		if not world.is_travelling():
			final_minute=world.minute
			break
	assert(saw_both,"Both persistent residents must share a real physics scene with the player taxi")
	assert(not world.is_travelling() and world.player_district=="margin_gate",
		"Real taxi must complete its physical approach rather than stay stopped forever")
	assert(world.route_hold_id.is_empty())
	assert(world.residents.size()==9)
	assert(max_hold_minutes<18)
	print("PLAYTEST_SHARED_STREET_PASS ",JSON.stringify({
		"seed":29,"from":"garage","to":"margin_gate",
		"route_minutes":starting_minutes,"arrival_world_minute":final_minute,
		"native_pair":saw_both,"legal_crossing_observed":saw_crossing,
		"vehicle_yield_observed":saw_real_hold,"max_hold_minutes":max_hold_minutes}))
	quit()
