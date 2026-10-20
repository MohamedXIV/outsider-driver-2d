extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	assert(scene._world.reposition("docks","clinic"))
	assert(scene._world.advance(41))
	scene._render()
	scene._city.reduced_motion=true
	for frame in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://work/geometry-native.png"))
	print("GEOMETRY_VISUAL_CAPTURED")
	quit()
