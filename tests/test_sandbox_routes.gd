extends SceneTree

func _initialize() -> void:
	var default: Array[String] = SandboxRoads.path("docks", "shelter")
	var alternate: Array[String] = SandboxRoads.path("docks", "shelter", "depot")
	assert(default == ["docks", "market", "shelter"])
	assert(alternate == ["docks", "depot", "shelter"])
	assert(SandboxRoads.path_minutes(default) == 20)
	assert(SandboxRoads.path_minutes(alternate) == 30)
	assert(SandboxRoads.path_expense(default) == 0 and SandboxRoads.path_expense(alternate) == 2)
	assert(SandboxRoads.path_exposure(default) == 1 and SandboxRoads.path_exposure(alternate) == 0)
	assert(SandboxRoads.path("docks", "shelter", "clinic").is_empty())
	assert(SandboxRoads.path("docks", "invalid").is_empty())
	assert(not SandboxRoads.valid_path(["docks", "shelter"]))
	var a: SandboxWorld = SandboxWorld.new(8)
	var chosen: Dictionary = {}
	for offer in a.open_offers():
		if offer["origin"] == "docks" and offer["destination"] == "shelter" and offer["channel"] != "official":
			chosen = offer
			break
	assert(not chosen.is_empty(), "Seed 8 needs a real playable Docks-to-Shelter offer.")
	var id: String = str(chosen["id"])
	var fare: int = int(chosen["fare"])
	assert(not a.accept(id, "clinic"))
	assert(a.offer_by_id(id)["status"] == "open")
	assert(a.accept(id, "depot"))
	assert(a.route_nodes == alternate and a.remaining_minutes == 30)
	assert(not a.accept(id, "market"))
	assert(a.advance(10))
	assert(a.player_district == "depot" and a.route_segment == 1)
	assert(a.route_edge_elapsed == 0 and a.remaining_minutes == 20)
	assert(a.advance(10))
	assert(a.route_edge_elapsed == 10 and a.remaining_minutes == 10)
	assert(a.player_district == "depot")
	var mid: Dictionary = a.snapshot()
	var file: String = "user://s4-mid-edge.json"
	assert(SandboxSave.save_world(a, file))
	var resumed: SandboxWorld = SandboxSave.load_world(file)
	assert(resumed != null and JSON.stringify(resumed.snapshot()) == JSON.stringify(mid))
	assert(a.advance(10) and resumed.advance(10))
	assert(JSON.stringify(a.snapshot()) == JSON.stringify(resumed.snapshot()))
	assert(a.active_offer_id.is_empty() and a.route_nodes.is_empty() and a.remaining_minutes == 0)
	assert(a.player_district == "shelter" and a.credits == 12 + fare - 2)
	assert(a.risk == (1 if chosen["channel"] == "underground" else 0))
	var checkpoints: int = 0
	var completed: int = 0
	for event in a.events:
		if event["kind"] == "route_segment_completed" and event["subject"] == id:
			checkpoints += 1
		if event["kind"] == "fare_settled" and event["subject"] == id:
			completed += 1
	assert(checkpoints == 2 and completed == 1)
	assert(a.advance(20))
	assert(a.credits == 12 + fare - 2)
	var forged: Dictionary = mid.duplicate(true)
	forged["route_nodes"] = ["docks", "shelter"]
	assert(not SandboxWorld.new().restore_snapshot(forged))
	forged = mid.duplicate(true)
	forged["remaining_minutes"] = 20
	assert(not SandboxWorld.new().restore_snapshot(forged))
	var b: SandboxWorld = SandboxWorld.new(8)
	assert(b.accept(id))
	assert(b.route_nodes == default and b.remaining_minutes == 20)
	assert(b.advance(20))
	assert(b.player_district == "shelter" and b.risk >= 1)
	assert(b.credits == 12 + fare)
	assert(b.events != a.events)
	print("SANDBOX_ROUTES_PASS")
	quit(0)
