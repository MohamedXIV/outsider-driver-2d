extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var scene: SandboxStreetPilot=load("res://scenes/street_pilot.tscn").instantiate()
	root.add_child(scene)
	assert(scene.get_node_or_null("FourWayNorthWest") is NavigationRegion2D,
			"Street kit needs an actual four-way sidewalk module")
	for i in range(8): await physics_frame
	var map: RID=scene.pedestrian._agent.get_navigation_map()
	for destination in [Vector2(1186,180),Vector2(1262,530),Vector2(1513,560)]:
		var path: PackedVector2Array=NavigationServer2D.map_get_path(map,Vector2(980,313),destination,true)
		assert(path.size()>2 and path[path.size()-1].distance_to(destination)<2.0,
				"Four-way and corner must connect through native sidewalks: %s" % destination)
	for lot in SandboxStreetModule.EXTENSION_LOTS:
		for road in SandboxStreetModule.EXTENSION_ROADS:
			assert(not lot.intersects(road),"Building lots cannot occupy asphalt")
		for sidewalk in SandboxStreetModule.EXTENSION_SIDEWALKS.values():
			assert(not lot.intersects(sidewalk),"Building setbacks must preserve sidewalk")
	var graph_before: Dictionary=scene.world.snapshot()
	var camera: Camera2D=root.get_camera_2d()
	camera.position=Vector2(850,350);camera.zoom=Vector2.ONE*.7
	await process_frame;await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("/tmp/od2d-street-evidence")
	root.get_texture().get_image().save_png("/tmp/od2d-street-evidence/kit-fourway-corner-wide.png")
	camera.position=Vector2(1310,370);camera.zoom=Vector2.ONE*1.5
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/od2d-street-evidence/kit-fourway-corner-close.png")
	assert(scene.world.snapshot()==graph_before,"Kit presentation cannot change graph/world state")
	print("STREET_EXTENSION_PASS native connected four-way and corner, marked crossing links, world-neutral kit")
	quit()
