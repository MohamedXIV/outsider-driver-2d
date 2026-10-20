extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var world: SandboxWorld=SandboxWorld.new(9)
	var id: String=""
	for tick in range(500):
		for npc in world.residents:
			if npc.get("transit_method","")=="shuttle" and npc.get("transit_to","")=="clinic": id=str(npc["id"]);break
		if not id.is_empty(): break
		assert(world.advance(1))
	assert(not id.is_empty(),"The city must supply the real shuttle")
	var npc: Dictionary=world.resident(id)
	var remaining: int=int(npc["transit_until"])-world.minute
	assert(world.advance(maxi(1,remaining-2)))
	var source: String=str(npc["transit_from_offer"])+":"+str(npc["transit_started"])
	var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(body);assert(body.bind(world,id))
	_check_arrival_merge(world,id)
	await physics_frame
	var arrived: bool=false
	for frame in range(1200):
		assert(body.step(1.0/60.0))
		if (frame+1)%60==0:
			assert(world.advance_elapsed(1))
			if npc.get("transit_method","")=="": arrived=true;break
		await physics_frame
	assert(arrived)
	var service: Dictionary=world.snapshot().get("vehicle_departures",{}).get("shuttle:"+source,{})
	if service.is_empty():
		push_error("The genuine shuttle disappeared at passenger arrival instead of retaining its World vehicle identity");quit(1);return
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	_check_departure_merge(world,source)
	assert(body.identity=="shuttle:"+source)
	var before: Vector2=body.position
	var service_id: String="shuttle:"+source
	assert(SandboxVehicleDepartures.screen(world,service_id).distance_to(before)<.001)
	var passenger: Vector2=SandboxVehicleDepartures.resident_screen(world,npc)
	assert(is_equal_approx(passenger.distance_to(before),SandboxVehicleBays.DOOR_CLEARANCE))
	var bad: Dictionary=world.snapshot()
	bad["vehicle_departures"][service_id]["x"]+=10.0
	assert(not SandboxWorld.new().restore_snapshot(bad))
	bad=world.snapshot();bad["vehicle_departures"]={}
	assert(not SandboxWorld.new().restore_snapshot(bad))
	body.queue_free();await physics_frame
	var departing: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(departing);assert(departing.bind(world,service_id))
	assert(departing.identity==service_id)
	assert(departing.position.distance_to(before)<.001)
	for frame in range(120):
		assert(departing.step(1.0/60.0))
		if (frame+1)%60==0: assert(world.advance_elapsed(1))
		await physics_frame
	assert(departing.position.distance_to(before)>1.0)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	departing.release(.4)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	assert(world.advance(2))
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	var corridor: SandboxWorldVehicleCorridor=SandboxWorldVehicleCorridor.new()
	root.add_child(corridor);corridor.attach(world)
	corridor._sync_curb_residents(passenger)
	assert(corridor.curb_residents.has(id))
	var resident_pose: Vector2=SandboxVehicleDepartures.resident_screen(world,npc,world.vehicle_fraction)
	assert(corridor.curb_residents[id].position.distance_to(resident_pose)<.001)
	corridor._sync_curb_residents(passenger+Vector2(1000,1000))
	assert(not corridor.curb_residents.has(id))
	corridor._sync_curb_residents(passenger)
	assert(corridor.curb_residents[id].position.distance_to(resident_pose)<.001)
	assert(world.residents.size()==9)
	print("WORLD_SHUTTLE_ARRIVAL_PASS source-owned public vehicle survives passenger arrival")
	quit()

func _check_departure_merge(original: SandboxWorld,source: String) -> void:
	var world: SandboxWorld=SandboxWorld.new()
	assert(world.restore_snapshot(original.snapshot()))
	var id: String="shuttle:"+source
	assert(SandboxVehicleExecution.bind(world,id))
	assert(world.reposition("docks","clinic") and world.advance(41))
	assert(SandboxVehicleExecution.bind(world,"player"))
	assert(SandboxVehicleJunctions.claim(world,"player"))
	if not is_finite(SandboxVehicleJunctions.stop_progress(world,id)):
		push_error("An empty shuttle can merge into a conflict reserved by the genuine taxi");quit(1);return
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))

func _check_arrival_merge(original: SandboxWorld,id: String) -> void:
	var world: SandboxWorld=SandboxWorld.new()
	assert(world.restore_snapshot(original.snapshot()))
	assert(world.reposition("docks","clinic") and world.advance(41))
	assert(SandboxVehicleExecution.bind(world,"player"))
	assert(SandboxVehicleJunctions.claim(world,"player"))
	if not is_finite(SandboxVehicleJunctions.stop_progress(world,id)):
		push_error("An arriving real shuttle ignores the taxi's exclusive clinic reservation");quit(1);return
