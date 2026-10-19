extends SceneTree

# Real CharacterBody2D displacement, with the engine and controller sharing
# each tested physics delta. Abrupt stop-line/queue clamps fail this test.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	# Exercise every native physics step without spending 75 wall-clock
	# seconds in three queues. Scale tick frequency with test time so body
	# integration still receives exactly 1/10, 1/30 and 1/60 second deltas.
	Engine.time_scale=4.0
	Engine.max_physics_steps_per_frame=32
	for rate in [10,30,60]:
		Engine.physics_ticks_per_second=rate*4
		await physics_frame;await physics_frame
		var delta: float=1.0/float(rate)
		var traffic: SandboxJunctionTraffic=SandboxJunctionTraffic.new()
		root.add_child(traffic);traffic.set_physics_process(false)
		await physics_frame
		print("NATIVE_INTEGRATION_DELTA ",rate," ",traffic.get_physics_process_delta_time()," expected ",delta)
		assert(is_equal_approx(traffic.get_physics_process_delta_time(),delta),
				"Accelerated test time must not change native integration delta")
		var resumed: bool=false
		for frame in range(rate*25):
			traffic.exit_blocked=frame<rate*4
			var before: Dictionary={}
			for id in traffic.IDS: before[id]=traffic.actors[id].current_speed
			traffic.step(delta)
			for id in traffic.IDS:
				var body: SandboxTrafficVehicle=traffic.actors[id]
				assert(float(before[id])-body.current_speed<=SandboxVehicleKinematics.SERVICE_BRAKE*delta+.12,
						"Predict braking before FIFO stop, leader and terminal: %s at %d Hz, frame %d, %.3f -> %.3f at %s progress %.4f collision %d"%[id,rate,frame,before[id],body.current_speed,body.position,traffic.distances[id],body.get_slide_collision_count()])
				assert(body.current_speed-float(before[id])<=SandboxVehicleKinematics.ACCELERATION*delta+.12)
			assert(SandboxJunctionTraffic.valid_snapshot(traffic.snapshot()),"Every variable-delta frame must remain saveable")
			if frame>rate*4 and traffic.actors["main"].current_speed>1.0: resumed=true
			if frame in [rate*3,rate*7,rate*11]:
				var saved: Dictionary=traffic.snapshot()
				var positions: Dictionary={}
				for id in traffic.IDS: positions[id]=traffic.actors[id].position
				traffic.free();traffic=SandboxJunctionTraffic.new();traffic.resume_state=saved
				root.add_child(traffic);traffic.set_physics_process(false)
				assert(traffic.snapshot()==saved,"Queue, owner and physical speed must restore together")
				for id in traffic.IDS: assert(traffic.actors[id].position.distance_to(positions[id])<.03)
			await physics_frame
		assert(resumed and traffic.priority.owner.is_empty())
		assert(traffic.actors["following"].position.x>950,"Queue must drain at every tested tick rate")
		traffic.free()
	print("JUNCTION_BRAKING_SCENE_PASS 10/30/60 Hz native braking, downstream queues, stop/resume and saved motion")
	quit()
