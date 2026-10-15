extends SceneTree

const SHOTS: String = "/tmp/od2d-ink-evidence/sandbox"

func _initialize() -> void:
	call_deferred("_exercise")

func _exercise() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	var packed: PackedScene = load("res://scenes/sandbox.tscn")
	assert(packed != null)
	var scene: Node2D = packed.instantiate() as Node2D
	get_root().add_child(scene)
	await process_frame
	await process_frame
	var world: SandboxWorld = scene.get("_world") as SandboxWorld
	assert(world.seed == 8 and world.minute == 480)
	var observe: Button = scene.get_node("HUD/WorldPanel/Content/Observe") as Button
	var world_info: Label = scene.get_node("HUD/WorldPanel/Content/WorldInfo") as Label
	assert(not observe.disabled)
	await RenderingServer.frame_post_draw
	_capture("autonomy-before-idle.png")
	for i in range(4):
		observe.pressed.emit()
		await process_frame
	assert(world.minute == 480 + 1440 and world.active_offer_id.is_empty())
	assert(world_info.text.contains("ALT DEPARTURES") and world_info.text.contains("ALT ARRIVALS"))
	var departed: int = 0
	var arrived: int = 0
	for evt in world.events:
		if evt["kind"] == "npc_alternative_departed":
			departed += 1
		elif evt["kind"] == "npc_alternative_arrived":
			arrived += 1
	assert(departed > 0 and arrived > 0)
	await RenderingServer.frame_post_draw
	_capture("autonomy-after-idle.png")
	scene.call("_on_save")
	scene.call("_on_new_seed")
	scene.call("_on_load")
	var resumed: SandboxWorld = scene.get("_world") as SandboxWorld
	assert(resumed.minute == world.minute and resumed.events.size() == world.events.size())
	assert(resumed.residents == world.residents)
	await RenderingServer.frame_post_draw
	_capture("autonomy-restored.png")
	print("SANDBOX_AUTONOMY_SCENE_PASS")
	quit(0)

func _capture(name: String) -> void:
	var img: Image = get_root().get_texture().get_image()
	assert(img != null and img.get_width() >= 640)
	assert(img.save_png(SHOTS.path_join(name)) == OK)
