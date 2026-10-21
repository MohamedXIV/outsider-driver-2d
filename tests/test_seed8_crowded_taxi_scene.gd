extends SceneTree

# Genuine crowded Seed 8 native reposition, using exactly the same World
# time-skip as the user's +6h Debug button. No injected car, resident,
# collision reservation, cost or temporary route.
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1600,900)
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene._reset_local_pedestrian()
	await physics_frame
	var world: SandboxWorld=SandboxWorld.new(8)
	scene._world=world
	scene._city.world=world
	scene._vehicle_corridor.attach(world)
	for batch in range(4): scene._advance_manual_time(360)
	scene._sync_local_pedestrian()
	assert(world.player_district=="garage" and world.residents.size()==9)
	print("SEED8_CROWDED_PRECONDITION ",JSON.stringify({"minute":world.minute,
		"events":world.events.size(),"vehicles":world.vehicle_execution.size(),
		"credits":world.credits,"travelling":world.is_travelling()}))
	assert(world.reposition("market"),"A real paid Garage -> Market reposition must be legal")
	var initial: int=world.remaining_minutes
	var stalled: int=0
	var last: float=-1.0
	var last_minute: int=world.minute
	var saw_native: bool=false
	var reason_counts: Dictionary={}
	for frame in range(1100):
		scene._process(.25)
		await physics_frame
		var state: Dictionary=world.vehicle_execution.get("player",{})
		if bool(state.get("native",false)): saw_native=true
		var reason: String=str(state.get("reason",""))
		reason_counts[reason]=int(reason_counts.get(reason,0))+1
		var position: float=float(state.get("progress",-1))
		if world.minute!=last_minute and world.is_travelling():
			if absf(position-last)<.00001 and reason=="vehicle":
				stalled+=world.minute-last_minute
			else: stalled=0
			last=position
			last_minute=world.minute
		if frame%40==0:
			var blocker: String=""
			if scene._vehicle_corridor.bodies.has("player"):
				blocker=scene._vehicle_corridor.bodies["player"].last_blocker
			print("SEED8_CROWDED_TAXI ",JSON.stringify({"frame":frame,
				"minute":world.minute,"remaining":world.remaining_minutes,
				"progress":position,"reason":reason,"blocker":blocker,
				"speed":state.get("speed",-1.0),"world_cars":world.vehicle_execution.size(),
				"native_cars":scene._vehicle_corridor.bodies.size(),
				"walkers":scene._street_pilot.loaded_ids().size() if scene._street_pilot!=null else 0,
				"route_hold":world.route_hold_id,
				"stalled_minutes":stalled}))
		assert(stalled<20,"A genuine 20-world-minute native vehicle obstruction must be diagnosed")
		if not world.is_travelling(): break
	assert(not world.is_travelling(),"Garage → Market native reposition never arrived")
	assert(world.player_district=="market" and world.route_hold_id.is_empty())
	assert(saw_native,"This must test actual Native traffic, not an aggregate-only journey")
	print("SEED8_CROWDED_TAXI_PASS ",JSON.stringify({"seed":8,
		"original_minutes":initial,"arrived_at":world.minute,
		"events":world.events.size(),"reasons":reason_counts}))
	quit()
