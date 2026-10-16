extends SceneTree

const SHOTS: String = "/tmp/od2d-ink-evidence/sandbox"

func _initialize() -> void:
	call_deferred("_walk")

func _walk() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	var scene: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	get_root().add_child(scene)
	await process_frame
	await process_frame
	var world: SandboxWorld = scene.get("_world")
	var first_id: String = str(scene.get("_selected_id"))
	var speaker: String = str(world.offer_by_id(first_id)["npc_id"])
	var accept: Button = scene.get_node("HUD/DockPanel/Content/Actions/Accept")
	assert(not accept.disabled)
	accept.pressed.emit()
	assert(world.advance(world.remaining_minutes))
	scene.call("_render")
	assert(SandboxDriverMemory.recognizes(world.resident(speaker)))
	var second_id: String = ""
	for step in range(150):
		for offer in world.open_offers():
			if offer["npc_id"] == speaker and offer["id"] != first_id:
				second_id = str(offer["id"])
				break
		if not second_id.is_empty():
			break
		assert(world.advance(10))
	assert(not second_id.is_empty())
	scene.call("_render")
	var list: ItemList = scene.get_node("HUD/DockPanel/Content/Offers")
	var found: bool = false
	for i in range(list.item_count):
		if str(list.get_item_metadata(i)) == second_id:
			list.select(i)
			list.item_selected.emit(i)
			found = true
			break
	assert(found)
	await process_frame
	assert(scene.get("_selected_id") == second_id)
	assert((scene.get_node("HUD/DockPanel/Content/Details") as Label).text.contains("RETURNING CAB"))
	var talk: Button = scene.get_node("HUD/DockPanel/Content/Actions/Talk")
	assert(not talk.disabled)
	talk.pressed.emit()
	await process_frame
	var conversation: SandboxConversation = scene.get("_conversation")
	assert(conversation != null and conversation.recognizes_driver())
	assert(conversation.current_frame()["text"] == SandboxLanguagePresentation.source_line(
			str(world.resident(speaker)["language"]), "intro_repeat"))
	await RenderingServer.frame_post_draw
	assert(get_root().get_texture().get_image().save_png(SHOTS.path_join("returning-cab-native.png")) == OK)
	scene.call("_on_save")
	scene.call("_on_new_seed")
	scene.call("_on_load")
	var restored: SandboxConversation = scene.get("_conversation")
	assert(restored != null and restored.recognizes_driver())
	await RenderingServer.frame_post_draw
	assert(get_root().get_texture().get_image().save_png(SHOTS.path_join("returning-cab-restored.png")) == OK)
	print("SANDBOX_DRIVER_SCENE_PASS")
	quit(0)
