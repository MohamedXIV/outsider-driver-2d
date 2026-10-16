extends SceneTree
const SHOTS: String="/tmp/od2d-city-evidence"
var scene: Node
var world: SandboxWorld
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	scene=load("res://scenes/sandbox.tscn").instantiate();root.add_child(scene)
	scene.set_process(false);world=scene._world
	await shot("01-player-outer-margin")
	scene._on_talk();await shot("02-passenger-dialogue")
	var before: Dictionary=world.snapshot()
	scene._player_ui.toggle_debug();assert(world.snapshot()==before)
	await shot("03-debug-same-world")
	scene._player_ui.toggle_debug();assert(world.snapshot()==before)
	scene._on_ask_common();scene._route_waypoint="depot";scene._on_dialogue_choice(1)
	assert(world.is_travelling());scene._on_talk()
	world.advance(12);scene._elapsed=.4;scene._city.visual_fraction=.4
	scene._on_save();var at: Vector3=world.player_position(.4)
	scene._on_load();world=scene._world
	assert(world.player_position(scene._elapsed).distance_to(at)<.01)
	await shot("04-long-city-ride")
	world.advance(world.remaining_minutes);scene._render()
	assert(scene._conversation!=null and scene._conversation.still_valid(world))
	await shot("05-arrival-readable")
	scene._on_dialogue_choice(2)
	assert(world.reposition("clinic"));world.advance(world.remaining_minutes)
	assert(world.reposition("depot","",["basin_turn","market","margin_gate","bridge_east","bridge_west"]))
	assert(world.route_nodes.has("basin_turn") and world.route_nodes.has("bridge_west"))
	var captured: Dictionary={}
	while world.is_travelling():
		var a: String=world.route_nodes[world.route_segment]
		var b: String=world.route_nodes[world.route_segment+1]
		var phase: String=""
		if a=="basin_turn" and b=="market": phase="06-underpass"
		elif a=="margin_gate" and b=="bridge_east": phase="07-ramp"
		elif a=="bridge_east" and b=="bridge_west": phase="08-deck"
		elif a=="bridge_west" and b=="worker_gate": phase="09-connected-descent"
		if not phase.is_empty() and not captured.has(phase) and world.route_edge_elapsed>=int(SandboxRoads.edge_minutes(a,b)*(.7 if phase=="06-underpass" else .5)):
			captured[phase]=true;scene._city.visual_fraction=.3
			await shot(phase)
		world.advance(1)
	assert(captured.size()==4)
	await shot("10-worker-belt-arrival")
	scene._player_ui._tab("settings");scene._on_language_locale("ar");scene._on_reduced_motion(true)
	await shot("11-arabic-player")
	print("CITY_PRESENTATION_PASS native frames, shared views, fractional save, readable arrival, underpass-ramp-deck-descent")
	quit()
func shot(label: String) -> void:
	scene._render()
	await process_frame;await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(SHOTS.path_join(label+".png"))==OK)
	var file: FileAccess=FileAccess.open(SHOTS.path_join(label+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"minute":world.minute,"node":world.player_district,"position":str(world.player_position(scene._city.visual_fraction)),"route":world.route_nodes,"segment":world.route_segment,"edge_elapsed":world.route_edge_elapsed}))
