extends SceneTree

const SHOTS: String = "/tmp/od2d-ink-evidence/sandbox"

func _initialize() -> void:
	call_deferred("_walkthrough")

func _walkthrough() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	var packed: PackedScene = load("res://scenes/sandbox.tscn")
	assert(packed != null)
	var scene: Node2D = packed.instantiate() as Node2D
	get_root().add_child(scene)
	await process_frame
	await process_frame
	var world: SandboxWorld = scene.get("_world") as SandboxWorld
	var list: ItemList = scene.get_node("HUD/DockPanel/Content/Offers") as ItemList
	var accept: Button = scene.get_node("HUD/DockPanel/Content/Actions/Accept") as Button
	assert(world.residents.size() == 9 and list.item_count > 1)
	assert(not accept.disabled, "No accessible generated demand at the starting district.")
	var talk: Button = scene.get_node("HUD/DockPanel/Content/Actions/Talk") as Button
	var dialogue: PanelContainer = scene.get_node("HUD/DialoguePanel") as PanelContainer
	var choice_list: VBoxContainer = scene.get_node("HUD/DialoguePanel/Content/Choices") as VBoxContainer
	assert(not talk.disabled)
	talk.pressed.emit()
	await process_frame
	assert(dialogue.visible and choice_list.get_child_count() == 3)
	var conversation: SandboxConversation = scene.get("_conversation") as SandboxConversation
	assert(conversation != null and not conversation.understood())
	assert(conversation.current_frame()["tags"].has("intent:request_trip"))
	await RenderingServer.frame_post_draw
	_capture("speaking-unknown-language.png")
	(choice_list.get_child(0) as Button).pressed.emit()
	await process_frame
	assert(conversation.current_frame()["tags"].has("intent:ask_destination"))
	assert(choice_list.get_child_count() == 2, "Ask destination did not keep valid actions.")
	scene.call("_on_save")
	var old_offer_id: String = conversation.offer_id
	scene.call("_on_load")
	var resumed: SandboxConversation = scene.get("_conversation") as SandboxConversation
	assert(resumed != null and resumed.offer_id == old_offer_id)
	assert(resumed.current_frame()["tags"].has("intent:ask_destination"))
	await RenderingServer.frame_post_draw
	_capture("restored-ink-choice.png")
	(choice_list.get_child(0) as Button).pressed.emit()
	await process_frame
	assert(scene.get("_conversation") == null)
	assert(scene.get("_last_outcome") == "accepted")
	world = scene.get("_world") as SandboxWorld
	assert(world.active_offer_id == old_offer_id)
	await RenderingServer.frame_post_draw
	_capture("generated-offers.png")
	var selected: String = old_offer_id # UI auto-selects next request after acceptance.
	var amount: int = int(world.offer_by_id(selected)["fare"])
	assert(world.active_offer_id == selected)
	assert(accept.disabled)
	world.advance(world.remaining_minutes)
	scene.call("_render")
	await process_frame
	assert(world.active_offer_id.is_empty() and world.credits == 12 + amount)
	await RenderingServer.frame_post_draw
	_capture("settled-demand.png")
	scene.call("_on_save")
	assert(FileAccess.file_exists(SandboxSave.PATH))
	scene.call("_on_new_seed")
	assert(world != scene.get("_world"))
	scene.call("_on_load")
	var recovered: SandboxWorld = scene.get("_world") as SandboxWorld
	assert(recovered.credits == 12 + amount)
	assert(recovered.offer_by_id(selected)["status"] == "completed")
	print("SANDBOX_SCENE_PASS")
	quit(0)

func _capture(name: String) -> void:
	var img: Image = get_root().get_texture().get_image()
	assert(img != null and img.get_width() >= 640)
	assert(img.save_png(SHOTS.path_join(name)) == OK)
