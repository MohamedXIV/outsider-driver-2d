extends SceneTree

func _initialize() -> void:
	var a: SandboxWorld = SandboxWorld.new(8)
	var b: SandboxWorld = SandboxWorld.new(8)
	var c: SandboxWorld = SandboxWorld.new(9)
	if not Check.ok(JSON.stringify(a.snapshot()) == JSON.stringify(b.snapshot()), "JSON.stringify(a.snapshot()) == JSON.stringify(b.snapshot())"): return
	if not Check.ok(JSON.stringify(a.snapshot()) != JSON.stringify(c.snapshot()), "JSON.stringify(a.snapshot()) != JSON.stringify(c.snapshot())"): return
	if not Check.ok(a.residents.size() == 9 and a.open_offers().size() > 1, "a.residents.size() == 9 and a.open_offers().size() > 1"): return
	if not Check.ok(not a.advance(0), "not a.advance(0)"): return
	if not Check.ok(not a.reposition("unknown"), "not a.reposition('unknown')"): return
	var chosen: Dictionary = {}
	for offer in a.open_offers():
		if offer["origin"] == a.player_district and offer["channel"] != "official":
			chosen = offer
			break
	if not Check.ok(not chosen.is_empty(), "Seed 8 must provide an accessible local demand."): return
	var id: String = str(chosen["id"])
	var npc_id: String = str(chosen["npc_id"])
	var prior_cash: int = int(a.resident(npc_id)["cash"])
	var price: int = int(chosen["fare"])
	if not Check.ok(a.accept(id), "a.accept(id)"): return
	if not Check.ok(not a.accept(id), "not a.accept(id)"): return
	if not Check.ok(not a.reposition("market"), "not a.reposition('market')"): return
	if not Check.ok(a.advance(SandboxRoads.travel_minutes(str(chosen["origin"]), str(chosen["destination"]))), "a.advance(SandboxRoads.travel_minutes(str(chosen['origin']), str(chosen['destination'])))"): return
	if not Check.ok(a.active_offer_id.is_empty(), "a.active_offer_id.is_empty()"): return
	if not Check.ok(a.offer_by_id(id)["status"] == "completed", "a.offer_by_id(id)['status'] == 'completed'"): return
	if not Check.ok(a.credits == 12 + price, "a.credits == 12 + price"): return
	if not Check.ok(a.resident(npc_id)["location"] == chosen["destination"], "a.resident(npc_id)['location'] == chosen['destination']"): return
	if not Check.ok(int(a.resident(npc_id)["cash"]) == prior_cash - price, "int(a.resident(npc_id)['cash']) == prior_cash - price"): return
	if not Check.ok(int(a.resident(npc_id)["trust"]) == 1, "int(a.resident(npc_id)['trust']) == 1"): return
	var settled: int = 0
	for evt in a.events:
		if evt["kind"] == "fare_settled" and evt["subject"] == id:
			settled += 1
	if not Check.ok(settled == 1, "settled == 1"): return
	var path: String = "user://sandbox-domain.json"
	if not Check.ok(SandboxSave.save_world(a, path), "SandboxSave.save_world(a, path)"): return
	var restored: SandboxWorld = SandboxSave.load_world(path)
	if not Check.ok(restored != null, "restored != null"): return
	if not Check.ok(restored.seed == a.seed and restored.minute == a.minute, "restored.seed == a.seed and restored.minute == a.minute"): return
	if not Check.ok(restored.player_district == a.player_district and restored.credits == a.credits, "restored.player_district == a.player_district and restored.credits == a.credits"): return
	if not Check.ok(restored.risk == a.risk and restored.residents.size() == a.residents.size(), "restored.risk == a.risk and restored.residents.size() == a.residents.size()"): return
	if not Check.ok(restored.offers.size() == a.offers.size() and restored.events.size() == a.events.size(), "restored.offers.size() == a.offers.size() and restored.events.size() == a.events.size()"): return
	if not Check.ok(restored.offer_by_id(id)["status"] == "completed", "restored.offer_by_id(id)['status'] == 'completed'"): return
	if not Check.ok(restored.resident(npc_id)["cash"] == a.resident(npc_id)["cash"], "restored.resident(npc_id)['cash'] == a.resident(npc_id)['cash']"): return
	if not Check.ok(restored.events.back()["id"] == a.events.back()["id"], "restored.events.back()['id'] == a.events.back()['id']"): return
	if not Check.ok(not restored.accept(id), "not restored.accept(id)"): return
	if not Check.ok(b.accept(id), "b.accept(id)"): return
	if not Check.ok(b.advance(SandboxRoads.travel_minutes(str(chosen["origin"]), str(chosen["destination"]))), "b.advance(SandboxRoads.travel_minutes(str(chosen['origin']), str(chosen['destination'])))"): return
	if not Check.ok(JSON.stringify(b.snapshot()) == JSON.stringify(a.snapshot()), "JSON.stringify(b.snapshot()) == JSON.stringify(a.snapshot())"): return
	if not Check.ok(restored.advance(110), "restored.advance(110)"): return
	var expirations: int = 0
	for evt in restored.events:
		if evt["kind"] == "offer_expired":
			expirations += 1
	if not Check.ok(expirations > 0, "expirations > 0"): return
	var invalid: Dictionary = a.snapshot()
	invalid["player_district"] = "not-a-district"
	if not Check.ok(not SandboxWorld.new().restore_snapshot(invalid), "not SandboxWorld.new().restore_snapshot(invalid)"): return
	Check.finish(self, "SANDBOX_DOMAIN")
