extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	var city: Node = scene.get("_city")
	var camera: Camera2D = scene.get_node("Camera2D")
	city._process(1.0)
	assert(camera.zoom.x > 2.0, "Fresh camera must be closer than the fixed baseline")
	var before: String = JSON.stringify(scene.get("_world").snapshot())
	assert(city.has_method("set_manual_zoom"), "Camera needs bounded manual zoom")
	city.set_manual_zoom(100.0)
	city._process(0.01)
	assert(camera.zoom.x < city.zoom_preference, "Normal zoom eases toward preference")
	city.reduced_motion = true
	city._process(0.01)
	assert(is_equal_approx(camera.zoom.x, 4.0))
	city.set_manual_zoom(-100.0)
	city._process(0.01)
	assert(is_equal_approx(camera.zoom.x, 1.25))
	assert(JSON.stringify(scene.get("_world").snapshot()) == before, "Zoom cannot mutate world")
	var ui: Node = scene.get("_player_ui")
	ui._tab("settings")
	assert(ui._actions.has("zoom_in") and ui._actions.has("zoom_out"))
	assert(ui._actions.zoom_in.custom_minimum_size.y >= 44)
	scene._on_save()
	city.set_manual_zoom(3.5)
	scene._on_load()
	assert(is_equal_approx(city.zoom_preference, 1.25), "Manual preference survives world load")
	print("CAMERA_ZOOM_PASS closer bounded smooth reduced-motion touch persistent world-neutral")
	quit()
