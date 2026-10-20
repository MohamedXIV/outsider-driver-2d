extends SceneTree
var frames: Array[Dictionary]=[]
var game: Node
var body: SandboxWorldVehicleBody
var blocker: StaticBody2D
var output: String="res://work/vehicle-native-frames"
func _initialize() -> void: call_deferred("_run")
func capture(label: String) -> void:
	game._render()
	await process_frame
	await RenderingServer.frame_post_draw
	var state: Dictionary=game._world.vehicle_execution["player"]
	var path: String=ProjectSettings.globalize_path(output+"/%02d-%s.png"%[frames.size(),label])
	root.get_texture().get_image().save_png(path)
	var canonical: Vector3=game._world.player_position()
	var rendered: Vector2=SandboxDirectedLanes.taxi_screen(game._world,0.0)
	assert(rendered.distance_to(body.position)<.001)
	frames.append({"world_position":{"x":canonical.x,"y":canonical.y,"z":canonical.z},"render_position":{"x":rendered.x,"y":rendered.y},"label":label,"world_minute":game._world.minute,"population":game._world.residents.size(),"vehicle_id":"player","source":state["source"],"progress":state["progress"],"x":body.position.x,"y":body.position.y,"heading":body.rotation,"speed":state["speed"],"reason":state["reason"],"remaining_minutes":game._world.remaining_minutes})
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	assert(game._world.reposition("market","margin_gate"))
	game._city.reduced_motion=true
	body=SandboxWorldVehicleBody.new()
	game.add_child(body)
	assert(body.bind(game._world,"player"))
	blocker=StaticBody2D.new()
	blocker.collision_layer=16;blocker.collision_mask=16
	var shape: CollisionShape2D=CollisionShape2D.new()
	var rectangle: RectangleShape2D=RectangleShape2D.new()
	rectangle.size=Vector2(30,30);shape.shape=rectangle
	blocker.add_child(shape)
	blocker.position=SandboxVehicleExecution.point(SandboxVehicleExecution.trip(game._world,"player"),1.8)
	blocker.draw.connect(func()->void:blocker.draw_rect(Rect2(-15,-15,30,30),Color("c8634d")))
	game.add_child(blocker)
	await physics_frame
	await capture("enter")
	for frame in range(120):
		assert(body.step(1.0/60.0))
		if (frame+1)%60==0: assert(game._world.advance_elapsed(1))
		await physics_frame
		if frame==29: await capture("approach")
	assert(float(game._world.vehicle_execution["player"]["speed"])<.01)
	await capture("held")
	var copy: SandboxWorld=SandboxWorld.new()
	assert(copy.restore_snapshot(game._world.snapshot()))
	body.queue_free()
	await physics_frame
	game._world=copy;game._city.world=copy
	body=SandboxWorldVehicleBody.new();game.add_child(body)
	assert(body.bind(copy,"player"))
	await physics_frame
	await capture("restored")
	assert(Vector2(frames[2]["x"],frames[2]["y"]).distance_to(body.position)<.001)
	blocker.queue_free();await physics_frame
	for frame in range(60):
		assert(body.step(1.0/60.0))
		await physics_frame
	assert(game._world.advance_elapsed(1))
	assert(body.position.distance_to(Vector2(frames[2]["x"],frames[2]["y"]))>1.0)
	await capture("depart")
	var file: FileAccess=FileAccess.open(ProjectSettings.globalize_path(output+"/frames.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(frames,"  "));file.close()
	print("WORLD_VEHICLE_COLLISION_CAPTURE_PASS controlled real route, native obstacle, World wait, saved body, coherent departure")
	quit()
