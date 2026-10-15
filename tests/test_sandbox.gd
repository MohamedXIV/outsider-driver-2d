extends SceneTree

func _initialize() -> void:
	var a: SandboxWorld = SandboxWorld.new(8)
	var b: SandboxWorld = SandboxWorld.new(8)
	var c: SandboxWorld = SandboxWorld.new(9)
	assert(JSON.stringify(a.snapshot()) == JSON.stringify(b.snapshot()))
	assert(JSON.stringify(a.snapshot()) != JSON.stringify(c.snapshot()))
	assert(a.residents.size() == 9 and a.open_offers().size() > 1)
	assert(not a.advance(7))
	assert(not a.reposition("unknown"))
	var chosen: Dictionary = {}
	for offer in a.open_offers():
		if offer["origin"] == "docks" and offer["channel"] != "official":
			chosen = offer
			break
	assert(not chosen.is_empty(), "Seed 8 must provide an accessible local demand.")
	var id: String = str(chosen["id"])
	var npc_id: String = str(chosen["npc_id"])
	var prior_cash: int = int(a.resident(npc_id)["cash"])
	var price: int = int(chosen["fare"])
	assert(a.accept(id))
	assert(not a.accept(id))
	assert(not a.reposition("market"))
	assert(a.advance(SandboxRoads.travel_minutes(str(chosen["origin"]), str(chosen["destination"]))))
	assert(a.active_offer_id.is_empty())
	assert(a.offer_by_id(id)["status"] == "completed")
	assert(a.credits == 12 + price)
	assert(a.resident(npc_id)["location"] == chosen["destination"])
	assert(int(a.resident(npc_id)["cash"]) == prior_cash - price)
	assert(int(a.resident(npc_id)["trust"]) == 1)
	var settled: int = 0
	for evt in a.events:
		if evt["kind"] == "fare_settled" and evt["subject"] == id:
			settled += 1
	assert(settled == 1)
	var path: String = "user://sandbox-domain.json"
	assert(SandboxSave.save_world(a, path))
	var restored: SandboxWorld = SandboxSave.load_world(path)
	assert(restored != null)
	assert(JSON.stringify(restored.snapshot()) == JSON.stringify(a.snapshot()))
	assert(not restored.accept(id))
	assert(b.accept(id))
	assert(b.advance(SandboxRoads.travel_minutes(str(chosen["origin"]), str(chosen["destination"]))))
	assert(JSON.stringify(b.snapshot()) == JSON.stringify(a.snapshot()))
	assert(restored.advance(110))
	var expirations: int = 0
	for evt in restored.events:
		if evt["kind"] == "offer_expired":
			expirations += 1
	assert(expirations > 0)
	var invalid: Dictionary = a.snapshot()
	invalid["player_district"] = "not-a-district"
	assert(not SandboxWorld.new().restore_snapshot(invalid))
	print("SANDBOX_DOMAIN_PASS")
	quit(0)
