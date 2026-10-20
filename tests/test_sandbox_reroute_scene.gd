extends SceneTree
const NativeRouteChecks=preload("res://tests/native_route_checks.gd")

const SHOTS: String = "/tmp/od2d-ink-evidence/sandbox"

func _initialize() -> void:
	call_deferred("_walkthrough")

func _walkthrough() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	var scene: Node2D = load("res://scenes/sandbox.tscn").instantiate() as Node2D
	get_root().add_child(scene)
	scene._player_ui.toggle_debug()
	await process_frame
	await process_frame
	var world: SandboxWorld = scene.get("_world") as SandboxWorld
	var via: OptionButton = scene.get_node("HUD/RoutePanel/Content/Via") as OptionButton
	var honor: Button = scene.get_node("HUD/RoutePanel/Content/RouteActions/Honor") as Button
	var rider_info: Label = scene.get_node("HUD/RoutePanel/Content/RiderInfo") as Label
	var i: int = -1
	for j in range(via.item_count):
		if via.get_item_metadata(j) == "depot":
			i = j
	assert(i >= 0)
	via.item_selected.emit(i)
	scene.call("_on_accept")
	await process_frame
	assert(world.rider_route_request.get("status") == "pending")
	assert(honor.visible and rider_info.visible)
	assert(not rider_info.text.is_empty())
	honor.pressed.emit()
	await process_frame
	assert(world.rider_route_request["status"] == "accepted")
	assert(world.pending_route_nodes.size() >= 2)
	await RenderingServer.frame_post_draw
	_capture("rider-reroute-queued.png")
	scene.call("_on_save")
	scene.call("_on_load")
	var recovered: SandboxWorld = scene.get("_world") as SandboxWorld
	assert(recovered.pending_route_nodes == world.pending_route_nodes)
	recovered.advance(SandboxRoads.edge_minutes(recovered.route_nodes[0],recovered.route_nodes[1]))
	for physical_delay in range(60):
		if recovered.pending_route_nodes.is_empty(): break
		assert(recovered.advance(1))
	assert(recovered.pending_route_nodes.is_empty(),"The real taxi must reach its queued junction")
	scene.call("_render")
	await process_frame
	assert(recovered.route_nodes[0] == "margin_gate" and recovered.route_segment == 0)
	await RenderingServer.frame_post_draw
	_capture("rider-reroute-junction.png")
	NativeRouteChecks.finish(recovered)
	scene.call("_render")
	assert(recovered.active_offer_id.is_empty())
	await RenderingServer.frame_post_draw
	_capture("rider-reroute-arrived.png")
	print("SANDBOX_REROUTE_SCENE_PASS")
	quit(0)

func _capture(name: String) -> void:
	var img: Image = get_root().get_texture().get_image()
	assert(img.save_png(SHOTS.path_join(name)) == OK)
