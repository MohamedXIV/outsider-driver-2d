extends SceneTree

const SHOTS: String = "/tmp/od2d-ink-evidence/sandbox"
func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	var scene: Node2D = load("res://scenes/sandbox.tscn").instantiate() as Node2D
	get_root().add_child(scene)
	scene._player_ui.toggle_debug()
	await process_frame
	await process_frame
	var world: SandboxWorld = scene.get("_world") as SandboxWorld
	var observe: Button = scene.get_node("HUD/WorldPanel/Content/Observe") as Button
	observe.pressed.emit()
	await process_frame
	var source: Dictionary = {}
	for event in world.events:
		if event["kind"] == "npc_peer_contact":
			source = event
			break
	assert(not source.is_empty())
	assert(world.resident(str(source["detail"]["recipient"]))["peer_knowledge"].has(source["detail"]["fact"]))
	var info: Label = scene.get_node("HUD/WorldPanel/Content/WorldInfo") as Label
	assert(info.text.contains("PEER CONTACTS") and info.text.contains("PEER FACTS"))
	await RenderingServer.frame_post_draw
	var screenshot: Image = get_root().get_texture().get_image()
	assert(screenshot.save_png(SHOTS.path_join("peer-contacts-idle.png")) == OK)
	scene.call("_on_save")
	scene.call("_on_new_seed")
	scene.call("_on_load")
	var restored: SandboxWorld = scene.get("_world") as SandboxWorld
	assert(restored.events == world.events and restored.residents == world.residents)
	await RenderingServer.frame_post_draw
	assert(get_root().get_texture().get_image().save_png(SHOTS.path_join("peer-contacts-restored.png")) == OK)
	print("SANDBOX_PEER_SCENE_PASS")
	quit(0)
