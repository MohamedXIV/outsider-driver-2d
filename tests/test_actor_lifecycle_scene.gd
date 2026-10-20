extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var scene: Node2D=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene._process(.25)
	var world: SandboxWorld=scene._world
	var ids: Array[String]=scene._street_pilot.loaded_ids()
	assert(not ids.is_empty())
	for i in range(30): await physics_frame
	var poses: Dictionary={}
	for id in ids:
		poses[id]=scene._street_pilot.pedestrians[id].global_position
	# Actual authored road departure and its ordinary proximity threshold.
	assert(world.reposition("market","margin_gate"))
	while SandboxStreetRouteBinding.in_neighborhood(world):
		assert(world.advance(1))
	# No physics frame between body observation, handoff and replacement.
	for id in ids: poses[id]=scene._street_pilot.pedestrians[id].global_position
	# Handoff occurs mid-minute in actual play. Reapplying this fraction
	# to the new anchor previously jumped the far walker immediately.
	scene._elapsed=.6
	scene._city.visual_fraction=.6
	scene._sync_local_pedestrian()
	assert(scene._street_pilot==null)
	var out: String="/tmp/od2d-lifecycle-evidence"
	DirAccess.make_dir_recursive_absolute(out)
	var source: FileAccess=FileAccess.open(out.path_join("world.json"),FileAccess.WRITE)
	source.store_string(JSON.stringify(world.snapshot()));source.close()
	var traces: Array=[]
	for i in range(5):
		scene._city.visual_fraction=.6+float(i)*.05
		var frame: Dictionary={"frame":i,"minute":world.minute,"actors":[],"population":world.residents.size()}
		for id in ids:
			var pose: Dictionary=SandboxActorLifecycle.pose(world,world.resident(id),scene._city.visual_fraction)
			assert(not pose.is_empty(),"An unloaded resident must keep a visible representation")
			if i==0: assert(pose["position"].distance_to(poses[id])<.001)
			frame["actors"].append({"id":id,"native":false,"render":[pose["position"].x,pose["position"].y],
				"trip":world.resident(id)["local_pedestrian_trip"].duplicate(true)})
		scene._city.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("%02d.png"%i))
		traces.append(frame)
	var file: FileAccess=FileAccess.open(out.path_join("frames.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(traces,"  "));file.close()
	# Real Save/Load must restore the same presentation timestamp before
	# the far renderer or native materialization sees the bundle.
	scene._on_save()
	assert(scene._notice_text=="Sandbox saved.")
	var before_load: Dictionary={}
	for id in ids: before_load[id]=SandboxActorLifecycle.pose(scene._world,scene._world.resident(id),.6)["position"]
	scene._elapsed=.1;scene._city.visual_fraction=.1
	scene._on_load()
	assert(scene._notice_text=="World, NPC and live dialogue restored.")
	assert(is_equal_approx(scene._city.visual_fraction,.6))
	for id in ids:
		assert(SandboxActorLifecycle.pose(scene._world,scene._world.resident(id),scene._city.visual_fraction)["position"].distance_to(before_load[id])<.001)
	# Reentry uses exactly the same fractional far pose, not an older minute.
	var far: Dictionary={}
	for id in ids: far[id]=SandboxActorLifecycle.pose(world,world.resident(id),.8)["position"]
	# Return through the same real road; same-minute reversal is unnecessary
	# for the test: a restored nearby World exercises the load boundary.
	var saved: SandboxWorld=SandboxWorld.new()
	assert(saved.restore_snapshot(world.snapshot()))
	var local: SandboxStreetPilot=SandboxStreetPilot.new()
	local.world=saved;local.embedded=true;local.reentry_fraction=.8
	local.transform=SandboxStreetRouteBinding.street_transform();root.add_child(local)
	for id in ids:
		assert(local.pedestrians.has(id))
		assert(local.pedestrians[id].global_position.distance_to(far[id])<.001)
	assert(world.residents.size()==9 and saved.residents.size()==9)
	assert(SandboxWorld.new().restore_snapshot(saved.snapshot()))
	print("ACTOR_LIFECYCLE_SCENE_PASS actual route unload, exact collision anchors, five far frames, restored fractional reentry ",out)
	quit()
