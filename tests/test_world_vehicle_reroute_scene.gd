extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var world: SandboxWorld=SandboxWorld.new(9)
	var offer: Dictionary={}
	for item in world.open_offers():
		if item["origin"]=="garage" and SandboxPassengerAlight.applicable(item): offer=item;break
	assert(not offer.is_empty() and world.accept(str(offer["id"])))
	var boundary: float=SandboxRoads.edge_minutes(world.route_nodes[0],world.route_nodes[1])
	assert(world.advance(int(boundary)-1))
	var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(body);assert(body.bind(world,"player"))
	await physics_frame
	for frame in range(180):
		assert(body.step(1.0/60.0))
		if float(world.vehicle_execution["player"]["progress"])>boundary+.1: break
		await physics_frame
	assert(float(world.vehicle_execution["player"]["progress"])>boundary)
	body.release(0.0)
	assert(world.queue_reroute("depot"))
	var old_travel: Dictionary=SandboxVehicleExecution.trip(world,"player")
	var expected: Vector2=SandboxVehicleExecution.point(old_travel,float(world.vehicle_execution["player"]["progress"])+1.0)
	var before: Dictionary=world.snapshot()
	assert(world.advance(1))
	var after: Dictionary=world.snapshot()
	FileAccess.open("res://work/reroute-handoff-repro.json",FileAccess.WRITE).store_string(JSON.stringify({"before":before,"after":after,"expected":[expected.x,expected.y],"render":str(SandboxDirectedLanes.taxi_screen(world,0.0))},"  "))
	if not world.vehicle_execution.has("player"):
		push_error("A real queued reroute discarded the physical handoff cursor at the canonical junction");quit(1);return
	assert(SandboxDirectedLanes.taxi_screen(world,0.0).distance_to(expected)<.001)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	var forged: Dictionary=world.snapshot()
	forged["vehicle_execution"]["player"].erase("incoming_node")
	assert(not SandboxWorld.new().restore_snapshot(forged))
	assert(await _native_turn())
	print("REROUTE_HANDOFF_PASS actual Native handoff, retained driven prefix, saved incoming context and live mid-turn rebase")
	quit()

func _native_turn() -> bool:
	var world: SandboxWorld=SandboxWorld.new(8)
	var offer: Dictionary={}
	for candidate in world.open_offers():
		if candidate["origin"]=="garage" and candidate["destination"]=="market": offer=candidate;break
	assert(not offer.is_empty() and world.accept(str(offer["id"]),"docks"))
	var clinic: int=world.route_nodes.find("clinic")
	assert(clinic>0)
	var boundary: float=0.0
	for index in range(clinic): boundary+=SandboxRoads.edge_minutes(world.route_nodes[index],world.route_nodes[index+1])
	assert(world.advance(int(boundary)-1))
	var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(body);assert(body.bind(world,"player"))
	await physics_frame
	for frame in range(240):
		assert(body.step(1.0/60.0))
		if float(world.vehicle_execution["player"]["progress"])>boundary+.1: break
		await physics_frame
	assert(float(world.vehicle_execution["player"]["progress"])>boundary)
	assert(world.vehicle_junctions.get("clinic",{}).get("vehicle","")=="player")
	var before: Transform2D=body.transform
	assert(world.queue_reroute("old_square"))
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	assert(world.advance(1))
	assert(world.vehicle_execution.has("player") and body.transform.is_equal_approx(before))
	assert(SandboxVehicleExecution.screen(world,"player").distance_to(body.position)<.001)
	assert(world.vehicle_junctions.get("clinic",{}).get("kind","")=="carried_turn")
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	for frame in range(60):
		assert(body.step(1.0/60.0));await physics_frame
	assert(body.position.distance_to(before.origin)>1.0)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	body.release(0.0);body.queue_free();await physics_frame
	return true
