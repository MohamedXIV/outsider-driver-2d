extends SceneTree
const NativeRouteChecks=preload("res://tests/native_route_checks.gd")

func _initialize() -> void:
	call_deferred("_walk")


func _walk() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/od2d-ink-evidence/sandbox")
	var scene: Node2D = (load("res://scenes/sandbox.tscn") as PackedScene).instantiate()
	get_root().add_child(scene)
	scene._player_ui.toggle_debug()
	await process_frame
	await process_frame
	var world: SandboxWorld = scene.get("_world")
	var ar: Button = scene.get_node("HUD/ARContext")
	assert(not ar.visible)
	scene.call("_on_starter_device", "gps")
	scene.call("_on_drive_market")
	NativeRouteChecks.finish(world)
	scene.call("_render")
	assert(world.player_district == "market" and world.knows("map:district-graph"))
	scene.get_node("HUD/WorldPanel/Content/ARActions/BuyAR").pressed.emit()
	assert(world.ar_owned and not world.ar_equipped and world.credits == 5)
	scene.get_node("HUD/WorldPanel/Content/ARActions/WearAR").pressed.emit()
	assert(world.ar_equipped)
	var talk: Button = scene.get_node("HUD/DockPanel/Content/Actions/Talk")
	talk.pressed.emit()
	await process_frame
	var dialog: SandboxConversation = scene.get("_conversation")
	assert(dialog != null and not dialog.understood() and not ar.visible)
	world.resident("npc:04")["need"]=70 # Comprehensible AR-context fixture; Common refusal covered in domain tests.
	scene.get_node("HUD/DialoguePanel/Content/RequestCommon").pressed.emit()
	await process_frame
	dialog = scene.get("_conversation")
	assert(dialog != null and dialog.understood())
	scene.call("_on_dialogue_choice", 0)
	await process_frame
	assert(ar.visible)
	var note: Dictionary = scene.get("_ar_note")
	assert(note["certainty"] == "verified")
	assert(str(note["source"]).contains("starter:gps"))
	ar.grab_focus()
	await process_frame
	assert((scene.get_node("HUD/ARHintPanel") as PanelContainer).visible)
	await RenderingServer.frame_post_draw
	assert(get_root().get_texture().get_image().save_png(
			"/tmp/od2d-ink-evidence/sandbox/ar-verified-native.png") == OK)
	scene.get_node("HUD/ARHintPanel/Content/Close").pressed.emit()
	assert(not (scene.get_node("HUD/ARHintPanel") as PanelContainer).visible)
	scene.call("_on_wear_ar")
	assert(not world.ar_equipped and not ar.visible)
	scene.call("_on_wear_ar")
	assert(world.ar_equipped and ar.visible)
	scene.call("_on_save")
	scene.call("_on_new_seed")
	scene.call("_on_load")
	world = scene.get("_world")
	assert(world.ar_owned and world.ar_equipped)
	assert(ar.visible and str(scene.get("_ar_note").get("certainty")) == "verified")
	print("SANDBOX_AR_SCENE_PASS")
	quit(0)
