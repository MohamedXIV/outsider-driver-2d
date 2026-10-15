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
	var via: OptionButton = scene.get_node("HUD/RoutePanel/Content/Via") as OptionButton
	var preview: Label = scene.get_node("HUD/RoutePanel/Content/Preview") as Label
	var chosen: Dictionary = world.offer_by_id(str(scene.get("_selected_id")))
	assert(chosen["origin"] == "docks" and chosen["destination"] == "shelter")
	assert(via.item_count > 1 and not via.disabled)
	await RenderingServer.frame_post_draw
	_capture("route-default.png")
	var alternate_index: int = -1
	for i in range(via.item_count):
		if str(via.get_item_metadata(i)) == "depot":
			alternate_index = i
	assert(alternate_index >= 0)
	via.item_selected.emit(alternate_index)
	assert(scene.get("_route_waypoint") == "depot")
	assert(preview.text.contains("30 min") and preview.text.contains("2 cr"))
	await RenderingServer.frame_post_draw
	_capture("route-via-depot.png")
	var accept: Button = scene.get_node("HUD/DockPanel/Content/Actions/Accept") as Button
	accept.pressed.emit()
	assert(world.active_offer_id == chosen["id"])
	assert(world.route_nodes == ["docks", "depot", "shelter"])
	world.advance(20)
	scene.call("_render")
	await process_frame
	assert(world.player_district == "depot" and world.route_edge_elapsed == 10)
	await RenderingServer.frame_post_draw
	_capture("route-mid-edge.png")
	scene.call("_on_save")
	scene.call("_on_load")
	var recovered: SandboxWorld = scene.get("_world") as SandboxWorld
	assert(recovered.route_edge_elapsed == 10 and recovered.route_nodes == world.route_nodes)
	recovered.advance(10)
	scene.call("_render")
	await RenderingServer.frame_post_draw
	_capture("route-arrived.png")
	assert(recovered.active_offer_id.is_empty() and recovered.offer_by_id(chosen["id"])["status"] == "completed")
	print("SANDBOX_ROUTES_SCENE_PASS")
	quit(0)

func _capture(name: String) -> void:
	var img: Image = get_root().get_texture().get_image()
	assert(img != null and img.get_width() >= 640)
	assert(img.save_png(SHOTS.path_join(name)) == OK)
