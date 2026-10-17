extends SceneTree

const SHOTS: String="/tmp/od2d-city-evidence"
var scene: Node

func _initialize() -> void: call_deferred("_run")

func _press(id: String) -> void:
	var button: BaseButton=scene._player_ui._actions.get(id)
	assert(button!=null and button.is_visible_in_tree() and not button.disabled,"Visible Player action: "+id)
	button.pressed.emit()
	await process_frame

func _run() -> void:
	scene=load("res://scenes/sandbox.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	await process_frame;await process_frame
	assert(not scene._player_ui.debug_mode)
	scene._player_ui._tab("map")
	var picker: OptionButton=scene._player_ui._actions["via"]
	for i in range(picker.item_count):
		if picker.get_item_metadata(i)=="depot":
			picker.select(i);picker.item_selected.emit(i);break
	await _press("plan_fare")
	await _press("accept")
	assert(scene._world.route_nodes.has("depot"))
	var longer: Dictionary=await _drive("native-long-journey",1)
	await _press("choice_2")
	var shorter_id: String=""
	for attempt in range(150):
		for offer in scene._world.open_offers():
			if offer["origin"]!=scene._world.player_district or offer["channel"]=="official": continue
			var route: Array[String]=SandboxRoads.path(offer["origin"],offer["destination"])
			if SandboxRoads.path_minutes(route)>0 and SandboxRoads.path_minutes(route)<longer["minutes"]:
				shorter_id=offer["id"];break
		if not shorter_id.is_empty(): break
		await _press("wait") # Real world-owned demand; no fabricated passenger.
	assert(not shorter_id.is_empty())
	await _press("fare_"+shorter_id)
	await _press("accept")
	var shorter: Dictionary=await _drive("native-short-journey",2)
	assert(shorter["minutes"]<longer["minutes"] and shorter["nodes"]!=longer["nodes"])
	await _press("choice_2")
	assert(scene._world.residents.size()==9 and not scene._player_ui.debug_mode)
	print("CITY_JOURNEYS_SCENE_PASS ",JSON.stringify({"long":longer,"short":shorter}))
	quit()

func _drive(label: String,settlements: int) -> Dictionary:
	var world: SandboxWorld=scene._world
	var offer: Dictionary=world.offer_by_id(world.active_offer_id)
	var metrics: Dictionary={"offer":offer["id"],"resident":offer["npc_id"],
		"minutes":world.remaining_minutes,"metres":SandboxRoads.path_metres(world.route_nodes),
		"nodes":world.route_nodes.duplicate()}
	await _press("talk")
	await _press("choice_0") # Real authored in-ride speech act.
	var saved: bool=false
	for frame in range(1200):
		# Accelerate controller time for QA; locomotion still runs in Godot's
		# actual physics frames, and every crossing hold remains enforced.
		scene._process(.5)
		await physics_frame
		if not saved and scene._world.remaining_minutes<int(metrics["minutes"])/2:
			assert(scene._world.is_travelling())
			var at: Vector3=scene._world.player_position(scene._elapsed)
			scene._player_ui._tab("settings");await _press("save")
			assert(scene._notice_text=="Sandbox saved.")
			await _press("load")
			assert(scene._world.player_position(scene._elapsed).distance_to(at)<.001)
			assert(scene._conversation!=null and scene._conversation.still_valid(scene._world))
			scene._player_ui._tab("requests");await _shot(label+"-restored",metrics)
			saved=true
		if not scene._world.is_travelling(): break
	assert(saved and not scene._world.is_travelling())
	assert(scene._settled_count()==settlements)
	var balance: int=scene._world.credits
	scene._process(1.0)
	assert(scene._settled_count()==settlements and scene._world.credits==balance)
	assert(scene._conversation!=null and scene._conversation.still_valid(scene._world))
	await _shot(label+"-arrived",metrics)
	return metrics

func _shot(label: String,metrics: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	scene._city._camera_initialized=false
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(SHOTS.path_join(label+".png"))==OK)
	var file: FileAccess=FileAccess.open(SHOTS.path_join(label+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics))
