extends SceneTree

# Human-reported "Night Clinic · en route · 10m" freeze and progressive
# frame cost. Use an ordinary seeded World + authored reposition; this
# diagnostic never forges an NPC, collision hold, timestamp or fare.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	await physics_frame
	var world: SandboxWorld=SandboxWorld.new(29)
	world.player_district="clinic" # Authored scenario origin, as in native return QA.
	scene._world=world
	scene._city.world=world
	scene._vehicle_corridor.attach(world)
	assert(world.reposition("shelter"),"The user's Clinic -> Mutual Aid Hall route must be connected")
	var plan: int=world.remaining_minutes
	assert(plan>0)
	scene._player_ui._tab("map")
	var status_visible: bool=false
	for label in scene._player_ui._body.find_children("*","Label",true,false):
		if "Current trip" in str(label.text) or "Taxi" in str(label.text):
			status_visible=true
	assert(status_visible,"Disabled Drive must explain an active journey instead of silently greying out")
	var last_minute: int=world.minute
	var last_route: String=""
	var unmoving_world_ticks: int=0
	var observations: Array=[]
	var total_micros: int=0
	var max_micros: int=0
	var frames: int=0
	for frame in range(720):
		var start_usec: int=Time.get_ticks_usec()
		scene._process(.25)
		await physics_frame
		var spent: int=Time.get_ticks_usec()-start_usec
		max_micros=maxi(max_micros,spent)
		total_micros+=spent
		frames+=1
		var state: Dictionary=world.vehicle_execution.get("player",{})
		var cursor: String="%d/%d/%.3f"%[world.route_segment,world.route_edge_elapsed,float(state.get("progress",-1.0))]
		if world.minute!=last_minute:
			if world.is_travelling() and cursor==last_route:
				unmoving_world_ticks+=world.minute-last_minute
			else:
				unmoving_world_ticks=0
			last_route=cursor
			last_minute=world.minute
		if frame%40==0 or (not world.is_travelling()):
			var item: Dictionary={
				"frame":frame,"minute":world.minute,"remaining":world.remaining_minutes,
				"segment":world.route_segment,"edge_elapsed":world.route_edge_elapsed,
				"hold":world.route_hold_id,"native":bool(state.get("native",false)),
				"speed":float(state.get("speed",-1.0)),
				"reason":str(state.get("reason","")),"body_count":scene._vehicle_corridor.bodies.size(),
				"pedestrians":scene._street_pilot.loaded_ids().size() if scene._street_pilot!=null else 0,
				"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
				"frame_usec":spent,"average_usec":float(total_micros)/float(frames)}
			observations.append(item)
			print("PLAYTEST_LIVENESS_SAMPLE ",JSON.stringify(item))
		if unmoving_world_ticks>25:
			printerr("PLAYTEST_LIVENESS_STALL ",JSON.stringify(observations))
			assert(false,"Taxi remained at an identical route cursor for more than 25 World minutes")
		if not world.is_travelling(): break
	assert(not world.is_travelling(),"Real clinic-origin journey never arrived after 180 wall-clock seconds")
	assert(world.player_district=="shelter")
	assert(world.route_hold_id.is_empty())
	print("PLAYTEST_LIVENESS_PASS ",JSON.stringify({
		"seed":29,"start":"clinic","destination":"shelter","planned_minutes":plan,
		"steps":frames,"average_usec":float(total_micros)/float(frames),
		"max_usec":max_micros,"final_nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	}))
	quit()
