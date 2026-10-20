extends SceneTree
func _initialize() -> void: call_deferred('_run')
func _run() -> void:
	root.size=Vector2i(1280,720)
	var w: SandboxWorld=SandboxWorld.new(8)
	assert(w.reposition('market','margin_gate'))
	while not SandboxStreetRouteBinding.approaching(w): assert(w.advance(1))
	assert(w.begin_crossing_yield())
	var host: Node2D=Node2D.new();root.add_child(host)
	var camera: Camera2D=Camera2D.new();camera.name='Camera2D';host.add_child(camera)
	var city: SandboxCityView=SandboxCityView.new();city.world=w;host.add_child(city)
	city.set_process(false);city._process(0);camera.reset_smoothing()
	var out: String='/tmp/od2d-lane-evidence'
	var snapshot: Dictionary=w.snapshot()
	var initial_pose: Vector2=SandboxDirectedLanes.taxi_screen(w,0.0)
	DirAccess.make_dir_recursive_absolute(out)
	var frames: Array=[]
	for i in range(5):
		city.visual_fraction=float(i)*.2375
		city._layers['ground'].queue_redraw();city._layers['above'].queue_redraw()
		for frame in range(3): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join('%02d.png'%i))
		var pose: Vector2=SandboxDirectedLanes.taxi_screen(w,city.visual_fraction)
		assert(pose.distance_to(initial_pose)<.001, 'The visible taxi cannot creep through a World-owned zebra hold')
		assert(w.snapshot()==snapshot, 'Sequential rendering cannot mutate World provenance')
		var authoritative: Vector3=w.player_position(city.visual_fraction)
		frames.append({'frame':i,'fraction':city.visual_fraction,'minute':w.minute,'hold':w.route_hold_id,'screen':[pose.x,pose.y],'world':[authoritative.x,authoritative.y,authoritative.z],'resident_count':w.residents.size()})
	var f: FileAccess=FileAccess.open(out.path_join('frames.json'),FileAccess.WRITE)
	f.store_string(JSON.stringify(frames,'  '));f.close()
	var restored: SandboxWorld=SandboxWorld.new()
	assert(restored.restore_snapshot(snapshot))
	assert(SandboxDirectedLanes.taxi_screen(restored,.95).distance_to(initial_pose)<.001)
	print('LANE_VISUAL_SCENE_PASS sequential native held poses, immutable World provenance, deterministic Save/Load projection ',out)
	quit()
