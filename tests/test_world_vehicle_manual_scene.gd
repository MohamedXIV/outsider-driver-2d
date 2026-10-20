extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _quad(body: SandboxWorldVehicleBody) -> PackedVector2Array:
	var polygon: PackedVector2Array=[]
	for corner in [Vector2(-12.5,-6.5),Vector2(12.5,-6.5),Vector2(12.5,6.5),Vector2(-12.5,6.5)]: polygon.append(body.global_transform*corner)
	return polygon
func _run() -> void:
	var app: Node=load("res://scenes/sandbox.tscn").instantiate()
	app._world=SandboxWorld.new(8);root.add_child(app)
	await process_frame
	app.set_process(false)
	assert(app._world.reposition("clinic") and app._world.advance(3))
	app._on_save();app._on_load()
	for minute in range(120):
		if not app._world.is_travelling(): break
		assert(app._world.advance(1))
	assert(not app._world.is_travelling() and app._world.player_district=="clinic")
	app._on_save();app._on_load()
	assert(app._world.reposition("docks"))
	var genuine_pair: bool=false
	# No engine physics frame occurs between these manual World minutes.
	for minute in range(120):
		if not app._world.is_travelling(): break
		assert(app._world.advance(1))
		var vehicles: Array=app._vehicle_corridor.bodies.values()
		if vehicles.size()>1: genuine_pair=true
		for first in range(vehicles.size()):
			for second in range(first+1,vehicles.size()):
				for overlap in Geometry2D.intersect_polygons(_quad(vehicles[first]),_quad(vehicles[second])):
					assert(SandboxIsoPresentation.polygon_area(overlap)<.001,"Manual time must not overlap genuine taxi and shuttle footprints")
	assert(genuine_pair and not app._world.is_travelling() and app._world.player_district=="docks")
	var via: Array[String]=["clinic","basin_turn"]
	assert(app._world.reposition("market","",via))
	for minute in range(150):
		if not app._world.is_travelling(): break
		assert(app._world.advance(1))
		var vehicles: Array=app._vehicle_corridor.bodies.values()
		for first in range(vehicles.size()):
			for second in range(first+1,vehicles.size()):
				for overlap in Geometry2D.intersect_polygons(_quad(vehicles[first]),_quad(vehicles[second])):
					assert(SandboxIsoPresentation.polygon_area(overlap)<.001,"Clinic frontage admission must preserve physical separation")
	assert(not app._world.is_travelling() and app._world.player_district=="market","The actual shuttle merge and incoming taxi must both drain")
	assert(app._world.residents.size()==9 and SandboxWorld.new().restore_snapshot(app._world.snapshot()))
	assert(not app._world.events.any(func(e: Dictionary)->bool:return e["kind"]=="fare_settled"))
	print("WORLD_VEHICLE_MANUAL_PASS genuine taxi/shuttle, manual-time clearance, saved clinic departure, no fake economy")
	quit()
