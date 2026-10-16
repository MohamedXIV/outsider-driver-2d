extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.get("_player_ui") != null, "Player adapter is installed")
	var ui: Node = scene.get("_player_ui")
	assert(not ui.debug_mode)
	assert(not scene.get_node("HUD").visible)
	var before: String = JSON.stringify(scene.get("_world").snapshot())
	ui.toggle_debug()
	assert(scene.get_node("HUD").visible)
	ui.toggle_debug()
	assert(JSON.stringify(scene.get("_world").snapshot()) == before)
	assert(ui.get_node("Root/Mode").size.y >= 44)
	print("PLAYER_MODE_PASS default, reversible shared world, touch toggle")
	quit()
