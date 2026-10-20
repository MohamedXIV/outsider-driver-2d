extends SceneTree
const NativeRouteChecks=preload("res://tests/native_route_checks.gd")

# Native Linux-visible physical market + installed/absent Ink comprehension.
const SHOTS: String = "/tmp/od2d-ink-evidence/sandbox"

func _initialize() -> void:
	call_deferred("_walkthrough")


func _walkthrough() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	var packed: PackedScene = load("res://scenes/sandbox.tscn")
	assert(packed != null)
	var scene: Node2D = packed.instantiate() as Node2D
	get_root().add_child(scene)
	scene._player_ui.toggle_debug()
	await process_frame
	await process_frame
	var world: SandboxWorld = scene.get("_world") as SandboxWorld
	var list: ItemList = scene.get_node("HUD/DockPanel/Content/Offers") as ItemList
	assert(world.residents.size() == 9 and list.item_count > 1)
	assert(world.modules_installed == ["trade"])
	var talk: Button = scene.get_node("HUD/DockPanel/Content/Actions/Talk") as Button
	var choices: VBoxContainer = scene.get_node("HUD/DialoguePanel/Content/Choices")
	talk.pressed.emit()
	await process_frame
	var unfamiliar: SandboxConversation = scene.get("_conversation") as SandboxConversation
	assert(unfamiliar != null and not unfamiliar.understood())
	await RenderingServer.frame_post_draw
	_capture("uninstalled-local.png")
	var district: OptionButton = scene.get_node("HUD/DockPanel/Content/Navigation/District")
	district.select(1)
	scene.call("_on_reposition")
	var moving_world: SandboxWorld=scene.get("_world")
	if moving_world.is_travelling(): NativeRouteChecks.finish(moving_world)
	scene.call("_render")
	await process_frame
	assert(world.player_district == "market" and world.credits == 10)
	var buy: Button = scene.get_node("HUD/GearPanel/Content/MarketBuy/BuyLocal")
	var install: Button = scene.get_node("HUD/GearPanel/Content/MarketInstall/InstallLocal")
	assert(not buy.disabled and install.disabled)
	var market_index: int = -1
	for i in range(list.item_count):
		if str(list.get_item_metadata(i)).contains("npc:04"):
			market_index = i
	assert(market_index >= 0)
	scene.call("_on_selected", market_index)
	talk.pressed.emit()
	await process_frame
	assert(not (scene.get("_conversation") as SandboxConversation).understood())
	await RenderingServer.frame_post_draw
	_capture("market-before-module.png")
	buy.pressed.emit()
	await process_frame
	assert(world.credits == 2 and world.modules_owned.has("local"))
	assert(not world.modules_installed.has("local") and buy.disabled and not install.disabled)
	await RenderingServer.frame_post_draw
	_capture("physical-module-purchased.png")
	install.pressed.emit()
	await process_frame
	assert(world.modules_installed.has("local") and install.disabled)
	talk.pressed.emit()
	await process_frame
	var translated: SandboxConversation = scene.get("_conversation") as SandboxConversation
	assert(translated != null and translated.understood())
	(choices.get_child(0) as Button).pressed.emit()
	await process_frame
	assert(str(translated.current_frame()["text"]).contains("heading to"))
	await RenderingServer.frame_post_draw
	_capture("installed-local-dialogue.png")
	scene.call("_on_save")
	var selected: String = translated.offer_id
	scene.call("_on_new_seed")
	scene.call("_on_load")
	var recovered: SandboxWorld = scene.get("_world") as SandboxWorld
	var pending: SandboxConversation = scene.get("_conversation") as SandboxConversation
	assert(recovered.credits == 2 and recovered.modules_installed.has("local"))
	assert(recovered.market_stock["local"] == 0)
	assert(pending != null and pending.offer_id == selected and pending.understood())
	await RenderingServer.frame_post_draw
	_capture("installed-module-restored.png")
	(choices.get_child(0) as Button).pressed.emit()
	await process_frame
	assert(recovered.active_offer_id == selected)
	scene.call("_render")
	await RenderingServer.frame_post_draw
	_capture("generated-offers.png")
	NativeRouteChecks.finish(recovered,true)
	scene.call("_render")
	await RenderingServer.frame_post_draw
	_capture("settled-demand.png")
	assert(recovered.offer_by_id(selected)["status"] == "completed")
	print("SANDBOX_SCENE_PASS")
	quit(0)


func _capture(name: String) -> void:
	var img: Image = get_root().get_texture().get_image()
	assert(img != null and img.get_width() >= 640)
	assert(img.save_png(SHOTS.path_join(name)) == OK)
