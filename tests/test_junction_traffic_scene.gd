extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var pilot: SandboxStreetPilot=SandboxStreetPilot.new();pilot.embedded=true
	root.add_child(pilot)
	var camera: Camera2D=Camera2D.new();camera.position=Vector2(835,330);camera.zoom=Vector2.ONE*1.7
	root.add_child(camera)
	await physics_frame;await physics_frame
	var traffic: SandboxJunctionTraffic=pilot.junction
	traffic.set_physics_process(false)
	traffic.exit_blocked=true
	var saw_approach_acceleration: bool=false
	var saw_approach_braking: bool=false
	var previous_speed: float=0.0
	for frame in range(180):
		traffic.step(1.0/60.0);await physics_frame
		var speed: float=traffic.actors["main"].current_speed
		if speed>0.1 and speed<SandboxVehicleKinematics.CRUISE-.1:
			saw_approach_acceleration=true
		if speed<previous_speed-.01 and traffic.distances["main"]<traffic.STOP_DISTANCE-.5:
			saw_approach_braking=true
		previous_speed=speed
	assert(saw_approach_acceleration and saw_approach_braking,
			"Junction approach must accelerate and brake before the priority stop")
	assert(traffic.priority.owner.is_empty())
	for body in traffic.actors.values():
		for crossing_x in [SandboxStreetModule.EAST_CROSS_X,1100.0]:
			assert(absf(body.position.x-crossing_x)>=27.0,"A stopped queue may not occupy a marked zebra")
	assert(traffic.actors["main"].position.x<=780.01)
	assert(traffic.actors["branch"].position.y<=290.01)
	assert(traffic.actors["following"].position.x<=traffic.actors["main"].position.x-41.99)
	assert(traffic.actors["main"].current_speed<0.01 and
			traffic.actors["branch"].current_speed<0.01,
			"Vehicles must rest at a blocked priority stop")
	await _shot("junction-blocked-queue")
	traffic.exit_blocked=false
	var accelerated_after_release: bool=false
	var captured: bool=false
	var blocked_owner: bool=false
	for frame in range(1600):
		traffic.step(1.0/60.0)
		await physics_frame
		if traffic.priority.owner=="main" and traffic.actors["main"].current_speed>0.01 \
				and traffic.actors["main"].current_speed<SandboxJunctionTraffic.SPEED*.5:
			accelerated_after_release=true
		assert(SandboxLocalPedestrianTrip.valid_presentation(pilot.world,pilot.visual_snapshot()),"Every ordinary physical frame must be saveable")
		var occupied: int=0
		for id in traffic.IDS:
			if traffic._in_conflict(id): occupied+=1
			for other in traffic.IDS:
				if id!=other: assert(traffic.actors[id].position.distance_to(traffic.actors[other].position)>=31.0)
		assert(occupied<=1,"Conflicting approaches cannot occupy the box together")
		if traffic.priority.owner=="main" and traffic.actors["main"].position.x>810.0 and not blocked_owner:
			var block: StaticBody2D=StaticBody2D.new();block.position=Vector2(862,350);block.collision_layer=4
			var hit: CollisionShape2D=CollisionShape2D.new();var box: RectangleShape2D=RectangleShape2D.new();box.size=Vector2(20,24)
			hit.shape=box;block.add_child(hit);pilot.add_child(block)
			for tick in range(150):
				traffic.step(1.0/60.0);await physics_frame
				assert(traffic.priority.owner=="main","An actually blocked body retains the conflict zone")
			assert(traffic.actors["main"].position.x<840.0)
			block.free();blocked_owner=true
		if traffic.priority.owner=="branch" and not captured:
			var saved: Dictionary=traffic.snapshot()
			assert(SandboxJunctionTraffic.valid_snapshot(saved))
			var before: Dictionary={}
			for id in traffic.IDS:
				before[id]={"position":traffic.actors[id].position,
						"speed":traffic.actors[id].current_speed}
			traffic.free()
			traffic=SandboxJunctionTraffic.new();traffic.resume_state=saved;pilot.add_child(traffic)
			traffic.set_physics_process(false);pilot.junction=traffic
			for id in traffic.IDS:
				print("JUNCTION_RESTORE ",id," ",before[id]," -> ",traffic.actors[id].position," at ",traffic.distances[id])
				assert(traffic.actors[id].position.distance_to(before[id]["position"])<.02)
				assert(is_equal_approx(traffic.actors[id].current_speed,float(before[id]["speed"])),
						"Mid-turn native vehicle speed must persist, not reset to cruise")
			captured=true
			await _shot("junction-branch-admitted")
	assert(captured)
	assert(traffic.actors["following"].position.x>900.0,"Finite downstream queue must drain without starvation/deadlock")
	assert(traffic.actors["branch"].position.x>940.0)
	assert(traffic.priority.owner.is_empty())
	for body in traffic.actors.values():
		for crossing_x in [SandboxStreetModule.EAST_CROSS_X,1100.0]:
			assert(absf(body.position.x-crossing_x)>=27.0,"The final queue must clear both marked zebras")
	assert(blocked_owner and accelerated_after_release,
			"FIFO release must resume with gradual native acceleration")
	assert(SandboxJunctionTraffic.valid_snapshot(traffic.snapshot()))
	print("JUNCTION_TRAFFIC_PASS blocked downstream, native FIFO merge, whole-body exclusion, headway, save/reconstruct and queue drain")
	quit()
func _shot(label: String) -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/od2d-multi-evidence")
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/od2d-multi-evidence/"+label+".png")
