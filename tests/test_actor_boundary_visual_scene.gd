extends SceneTree

func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size=Vector2i(1280,720)
	var world: SandboxWorld=SandboxWorld.new(29)
	var id: String=SandboxLocalPedestrianTrip.candidate(world)
	assert(SandboxLocalPedestrianTrip.begin(world,id,SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	assert(world.reposition("market","margin_gate"))
	while SandboxStreetRouteBinding.in_neighborhood(world): assert(world.advance(1))
	var anchor: Vector2=SandboxStreetModule.position_at(.24)
	assert(SandboxLocalPedestrianTrip.handoff(world,id,.24,anchor))
	var host: Node2D=Node2D.new();root.add_child(host)
	var camera: Camera2D=Camera2D.new();camera.name="Camera2D";host.add_child(camera)
	var city: SandboxCityView=SandboxCityView.new();city.world=world;host.add_child(city)
	city.set_process(false)
	# Inspect the threshold at the minimum supported zoom. Camera placement
	# affects observation only; no actor or World pose moves for the image.
	camera.position=SandboxStreetRouteBinding.street_transform()*anchor
	camera.zoom=Vector2.ONE*SandboxCityView.MIN_ZOOM
	var out: String="/tmp/od2d-actor-boundary"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var traces: Array=[]
	for i in range(5):
		city.visual_fraction=float(i)*.2
		city._layers["ground"].queue_redraw();city._layers["above"].queue_redraw()
		for frame in range(2): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("%02d.png"%i))
		traces.append({"id":id,"minute":world.minute,"fraction":city.visual_fraction,
			"handoff":[anchor.x,anchor.y],"trip":world.resident(id)["local_pedestrian_trip"].duplicate(true),
			"camera":[camera.position.x,camera.position.y],"zoom":camera.zoom.x,"population":world.residents.size()})
	var file: FileAccess=FileAccess.open(out.path_join("frames.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(traces,"  "));file.close()
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	print("ACTOR_BOUNDARY_VISUAL_SCENE_PASS real resident, authored road threshold, minimum zoom, five frames ",out)
	quit()
