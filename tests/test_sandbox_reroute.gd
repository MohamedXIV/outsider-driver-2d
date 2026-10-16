extends SceneTree
func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	var chosen: Dictionary={}
	for offer in world.open_offers():
		if offer["origin"]==world.player_district and offer["channel"]!="official": chosen=offer;break
	assert(world.accept(chosen["id"]))
	assert(world.advance(1))
	var before: Vector3=world.player_position()
	assert(not world.queue_reroute("invalid"))
	assert(world.queue_reroute("depot"))
	assert(world.player_position()==before,"Queued turn must not teleport")
	var pending: Array[String]=world.pending_route_nodes.duplicate()
	var junction: String=world.route_nodes[world.route_segment+1]
	assert(pending.front()==junction and pending.has("depot"))
	var remaining_edge: int=SandboxRoads.edge_minutes(world.route_nodes[0],junction)-world.route_edge_elapsed
	assert(SandboxSave.save_world(world,"user://city-queued.json"))
	var resumed: SandboxWorld=SandboxSave.load_world("user://city-queued.json")
	assert(resumed!=null and resumed.snapshot()==world.snapshot())
	var forged: Dictionary=world.snapshot();forged["pending_route_nodes"]=["garage","terraces"]
	assert(not SandboxWorld.new().restore_snapshot(forged))
	assert(world.advance(remaining_edge) and resumed.advance(remaining_edge))
	assert(world.player_district==junction and world.route_nodes==pending and world.pending_route_nodes.is_empty())
	assert(world.snapshot()==resumed.snapshot())
	assert(world.advance(world.remaining_minutes) and resumed.advance(resumed.remaining_minutes))
	assert(world.snapshot()==resumed.snapshot())
	var paid: int=0;var queued: int=0;var applied: int=0
	for event in world.events:
		if event["kind"]=="fare_settled":paid+=1
		if event["kind"]=="route_change_queued":queued+=1
		if event["kind"]=="route_rerouted":applied+=1
	assert(paid==1 and queued==1 and applied==1)
	# Find an actual route preference rather than assuming a particular five-node graph.
	var checked: bool=false
	for via in SandboxRoads.DISTRICTS:
		var rider: SandboxWorld=SandboxWorld.new(8)
		if not rider.accept(chosen["id"],via) or rider.rider_route_request.is_empty(): continue
		var who: Dictionary=rider.resident(chosen["npc_id"])
		var trust: int=who["trust"]
		assert(rider.respond_rider_route(false))
		assert(who["trust"]==trust-1 and not rider.respond_rider_route(false))
		var agrees: SandboxWorld=SandboxWorld.new(8)
		assert(agrees.accept(chosen["id"],via))
		assert(agrees.respond_rider_route(true))
		assert(agrees.resident(chosen["npc_id"])["trust"]==trust+1)
		assert(not agrees.pending_route_nodes.is_empty())
		checked=true;break
	assert(checked,"A real metric route must provoke a grounded rider preference")
	print("SANDBOX_REROUTE_PASS")
	quit()
