extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	var city: Node=scene._city
	assert(city.get("_layers") is Dictionary,"Static city and moving actors need separate redraw layers")
	await process_frame;await process_frame
	assert(city._layers.size()==4)
	assert(city._layers["ground"].z_index<city._layers["deck"].z_index)
	assert(city._layers["above"].z_index>city._layers["deck"].z_index)
	var before: Dictionary=scene._world.snapshot()
	city.visual_fraction=.6
	await process_frame
	assert(scene._world.snapshot()==before,"Rendering never advances world time")
	print("CITY_RENDER_CACHE_PASS retained static layers, dynamic actors and correct deck order")
	quit()
