extends SceneTree

# Human playtest regression: two genuine trips through the physical Patchworks
# crossing, then the observed Clinic → Mutual Aid Hall leg on the SAME World.
# No actor, timer or traffic reservation is fabricated by this test.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	await physics_frame
	scene._reset_local_pedestrian()
	var world: SandboxWorld=SandboxWorld.new(29)
	scene._world=world
	scene._city.world=world
	scene._vehicle_corridor.attach(world)
	assert(world.player_district=="garage")
	assert(world.reposition("clinic"),"Real garage-origin route to Night Clinic must exist")
	var initial_minutes: int=world.remaining_minutes
	var leg: int=0
	var last_minute: int=world.minute
	var last_cursor: String=""
	var unchanged_minutes: int=0
	var max_frame_usec: int=0
	var sum_usec: int=0
	var num_frames: int=0
	for frame in range(1050):
		var now: int=Time.get_ticks_usec()
		scene._process(.25)
		await physics_frame
		var usec: int=Time.get_ticks_usec()-now
		sum_usec+=usec
		num_frames+=1
		max_frame_usec=maxi(max_frame_usec,usec)
		var state: Dictionary=world.vehicle_execution.get("player",{})
		var cursor: String="%d/%d/%.5f"%[
			world.route_segment,world.route_edge_elapsed,float(state.get("progress",-1.0))]
		if world.minute!=last_minute:
			if world.is_travelling() and cursor==last_cursor:
				unchanged_minutes+=world.minute-last_minute
			else: unchanged_minutes=0
			last_minute=world.minute
			last_cursor=cursor
		if frame%40==0:
			print("PLAYTEST_ROUNDTRIP_TRACE ",JSON.stringify({
				"leg":leg,"minute":world.minute,"remaining":world.remaining_minutes,
				"segment":world.route_segment,"edge":world.route_edge_elapsed,
				"native_progress":state.get("progress",-1),"speed":state.get("speed",-1),
				"reason":state.get("reason",""),"crossing_hold":world.route_hold_id,
				"pedestrians":scene._street_pilot.loaded_ids().size() if scene._street_pilot!=null else 0,
				"cars":scene._vehicle_corridor.bodies.size(),
				"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
				"avg_frame_usec":float(sum_usec)/float(num_frames)}))
		assert(unchanged_minutes<=25,
			"Real taxi cursor stuck longer than 25 World minutes — check trace for collision/yield reason")
		if not world.is_travelling():
			if leg==0:
				assert(world.player_district=="clinic")
				assert(world.route_hold_id.is_empty())
				assert(world.reposition("shelter"),"Must continue from Night Clinic toward Mutual Aid Hall")
				leg=1;unchanged_minutes=0;last_cursor=""
				print("PLAYTEST_ROUNDTRIP_CLINIC_ARRIVED ",world.minute)
			else:
				break
	assert(leg==1 and not world.is_travelling() and world.player_district=="shelter",
		"Actual two-leg native drive could not reach Mutual Aid Hall")
	assert(world.route_hold_id.is_empty())
	var departed: int=0
	for event in world.events:
		if event.get("kind","")=="local_pedestrian_departed": departed+=1
	assert(departed>=1,"The genuine garage resident must initiate an errand in ordinary ticks")
	print("PLAYTEST_ROUNDTRIP_PASS ",JSON.stringify({
		"seed":29,"initial_leg_minutes":initial_minutes,"final_world_minute":world.minute,
		"total_frames":num_frames,"average_usec":float(sum_usec)/float(num_frames),
		"max_usec":max_frame_usec,"final_nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"pedestrian_departures":departed}))
	quit()
