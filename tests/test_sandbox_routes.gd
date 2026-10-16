extends SceneTree
func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	var chosen: Dictionary={}
	for offer in world.open_offers():
		if offer["origin"]==world.player_district and offer["channel"]!="official": chosen=offer;break
	assert(not chosen.is_empty())
	var direct: Array[String]=SandboxRoads.path(world.player_district,str(chosen["destination"]))
	var alternate: Array[String]=SandboxRoads.path(world.player_district,str(chosen["destination"]),"depot")
	assert(SandboxRoads.valid_path(alternate) and alternate!=direct)
	assert(SandboxRoads.path_minutes(alternate)>SandboxRoads.path_minutes(direct))
	assert(SandboxRoads.path_expense(alternate)>0)
	assert(not world.accept(chosen["id"],"invalid"))
	assert(world.accept(chosen["id"],"depot"))
	assert(world.route_nodes==alternate)
	assert(not world.accept(chosen["id"]))
	assert(world.advance(1))
	var mid: Dictionary=world.snapshot()
	assert(SandboxSave.save_world(world,"user://city-route.json"))
	var resumed: SandboxWorld=SandboxSave.load_world("user://city-route.json")
	assert(resumed!=null and resumed.snapshot()==mid)
	assert(world.advance(world.remaining_minutes) and resumed.advance(resumed.remaining_minutes))
	assert(world.snapshot()==resumed.snapshot())
	assert(world.credits==12+int(chosen["fare"])-SandboxRoads.path_expense(alternate))
	assert(world.risk==SandboxRoads.path_exposure(alternate)+(1 if chosen["channel"]=="underground" else 0))
	var segments: int=0;var settlements: int=0
	for evt in world.events:
		if evt["kind"]=="route_segment_completed": segments+=1
		if evt["kind"]=="fare_settled": settlements+=1
	assert(segments==alternate.size()-1 and settlements==1)
	var money: int=world.credits
	world.advance(20);assert(world.credits==money)
	var forged: Dictionary=mid.duplicate(true);forged["route_nodes"]=["garage","market"]
	assert(not SandboxWorld.new().restore_snapshot(forged))
	forged=mid.duplicate(true);forged["remaining_minutes"]+=1
	assert(not SandboxWorld.new().restore_snapshot(forged))
	print("SANDBOX_ROUTES_PASS")
	quit()
