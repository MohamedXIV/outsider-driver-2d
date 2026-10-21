extends SceneTree

# Native CPU profiler for the ACTUAL Seed 8 screenshot: preserve all World
# economy and event history. Run identical script against frozen baseline
# and playtest fixes on the SAME GitHub runner, never assert faster == correct.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1600,900)
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	var world: SandboxWorld=SandboxWorld.new(8)
	scene._world=world
	scene._city.world=world
	scene._vehicle_corridor.attach(world)
	for segment in range(5):
		var started: int=Time.get_ticks_usec()
		# This is the real +6h user command, including Native reservation
		# checks; NOT a fabricated event count or a replaceable NPC fixture.
		scene._advance_manual_time(360)
		var elapsed: int=Time.get_ticks_usec()-started
		scene._render()
		var ticks: int=90
		var total_process: int=0
		var max_process: int=0
		for n in range(ticks):
			var before: int=Time.get_ticks_usec()
			scene._process(1.0/60.0)
			await physics_frame
			var micros: int=Time.get_ticks_usec()-before
			total_process+=micros
			max_process=maxi(max_process,micros)
		var sample: Dictionary={
			"seed":8,"batch":segment,"world_minute":world.minute,
			"events":world.events.size(),"vehicles":scene._vehicle_corridor.bodies.size(),
			"world_vehicles":world.vehicle_execution.size(),
			"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			"manual_six_hour_wall_ms":float(elapsed)/1000.0,
			"frame_mean_ms":float(total_process)/1000.0/float(ticks),
			"frame_max_ms":float(max_process)/1000.0}
		print("SEED8_MATCHED_PERF ",JSON.stringify(sample))
		assert(world.residents.size()==9)
		assert(world.minute>=SandboxWorld.START_MINUTE+360*(segment+1))
	print("SEED8_MATCHED_PERF_PASS")
	quit()
