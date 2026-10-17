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
	for frame in range(180):
		traffic.step(1.0/60.0);await physics_frame
	assert(traffic.priority.owner.is_empty())
	for body in traffic.actors.values():
		for crossing_x in [SandboxStreetModule.EAST_CROSS_X,1100.0]:
			assert(absf(body.position.x-crossing_x)>=27.0,"A stopped queue may not occupy a marked zebra")
	assert(traffic.actors["main"].position.x<=780.01)
	assert(traffic.actors["branch"].position.y<=290.01)
	assert(traffic.actors["following"].position.x<=traffic.actors["main"].position.x-41.99)
	await _shot("junction-blocked-queue")
	traffic.exit_blocked=false
	var captured: bool=false
	var blocked_owner: bool=false
	for frame in range(1600):
		traffic.step(1.0/60.0)
		await physics_frame
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
			for id in traffic.IDS: before[id]=traffic.actors[id].position
			traffic.free()
			traffic=SandboxJunctionTraffic.new();traffic.resume_state=saved;pilot.add_child(traffic)
			traffic.set_physics_process(false);pilot.junction=traffic
			for id in traffic.IDS:
				print("JUNCTION_RESTORE ",id," ",before[id]," -> ",traffic.actors[id].position," at ",traffic.distances[id])
				assert(traffic.actors[id].position.distance_to(before[id])<.02)
			captured=true
			await _shot("junction-branch-admitted")
	assert(captured)
	assert(traffic.actors["following"].position.x>900.0,"Finite downstream queue must drain without starvation/deadlock")
	assert(traffic.actors["branch"].position.x>940.0)
	assert(traffic.priority.owner.is_empty())
	for body in traffic.actors.values():
		for crossing_x in [SandboxStreetModule.EAST_CROSS_X,1100.0]:
			assert(absf(body.position.x-crossing_x)>=27.0,"The final queue must clear both marked zebras")
	assert(blocked_owner)
	assert(SandboxJunctionTraffic.valid_snapshot(traffic.snapshot()))
	print("JUNCTION_TRAFFIC_PASS blocked downstream, native FIFO merge, whole-body exclusion, headway, save/reconstruct and queue drain")
	quit()
func _shot(label: String) -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/od2d-multi-evidence")
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/od2d-multi-evidence/"+label+".png")
