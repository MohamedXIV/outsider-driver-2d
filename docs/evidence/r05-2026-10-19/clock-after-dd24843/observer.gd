extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size=Vector2i(1280,720)
	var source: String="/workspace/outsider-driver-2d/work/phase-evidence-source.json"
	var out: String="/tmp/od2d-phase-after"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--snapshot="): source=argument.trim_prefix("--snapshot=")
		if argument.begins_with("--out="): out=argument.trim_prefix("--out=")
	var world: SandboxWorld=SandboxWorld.new()
	assert(world.restore_snapshot(SandboxSave._canonical_json_numbers(JSON.parse_string(FileAccess.get_file_as_string(source)))))
	var npc: Dictionary={}
	for person in world.residents:
		if person.get("local_pedestrian_trip",{}).get("status","")=="offscreen": npc=person;break
	assert(not npc.is_empty())
	var trip: Dictionary=npc["local_pedestrian_trip"]
	var anchor: Vector2=SandboxStreetRouteBinding.street_transform()*Vector2(float(trip["handoff_x"]),float(trip["handoff_y"]))
	var host: Node2D=Node2D.new();root.add_child(host)
	var camera: Camera2D=Camera2D.new();camera.name="Camera2D";host.add_child(camera)
	var city: SandboxCityView=SandboxCityView.new();city.world=world;host.add_child(city);city.set_process(false)
	camera.position=anchor;camera.zoom=Vector2.ONE*2.6
	var reference: Node2D=Node2D.new();reference.position=anchor;reference.z_index=10;host.add_child(reference)
	reference.draw.connect(func()->void:
		reference.draw_line(Vector2(-10,0),Vector2(10,0),Color("de7190"),1.0)
		reference.draw_line(Vector2(0,-10),Vector2(0,10),Color("de7190"),1.0))
	var snapshot: Dictionary=world.snapshot()
	var frames: Array=[]
	DirAccess.make_dir_recursive_absolute(out)
	for i in range(5):
		city.visual_fraction=.6+float(i)*.05
		city._layers["ground"].queue_redraw();city._layers["above"].queue_redraw()
		for frame in range(2): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("%02d.png"%i))
		var point: Vector2=SandboxActorLifecycle.pose(world,npc,city.visual_fraction)["position"]
		frames.append({"id":npc["id"],"minute":world.minute,"fraction":city.visual_fraction,
			"native_anchor":[anchor.x,anchor.y],"render":[point.x,point.y],"offset":point.distance_to(anchor),
			"population":world.residents.size(),"trip":trip.duplicate(true)})
		assert(world.snapshot()==snapshot)
	var f: FileAccess=FileAccess.open(out.path_join("frames.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(frames,"  "));f.close()
	print("PHASE_VISUAL_OBSERVED first offset ",frames[0]["offset"]," ",out)
	quit()
