extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _quad(body: SandboxWorldVehicleBody) -> PackedVector2Array:
	var polygon: PackedVector2Array=[]
	for corner in [Vector2(-12.5,-6.5),Vector2(12.5,-6.5),Vector2(12.5,6.5),Vector2(-12.5,6.5)]: polygon.append(body.global_transform*corner)
	return polygon
func _run() -> void:
	var world: SandboxWorld=SandboxWorld.new(1)
	assert(world.reposition("docks","clinic") and world.advance(41))
	# Hold the actual player journey while the independent city generates the
	# genuine npc:08 municipal trip. No resident, offer or fare is injected.
	assert(SandboxVehicleExecution.bind(world,"player") and world.advance(10))
	assert(world.resident("npc:08").get("transit_method","")=="shuttle")
	var corridor: SandboxWorldVehicleCorridor=SandboxWorldVehicleCorridor.new()
	root.add_child(corridor);corridor.attach(world)
	assert(corridor.bodies.has("player") and corridor.bodies.has("npc:08"))
	await physics_frame
	var queued: bool=false
	var finished: bool=false
	var restored: bool=false
	for frame in range(1200):
		world.vehicle_fraction=float(frame%60)/60.0
		corridor.step(1.0/60.0)
		var taxi: SandboxWorldVehicleBody=corridor.bodies["player"]
		var shuttle: SandboxWorldVehicleBody=corridor.bodies["npc:08"]
		for overlap in Geometry2D.intersect_polygons(_quad(taxi),_quad(shuttle)):
			assert(SandboxIsoPresentation.polygon_area(overlap)<.001,"Two genuine World vehicle footprints overlap")
		queued=queued or world.vehicle_execution["player"]["reason"]=="junction" or world.vehicle_execution["npc:08"]["reason"]=="junction"
		if not restored and not world.vehicle_junctions.is_empty() and float(world.vehicle_execution["npc:08"]["progress"])>9.7:
			var copy: SandboxWorld=SandboxWorld.new()
			assert(copy.restore_snapshot(world.snapshot()))
			var taxi_pose: Transform2D=taxi.transform
			var shuttle_pose: Transform2D=shuttle.transform
			corridor.attach(copy);world=copy
			assert(corridor.bodies["player"].transform.is_equal_approx(taxi_pose))
			assert(corridor.bodies["npc:08"].transform.is_equal_approx(shuttle_pose))
			restored=true
		if float(world.vehicle_execution["player"]["progress"])>45.0 and float(world.vehicle_execution["npc:08"]["progress"])>11.0:
			finished=true;break
		if (frame+1)%60==0: assert(world.advance_elapsed(1))
		await physics_frame
	assert(queued and restored and finished,"Both automatic real vehicles must drain the saved conflict")
	assert(world.vehicle_junctions.is_empty() and world.residents.size()==9)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	print("WORLD_VEHICLE_CONFLICT_PASS automatic genuine taxi/shuttle, no overlap, exclusive saved turn, exact body reload, both drain")
	quit()
