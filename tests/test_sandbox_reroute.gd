extends SceneTree

func _initialize() -> void:
	var world: SandboxWorld = SandboxWorld.new(8)
	var chosen: Dictionary = {}
	for offer in world.open_offers():
		if offer["origin"] == "docks" and offer["destination"] == "shelter" \
				and offer["channel"] != "official":
			chosen = offer
			break
	assert(not chosen.is_empty())
	var id: String = str(chosen["id"])
	var fare: int = int(chosen["fare"])
	assert(world.accept(id))
	assert(world.rider_route_request.is_empty())
	assert(not world.queue_reroute("clinic")) # Cyclic/unreachable continuation.
	assert(not world.queue_reroute("shelter")) # Same remaining path.
	assert(world.queue_reroute("depot"))
	assert(world.pending_route_nodes == ["market", "docks", "depot", "shelter"])
	assert(world.player_district == "docks" and world.route_nodes == ["docks", "market", "shelter"])
	assert(world.remaining_minutes == 50)
	var save_file: String = "user://route-p1-queued.json"
	assert(SandboxSave.save_world(world, save_file))
	var resumed: SandboxWorld = SandboxSave.load_world(save_file)
	assert(resumed != null and resumed.snapshot() == world.snapshot())
	assert(world.advance(10) and resumed.advance(10))
	assert(world.player_district == "market" and world.route_nodes == ["market", "docks", "depot", "shelter"])
	assert(world.pending_route_nodes.is_empty() and world.route_segment == 0)
	assert(world.remaining_minutes == 40)
	assert(resumed.snapshot() == world.snapshot())
	assert(world.advance(40) and resumed.advance(40))
	assert(world.snapshot() == resumed.snapshot())
	assert(world.active_offer_id.is_empty() and world.player_district == "shelter")
	assert(world.credits == 12 + fare - 2)
	var settled: int = 0
	var queued: int = 0
	var applied: int = 0
	for event in world.events:
		if event["kind"] == "fare_settled" and event["subject"] == id:
			settled += 1
		elif event["kind"] == "route_change_queued" and event["subject"] == id:
			queued += 1
		elif event["kind"] == "route_rerouted" and event["subject"] == id:
			applied += 1
	assert(settled == 1 and queued == 1 and applied == 1)
	var forged: Dictionary = SandboxWorld.new(8).snapshot()
	var b: SandboxWorld = SandboxWorld.new(8)
	assert(b.accept(id, "depot"))
	assert(b.route_nodes == ["docks", "depot", "shelter"])
	assert(b.rider_route_request.get("status") == "pending")
	assert(b.rider_route_request.get("via") == "market")
	var requester: String = str(chosen["npc_id"])
	var before_trust: int = int(b.resident(requester)["trust"])
	assert(b.respond_rider_route(true))
	assert(b.rider_route_request["status"] == "accepted")
	assert(int(b.resident(requester)["trust"]) == before_trust + 1)
	assert(b.pending_route_nodes == ["depot", "docks", "market", "shelter"])
	assert(not b.respond_rider_route(true))
	assert(b.advance(10))
	assert(b.player_district == "depot" and b.route_nodes[0] == "depot")
	assert(b.advance(30))
	assert(b.active_offer_id.is_empty() and int(b.resident(requester)["trust"]) == before_trust + 2)
	var rejected: SandboxWorld = SandboxWorld.new(8)
	assert(rejected.accept(id, "depot"))
	assert(rejected.respond_rider_route(false))
	assert(rejected.pending_route_nodes.is_empty())
	assert(rejected.rider_route_request["status"] == "declined")
	assert(int(rejected.resident(requester)["trust"]) == before_trust - 1)
	assert(rejected.advance(30))
	assert(int(rejected.resident(requester)["trust"]) == before_trust) # Fare +1, refusal -1.
	assert(rejected.credits == 12 + fare - 2)
	assert(rejected.snapshot() != b.snapshot())
	var pending: SandboxWorld = SandboxWorld.new(8)
	assert(pending.accept(id, "depot"))
	assert(pending.respond_rider_route(true))
	forged = pending.snapshot()
	forged["pending_route_nodes"] = ["clinic", "shelter"]
	assert(not SandboxWorld.new().restore_snapshot(forged))
	forged = pending.snapshot()
	forged["remaining_minutes"] = 10
	assert(not SandboxWorld.new().restore_snapshot(forged))
	print("SANDBOX_REROUTE_PASS")
	quit(0)
