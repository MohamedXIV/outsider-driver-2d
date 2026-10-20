extends SceneTree

# A real wait button must remain under the pointer while autonomous local
# offers appear/expire. A cached Player action bound must still hit Wait.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size=Vector2i(1280,720)
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene);scene.set_process(false)
	var ui: SandboxPlayerUI=scene._player_ui
	for frame in range(4): await process_frame
	var anchor: Vector2=ui._actions["wait"].get_global_rect().get_center()
	var previous_count: int=0
	for offer in scene._world.open_offers():
		if offer["origin"]==scene._world.player_district: previous_count+=1
	var down: InputEventMouseButton=InputEventMouseButton.new()
	down.position=anchor;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true
	Input.parse_input_event(down);await process_frame
	assert(ui._actions["wait"].is_pressed())
	var changed: bool=false
	for tick in range(200):
		scene._process(1.0)
		for frame in range(3): await process_frame
		var count: int=0
		for offer in scene._world.open_offers():
			if offer["origin"]==scene._world.player_district: count+=1
		if count==previous_count: continue
		changed=true
		var actual: Vector2=ui._actions["wait"].get_global_rect().get_center()
		print("WAIT_OFFER_TRANSITION minute=",scene._world.minute," offers=",previous_count," -> ",count," point=",anchor," -> ",actual)
		assert(anchor.distance_to(actual)<1.0,
				"Autonomous offers must not move Wait out from under a real player click")
		var serial: int=ui._action_serial
		var minute: int=scene._world.minute
		for pressed in [false]:
			var event: InputEventMouseButton=InputEventMouseButton.new()
			event.position=anchor;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
			Input.parse_input_event(event);await process_frame
		for frame in range(3): await process_frame
		assert(ui._action_serial==serial+1,"Exactly one real Wait click must be acknowledged")
		assert(scene._world.minute==minute+20,"Wait still advances the authoritative world, exactly once")
		break
	assert(changed,"The regression must exercise a genuine autonomous offer transition")
	print("PLAYER_WAIT_SCENE_PASS stable hit target across autonomous offer expiry, actual mouse input and once-only World command")
	quit()
